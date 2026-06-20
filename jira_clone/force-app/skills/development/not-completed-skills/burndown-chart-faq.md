# Burndown Chart FAQ (shared question iteration)

The ordered questions for building a **burndown chart** (a Chart.js `line` chart)
in an LWC. This file is **questions only** — the calling skill decides whether to
enter, supplies the mandatory guides, and does all the analysis (state wiring,
Apex resolution, code emission, CSS) after these answers are collected.

## Precondition

> **Chart type: `burndown chart`.**

Only run this FAQ once the chart type has been confirmed as a burndown chart. If
the user wants a different chart type, this FAQ does not apply — stop and route
to the matching chart FAQ.

## Step prefix (avoid number conflicts)

This FAQ does **not** own a fixed step number. It is invoked from inside a
calling skill that already has its own `Step 1 / 2 / 3 …`. The caller passes the
step number it reached when it calls this FAQ — call it `<prefix>` — and every
question below is read as `<prefix>.1 … <prefix>.7`.

Example: if a skill calls this FAQ at its **Step 3**, then `<prefix>` is `3` and
the questions run as `Step 3.1 … Step 3.7`.

Ask one question per message, in order. Print the tracker line at the top of
every question so the loop state is always visible:

```
[Chart: burndown | Step <prefix>.<n>]
```

---

## `.1` — Context / dimensions (canvas info)

Ask for the **canvas context dimensions**: width and height of the chart's
canvas (and any wrapper sizing). These feed the `<canvas>` markup and the
`responsive` / `maintainAspectRatio` decision in `.6`. Record exactly what the
user gives; do not assume a default size.

## `.2` — X-axis labels

Ask **what to display on the X axis** — i.e. the `labels` array. For a burndown
this is usually the sprint timeline (e.g. `Day 0 … Day N`, dates, or sprint
days). Capture both the source of the labels and their format.

## `.3` — Number of datasets

Ask **how many datasets** the chart has. A classic burndown has two (Ideal vs
Actual), but record exactly what the user states. This number `N` drives the
loop in `.4`.

## `.4` — Per-dataset loop

**Loop `N` times** (once per dataset from `.3`). For each dataset `i`
(`1 … N`), keep the tracker line `[Chart: burndown | Step <prefix>.4 — dataset
i/N]` and ask, in order:

- **`.4.i.a` — label?** The dataset's display name (e.g. `Ideal`, `Actual`).
- **`.4.i.b` — which data to load?** The source for this dataset's `data`
  array — the state object + field, or the computed series (e.g. ideal
  remaining vs actual remaining story points).
- **`.4.i.c` — border color?** The line color (`borderColor`).
- **`.4.i.d` — border dash?** The `borderDash` pattern (e.g. `[6, 6]` for a
  dashed ideal line, or none for a solid line).
- **`.4.i.e` — background color?** The `backgroundColor`. **Note for the
  user:** background color matters when the area under the line is filled —
  it changes (e.g. to a translucent fill like `rgba(...)`) only when `fill` is
  enabled for that dataset; for an unfilled line, `transparent` is normal.
- **`.4.i.f` — pointRadius?** The size of the data-point markers (e.g. `0` to
  hide points, `3` to show them).
- **`.4.i.g` — tension?** The line curve (`0` for straight segments, `> 0` for
  a smoothed curve).

Do not advance to `.5` until every dataset `1 … N` has all seven values
recorded.

## `.5` — Options: fill or let AI customize?

Ask:

> *"Do you want to fill in the chart options yourself, or let the AI choose
> them?"*

- **Custom by AI** → record that and **skip `.6`**; the calling skill chooses
  sensible burndown defaults.
- **Fill** → continue to `.6` and gather each option explicitly.

## `.6` — Options (only when `.5` = "fill")

Gather each option in order:

- **`.6.1` — responsive?** `true` / `false`.
- **`.6.2` — maintainAspectRatio?** `true` / `false`.
- **`.6.3` — plugins:**
  - **title display?** `true` / `false`.
  - **title text?** the chart title string.
  - **legend position?** e.g. `top` / `bottom` / `left` / `right`.
- **`.6.4` — scales:**
  - **x — title:**
    - **display?** `true` / `false`.
    - **text?** the X-axis title string.
  - **y — title:**
    - **display?** `true` / `false`.
    - **text?** the Y-axis title string.
    - **beginAtZero?** `true` / `false`.

---

## Return to the calling skill

When `.1` through `.6` are all answered (with `.6` skipped if `.5` = "custom by
AI"), **hand these FAQ answers back to the calling skill**. This FAQ asks
questions only — it does not decide how the data is loaded (`@wire` vs
imperative), how the state is wired, or which Apex method backs each dataset.
The calling skill resumes at its own next step and does all of that from these
answers.

---

## Reading a combined prompt

A user may answer several of these questions up front in one prompt. When that
happens:

1. Walk the prompt top-to-bottom and assign each block to its matching question
   (and, for `.4`, to the right dataset `i`).
2. For every question already **present**, record the answer and move on — do
   not re-ask it.
3. For every question that is **missing**, ask that one question (and only that
   one) using the tracker line, then continue.
4. Do not invent answers for missing questions, and do not skip them — control
   only returns to the caller once all questions are resolved.

### Worked example mapping (two-dataset burndown)

```
─── [.1 Context / dimensions] ──────────────────────────────────────────────
canvas: full-width wrapper, height 320px

─── [.2 X-axis labels] ─────────────────────────────────────────────────────
labels: Day 0 … Day 10 (one per sprint working day)

─── [.3 Number of datasets] ───────────────────────────────────────────────
2

─── [.4 dataset 1/2] ──────────────────────────────────────────────────────
label: Ideal
data:  ideal remaining story points (straight scope → 0)
borderColor: #9aa0a6
borderDash:  [6, 6]
backgroundColor: transparent
pointRadius: 0
tension: 0

─── [.4 dataset 2/2] ──────────────────────────────────────────────────────
label: Actual
data:  actual remaining story points per day
borderColor: #1b5e20
borderDash:  none
backgroundColor: rgba(27, 94, 32, 0.12)   (only because fill is on)
pointRadius: 3
tension: 0.25

─── [.5 fill or AI] ────────────────────────────────────────────────────────
fill

─── [.6 options] ──────────────────────────────────────────────────────────
responsive: true
maintainAspectRatio: false
plugins.title.display: true
plugins.title.text: Sprint Burndown
plugins.legend.position: bottom
scales.x.title.display: true
scales.x.title.text: Sprint day
scales.y.title.display: true
scales.y.title.text: Story points remaining
scales.y.beginAtZero: true
```
