---
name: apex-method-resolution
activation:
  mode: required
  applies_when: >-
    a new functionality or event handler must be backed by an Apex method
    (parent skills only — children never call Apex, so this self-skips)
description: >
  Shared interview sub-step for resolving which Apex method backs a new LWC
  functionality or event handler. Reusable across any task-skill whose
  interview reaches "which controller method handles this?" — captures the
  method via one of three branches (existing-known, existing-find,
  create-new) and recursively resolves any dependent class/method that does
  not yet exist before code is emitted. Step-number-agnostic: the calling
  skill substitutes its own step prefix when printing the tracker line.
---

# Apex Method Resolution (shared interview sub-step)

Use this protocol at the point in any parent-interview where the Apex
backing a new functionality or event handler must be identified. The
calling skill keeps its own step number (e.g. `Step 2.7`, `Step 10`) and
substitutes it into the tracker line — the protocol itself is the same.

## Question

> *"Which Apex method should handle this? (A) class + method + line, (B)
> point to a folder/class and AI finds it, (C) method doesn't exist —
> create it."*

## Branches

- **Branch A — user supplied the line.** Record `<ApexClass>.<method>` and
  skip verification entirely. **→ Final Output.**
- **Branch B — user points to a folder/class.** Search the named location,
  identify the method, confirm with the user. **→ Final Output.**
- **Branch C — method doesn't exist.** Run the **Creation Sub-Loop** below.

## Creation Sub-Loop (Branch C)

Ask sub-question **.1** (*"What should the controller do?"*) — then parse
the answer for any other class/method it references. For each referenced
symbol that doesn't exist, recurse:

> *"You mentioned `<Class>.<method>`, which doesn't exist. What should it
> do?"*

Continue until no description references an unresolved class/method. Track
depth in the tracker line, e.g.:

```
[... | Step <N>.1 | depth 2: FooSvc.bar]
```

Then ask sub-question **.2** (*"Where should the controller live?"*) for
every method created during the recursion.

Then ask sub-question **.3** (*"Should this method be cacheable
(`@AuraEnabled(cacheable=true)`) or not?"*) for every method created during
the recursion. A method that only reads data and never performs DML can be
cacheable; any method that performs DML or must always return fresh data must
not be cacheable. Record the choice so the emitted controller method carries
the correct `@AuraEnabled` / `@AuraEnabled(cacheable=true)` annotation.
