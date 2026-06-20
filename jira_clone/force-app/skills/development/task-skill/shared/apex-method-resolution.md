---
name: apex-method-resolution
description: >
  Shared question iteration for resolving which Apex method backs a new LWC
  functionality or event handler. Reusable from any FAQ that reaches "which
  controller method handles this?" — captures the method via one of three
  branches (existing-known, existing-find, create-new) and recursively resolves
  any dependent class/method that does not yet exist. Questions only: it gathers
  the method, where a new one lives, and whether it is cacheable — it does not
  decide `@wire` vs imperative (that is the pather's job). Step-number-agnostic:
  the calling FAQ substitutes its own step prefix when printing the tracker line.
---

# Apex Method Resolution (shared question iteration)

Use this protocol at the point in any FAQ where the Apex method backing a new
functionality or event handler must be identified. The calling FAQ keeps its own
step number (e.g. `.8`, `.10`) and substitutes it into the tracker line — the
protocol itself is the same.

## Question

> *"Which Apex method should handle this? (A) class + method + line, (B)
> point to a folder/class and AI finds it, (C) method doesn't exist —
> create it."*

## Branches

- **Branch A — user supplied the line.** Record `<ApexClass>.<method>` and
  skip verification entirely. **→ Final answer.**
- **Branch B — user points to a folder/class.** Search the named location,
  identify the method, confirm with the user. **→ Final answer.**
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
[... | <prefix>.1 | depth 2: FooSvc.bar]
```

Then ask sub-question **.2** (*"Where should the controller live?"*) for
every method created during the recursion.

Then ask sub-question **.3** (*"Should this method be cacheable
(`@AuraEnabled(cacheable=true)`) or not?"*) for every method created during
the recursion. A method that only reads data and never performs DML can be
cacheable; any method that performs DML or must always return fresh data must
not be cacheable. Record the choice so the emitted controller method carries
the correct `@AuraEnabled` / `@AuraEnabled(cacheable=true)` annotation.

Recording cacheability here is gathering, not deciding — the calling pather
skill is what later turns "cacheable" into an actual `@wire`-vs-imperative
choice.
