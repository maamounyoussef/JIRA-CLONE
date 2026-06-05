# Pather — Event Handler FAQ (shared per-event question iteration)

The questions for wiring a parent LWC to handle a `CustomEvent` dispatched by a
child. This file is **questions only** — it asks every question below, records
the answers, and hands them back. It makes no implementation decisions. The
calling pather skill names the child and lists its events (entry point), and
from the returned answers it decides the call style (imperative vs `@wire`), the
wire shape, and does all the analysis (handler placement, state-management
checklist, code emission, CSS). This file never decides the call style and never
references a `guide/` file.

## Step prefix (avoid number conflicts)

This FAQ does **not** own a fixed step number. It is invoked from inside a
calling pather skill that already has its own `Step 1 / 2 / 3 …`, so a literal
step label here would collide with the caller's. The caller passes the step
number it reached — call it `<prefix>` — and every question below is read as
`<prefix>.1 … <prefix>.5`.

This is a **per-event loop**: the caller hands one dispatched event at a time
and asks the questions it needs for that event, then returns for the next event.

Ask one question per message. Print the tracker line at the top of every
question:

```
[Child: <name> | Event: <eventName> | Step <prefix>.<n>]
```

"I don't know" is a valid answer — analyse the available info (dispatched event
name, RULES, state shape), make the best decision, and proceed. Do not stall.

---

**`.1` — State identification.** Ask which state the parent is working on
(UPDATE / LOAD / SEARCH), and whether it is stored in an **array** or as a
**single (separate)** value.

**`.2` — Apex method resolution.** Run the shared question sub-step defined in
[apex-method-resolution.md](./apex-method-resolution.md). Keep the `<prefix>.2`
step prefix (with sub-questions `<prefix>.2.1` / `<prefix>.2.2` /
`<prefix>.2.3`) in the tracker line, and follow its branches and Creation
Sub-Loop verbatim. This records the method and — when one is created — **whether
it is cacheable**.

**`.3` — Concurrent writes.** Ask: *"Can other users or other browser sessions
modify this data while this component is open?"* (Yes / No.)

**`.4` — Expand action.** Ask: *"Was this dispatch caused by an expand action?"*
(Yes / No / "do your own check from the event name".)

**`.5` — Load timing.** Ask: *"Should the data load on child **creation** or on
**expand**?"* (Created / Expanded.) Ask this only when `.4` was an expand
action; otherwise there is nothing to time, so record "n/a" and finish.

---

## Return to the calling pather skill

When the caller has the answers it needs for the current event, **hand them
back to the calling pather skill**. This FAQ does not decide the call style and
does not emit code. The pather skill resumes at its own next step, makes the
imperative-vs-`@wire` decision and the wire-shape decision, runs its analysis
(handler placement, state-management checklist, code emission, optional CSS),
then comes back here for the next event.
