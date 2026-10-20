# Design red flags

Screen the chosen design against this list before writing the spec. A flag is a reason to revise the shape, not a style note. Assume the next contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Prefer the design where a change that looks right from one file is right for the whole repo.

Adapted from pstack by Lauren Tan (MIT).

## Shallow module

A large interface that hides little. Judge depth by the capability and policy hidden behind the public surface relative to the size of that surface.

- Callers coordinate several methods to finish one operation.
- Public options expose internal stages or implementation choices.
- Learning the interface does not save the caller from learning the implementation.

A deep call chain is not a deep module: it scatters understanding across layers. Concentrate capability behind one small interface.

## Information leakage

Several modules depend on the same internal decision (a representation, policy, or protocol detail), so changing it takes coordinated edits. Re-exporting wire or transport types is leakage. Parse external data into domain types behind the interface and keep storage schemas and framework objects private.

## Temporal decomposition

Modules split by execution order (load, validate, transform, save) instead of by the knowledge they own. The stages repeat one representation and its invariants across every boundary. Group code around the decisions it protects, even when the methods run at different times.

## Pass-through method

A method forwards the same arguments to another method of the same shape and adds nothing. Remove it, or move responsibility to the module that can finish the operation. Keep a forwarding boundary only when it adds policy, adaptation, or a distinct abstraction.

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
