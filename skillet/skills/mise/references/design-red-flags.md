# Design red flags

Screen the chosen design against this list before writing the spec. A flag is a reason to revise the shape, not a style note. Assume the next contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Prefer the design where a change that looks right from one file is right for the whole repo.

Adapted from pstack by Lauren Tan (MIT).

## Shallow module

A module whose surface is about as complicated as its inside. Weigh how much real work and policy sits behind the interface against how many things a caller has to know to use it.

- A caller must call several methods in the right order to get one thing done.
- Configuration options mirror the module's internal stages.
- Reading the interface teaches the caller nothing it would not learn by reading the code.

Many thin layers calling each other is the opposite of depth, not a form of it: the logic ends up spread across the layers. Aim for one small entry point with a lot of behavior behind it.

## Information leakage

One internal choice (a data format, a rule, a wire detail) is known to several modules, so changing it means editing all of them. Handing callers the raw wire or storage types is the common form. Convert incoming data into the system's own types at the edge, and keep schemas and framework objects behind the module that owns them.

## Temporal decomposition

Code divided along the timeline (load, then validate, then transform, then save) instead of along what each part knows. Every stage ends up re-handling the same data shape and re-checking the same rules. Divide by ownership of a concept, even if that puts steps that run at different moments in one module.

## Pass-through method

A function whose whole body is a call to another function with the same arguments. It costs a hop for every reader and hides nothing. Delete it, or hand its job to whichever module can actually finish the work. A forwarding layer earns its place only if it translates, enforces a rule, or marks a real boundary between concepts.

## Split ownership of state

More than one module writes the same state or keeps its own copy. An agent editing one writer cannot see the others, so their rules drift apart. Give each piece of state one owner; everyone else reads it or asks the owner to change it.

## Two ways to do one task

The design supports two paths to the same result. An agent copies whichever it finds first, so both keep gaining callers. Keep one, move callers over, and delete the other in the same change.

## Importable internals

Callers can import a module's internals, so the shortest path that compiles becomes part of the interface. Make internals unreachable from outside so an outside import fails the build.

## Hand-synced list

Two places list the same items and adding one means editing both. An agent that sees one list updates only that one. Keep one list and derive the rest; if a list cannot be derived, make the build fail when they disagree.

## Growing conditional

An if/else or switch chain that gains a branch per new case, or a second boolean that must always track the first. The next case adds another branch, and the invalid combinations stay reachable. Replace it with a single tagged value or a table keyed by the case, so a new case is data and an impossible state cannot be built.

## New requirement bolted on

The new requirement is added beside the existing design (a flag, a wrapper, a parallel path) instead of integrated into it. Ask what the design would look like if the requirement had been there from the start, and build that. If integrating it means changing the existing shape, say so in the spec.
