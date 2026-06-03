# Mandatory LWC guard for lwc child (apply without being asked)

Every LWC — children included — routes failures through a toast, so
**`lwc-error-handling`** (`force-app/skills/development/guard/lwc-error-handling-skill.md`)
is mandatory on every functionality that emits child JS/HTML. Any synchronous
validation failure (or `success === false` / error branch the child handles
before emitting upward) surfaces through `ShowToastEvent` (`variant: 'error'`),
never a tracked inline `errorMessage` banner.

`lwc-apex-loading` does **not** apply here: children never call Apex (the
contract this skill enforces), so there is no round-trip to spin on. The
parent owns loading state.

The guard's own SKIP conditions still hold; when you skip it, state the
reason in the iteration message. Confirm its completion checklist passes
before reporting the functionality done.
