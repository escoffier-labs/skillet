# Updates, Launchers, and Local Automation

Use this reference when T3 shows an update banner, a wrapper launches the wrong build, or desktop and headless components drift apart.

## Identify the install source

Before updating, record:

```bash
command -v t3
t3 --version
readlink -f "$(command -v t3)"
```

For the desktop application, inspect the launcher or desktop entry to determine whether it runs an AppImage, package-manager installation, source checkout, or another channel.

Do not run an npm, package-manager, or AppImage update command until the current source is known. Two installations can coexist and make an update appear ineffective.

## Separate components

Check these independently:

- Desktop application build.
- T3 CLI used in the shell.
- Headless server executable used by a service.
- Wrapper or symlink that selects a version.

An update banner may refer to one component while another is already current.

## Durable local layout

Keep local integration outside release artifacts:

- Versioned application files: `~/.local/opt/t3-code/` or another user-owned application directory.
- Stable launcher or symlink: `~/.local/bin/`.
- Local assets: `~/.local/share/t3-code/`.
- User services and timers: `~/.config/systemd/user/`.

A launcher should select one explicit installation and fail clearly when it is missing. Avoid scanning arbitrary downloads on every launch.

## Update sequence

1. Record the current version and executable target.
2. Download or install through the same trusted channel.
3. Verify the new artifact before changing the stable launcher.
4. Switch the wrapper or symlink atomically.
5. Relaunch the desktop application or restart the user service.
6. Confirm the reported version and the executable path after restart.
7. Keep or remove the previous artifact according to the user's rollback policy.

Do not modify a generated bundle to make a durable fix. Put compatibility flags, environment variables, and path selection in the local wrapper.

## User timer pattern

Automated updates are optional. If the user asks for them, use a user service and timer that call a reviewed local updater. Do not embed credentials in the unit. Use randomized delay and retain logs for diagnosis.

After changing units:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-update.timer
systemctl --user list-timers --all | grep t3
journalctl --user -u t3-update.service -n 100 --no-pager
```

## Verification

- `command -v t3` and `readlink -f` point to the intended installation.
- `t3 --version` reports the expected build.
- The desktop launcher starts the intended desktop artifact.
- The headless service uses the intended executable.
- Project state remains under the intended base directory.
- A failed update leaves the previous working version available when rollback was requested.
