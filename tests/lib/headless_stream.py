"""Shared helper for the opt-in headless runners (run-trigger-tests.sh and
run-skill-evals.sh --live).

Starts one flat headless agent pass, feeds the prompt on stdin (a variadic
--disallowedTools flag would otherwise swallow a positional prompt), parses the
stream-json output line by line, appends every raw line to a log file, and can
stop the process early once the caller has seen enough.

Every pass runs with CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 so CLAUDE.md files in the
scratch directory's parents (the temp dir may sit under a home directory) cannot
leak into the measurement.

Standard library only. This module never builds the command line: the shell
callers own that, so --dry-run can print exactly what would run.
"""
import json
import os
import signal
import subprocess
import threading
import time


def run_stream(cmd, prompt, cwd, timeout, log_path, on_event=None):
    """Run cmd, return a dict: events, returncode, timed_out, stopped_early,
    stderr, duration_ms. on_event(event) may return True to stop the run."""
    started = time.monotonic()
    events = []
    stopped_early = False
    timed_out = False

    env = dict(os.environ)
    env["CLAUDE_CODE_DISABLE_CLAUDE_MDS"] = "1"

    try:
        proc = subprocess.Popen(
            cmd,
            cwd=cwd,
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
    except OSError as error:
        return {
            "events": [],
            "returncode": 127,
            "timed_out": False,
            "stopped_early": False,
            "stderr": f"cannot start {cmd[0]!r}: {error}",
            "duration_ms": 0,
        }

    stderr_chunks = []
    stderr_thread = threading.Thread(
        target=lambda: stderr_chunks.append(proc.stderr.read()), daemon=True
    )
    stderr_thread.start()

    def kill_group(sig):
        try:
            os.killpg(proc.pid, sig)
        except (ProcessLookupError, PermissionError):
            pass

    timer_fired = threading.Event()

    def on_timeout():
        timer_fired.set()
        kill_group(signal.SIGTERM)

    timer = threading.Timer(timeout, on_timeout)
    timer.start()

    try:
        try:
            proc.stdin.write(prompt)
            proc.stdin.close()
        except BrokenPipeError:
            pass

        with open(log_path, "a", encoding="utf-8") as log:
            for line in proc.stdout:
                log.write(line)
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue
                events.append(event)
                if on_event is not None and on_event(event):
                    stopped_early = True
                    kill_group(signal.SIGTERM)
                    break
    finally:
        timer.cancel()
        timed_out = timer_fired.is_set()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            kill_group(signal.SIGKILL)
            proc.wait()
        stderr_thread.join(timeout=2)

    return {
        "events": events,
        "returncode": proc.returncode,
        "timed_out": timed_out,
        "stopped_early": stopped_early,
        "stderr": "".join(stderr_chunks),
        "duration_ms": int((time.monotonic() - started) * 1000),
    }


def tool_uses(event):
    """Yield (name, input) for every tool_use block in an assistant event."""
    if event.get("type") != "assistant":
        return
    content = (event.get("message") or {}).get("content") or []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            yield block.get("name", ""), block.get("input") or {}
