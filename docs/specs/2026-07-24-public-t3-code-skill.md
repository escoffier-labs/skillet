# Public T3 Code Skill

## Goal

Ship one portable `t3-code` skill folder that another user can copy or install without inheriting private fleet details.

## Design

The skill keeps one discoverable entry point, `SKILL.md`, and three routed references:

- `project-state.md` for project registration, titles, workspace identity, SQLite inspection, and icons.
- `remote-tailscale.md` for direct Tailnet binding, Tailscale Serve, and a generic user-service pattern.
- `updates-and-launchers.md` for install-source detection, desktop/server version drift, wrappers, and optional user timers.

The package also carries Skillet's required `skill.json` and `CHANGELOG.md`. It has no dependency on another skill, private repository, organization, machine, timer, or absolute user path.

## Sanitization boundary

Remove all private hostnames, organization names, repository names, local wrapper names, exact timer names, device workflows, and fleet-specific normalization behavior. Public examples use generic project and host labels. Network examples use runtime-discovered Tailnet addresses or placeholders, never a real address.

## Safety boundary

- Prefer supported T3 CLI commands over database writes.
- Inspect installed flags because nightly behavior may change.
- Keep remote access private by default.
- Require explicit intent before forced project removal, replacement installs, or public exposure.
- Keep machine-specific integration in user-owned paths outside release artifacts.

## Acceptance

- The complete skill lives under `skillet/skills/t3-code/`.
- A user can take that directory alone and retain every referenced instruction.
- Skillet's catalog, routing skill, marketplace description, count badge, and changelog include `t3-code`.
- The skill and full catalog pass `tests/lint-skills.sh`.
- A tracked-tree and history scan finds no private fleet details introduced by this change.
