# Contributing to skillet

skillet is a roster of agent skills for AI coding agents: plain `SKILL.md` files that audit, improve, and ship repos. It grew out of [Solomon's Cookbook](https://github.com/escoffier-labs/solos-cookbook), and patches are welcome. Before you start, please skim this file so we both spend our time on the right things.

## Support scope

This is a maintained but small project. What you can expect:

- **Bug reports** for a skill that misfires, triggers when it should not, or no longer matches its description: please file an issue with the [bug template](.github/ISSUE_TEMPLATE/bug.yml).
- **Install and discovery problems** (`npx skills add`, the Claude Code marketplace, raw `SKILL.md` copy): file the [bug template](.github/ISSUE_TEMPLATE/bug.yml) with your harness and install method.
- **Questions and "how do I use this"**: please use the cookbook link in the issue template's contact links rather than opening an issue. The cookbook is where the longer-form guidance lives.

## What kinds of changes land easily

- **Bug fixes** for a skill's trigger description, instructions, or a broken example.
- **Sharper triggers**: a skill that fails to fire (or fires on the wrong work) is a real bug in the trigger description, and a fix is welcome.
- **Tightening an existing skill's procedure** with a gotcha you hit in real use.
- **Docs fixes**: the README skill table, the audit report contract, install instructions.

## What needs a conversation first

- **A new skill.** Open an issue first describing the workflow it encodes and the friction it removes. Skills are the public surface, and a skill that overlaps an existing one (or fights a stated boundary) is painful to remove later.
- **Renaming or removing a skill**, or changing the shared audit report contract (`docs/audit-report-format.md`). Other skills and downstream tooling depend on those.
- **Changing a skill's read-only / review-gated boundary** (for example making an audit skill apply changes). Those boundaries are deliberate.

## What does not land

- Personal details, hostnames, IPs, account IDs, or live auth profiles in skill instructions, examples, or tests. The whole point of several of these skills is to keep that stuff out of public repos. The `content-guard` pre-push hook will flag it.
- A skill that pushes, publishes, or releases without an explicit operator request, or that applies changes the audit skills are supposed to only report.
- AI-co-authorship trailers on commits (`Co-Authored-By: <model>`). Conventional commits only.

## Anatomy of a skill

Each skill is a directory under `skillet/skills/<name>/` containing a `SKILL.md` with frontmatter (a `name` and a trigger `description`) and the procedure body. Some skills ship helper scripts alongside the `SKILL.md` (for example `grill` ships `scripts/grill-scan.sh`). The trigger `description` is load-bearing: it is what makes the skill auto-fire, so keep it specific about when to use the skill and when not to.

## Testing a skill before you call it done

A skill is done when a fresh agent with no prior context can follow it and reach the intended outcome. The **skillify** skill documents the fresh-agent test in detail; the short version:

1. Install or point a clean agent session at the skill.
2. Give it a realistic task that should trigger the skill.
3. Confirm the skill fires on its own from the description, and that following it produces the right result without you steering.

Note any baseline behavior you tested against in the changelog entry, the way existing entries do (for example "baseline-tested against a fresh agent before it shipped").

## Filing issues

Please use the templates under `.github/ISSUE_TEMPLATE/`. Before posting any agent output, remove tokens, private hostnames, private repo names, and unredacted absolute paths.

## License

By contributing you agree that your contribution is licensed under the MIT License, the same as the rest of the repo.
