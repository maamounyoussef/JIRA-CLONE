# Project Instructions — Jira Clone

These instructions say **which** discipline applies and **when**. The **how** lives
in the referenced skill / guide `.md` files — read those for the rules, checklists,
and examples. Do not duplicate implementation detail here.

## `run` trigger → orchestrator (MANDATORY)

When the developer types **`run`**, invoke the `agile-development-orchastrator`
skill and follow its `.md` iteration exactly. Do not run the app, deploy, or take
any other action — `run` always means start the orchestrator.

## Skill iteration discipline (MANDATORY — applies to every development skill)

When running any development skill or task‑skill (the `agile-development-orchastrator`
and anything under `force-app/skills/development/**`), follow the iteration **exactly
as written in the skill's `.md` file** and **do not ask any question that is not
defined in that `.md`**.

- Ask **only** the questions the skill's `.md` lists, in its order, one at a time.
- Never invent, add, merge, or borrow a question from another skill. If a question
  is not in the active skill's `.md`, it does not get asked.
- If information seems missing, re‑read the active skill's `.md` and continue its
  defined iteration. Do not fill gaps with extra questions.

## Mandatory‑guides step: read each guide's `activation:` contract (MANDATORY)

Every task‑skill under `force-app/skills/development/task-skill/**` opens with a
**"Mandatory guides"** step. That step lists guide **names only** — it does NOT
restate when each guide fires. The trigger lives with the guide: every file under
`task-skill/guide/**` declares an `activation:` block in its frontmatter
(`mode`, `applies_when`, and — for optional guides — `question`). For each guide a
task‑skill lists, open it, read its `activation:` block, and apply it by its
declared `mode`:

- **required** → no question. Look at the scope of the change: read and apply the
  guide when its `applies_when` matches that scope; otherwise skip it and state the
  skip reason in the iteration message.
- **optional** → ask the guide's declared `question` first. Apply it only when the
  user answers yes; never apply it silently.
- **cross-cutting** → the guide is project‑wide and fires from this CLAUDE.md (not
  from any task‑skill's list). It is never gated by a Mandatory‑guides question.

## Shared FAQ responsibility (MANDATORY)

A **shared FAQ** (any file under `force-app/skills/development/task-skill/shared/**`
that drives an interview — e.g. `pather-add-functionality-faq.md`,
`pather-event-handler-faq.md`, `apex-method-resolution.md`,
`ask-user-for-lwc-validation.md`) is responsible for **asking questions and
recording the user's answers — nothing else**:

- It only gathers input. It never decides **what to do** with an answer (e.g.
  `@wire` vs imperative call style, layering, which code to emit). Deciding from
  the answers is the **calling task‑skill's (pather's) job**.
- A shared FAQ never references a `guide/` file — guides encode the
  answer‑driven decisions, so they are referenced only by the skills directly
  under `task-skill/`, never from a `shared/` FAQ. A shared FAQ may reference
  other `shared/**` question sub‑steps.
- A shared FAQ is step‑number‑agnostic: the caller passes the step number it
  reached as a `<prefix>`, and the FAQ's questions read as `<prefix>.1 …`. The
  FAQ does not know whether the parent LWC already exists — that is the caller's
  entry‑point concern.

## Apex bulkification (MANDATORY — applies automatically)

Whenever you write or edit Apex that retrieves or updates **more than one record**,
run the bulkification skill chain **in order, without being asked**, following each
skill's `.md`:

1. **Detect** — `apex-governor-limit-guard`
   (`force-app/skills/development/guard/apex-governor-limit-guard.md`).
2. **Rewrite** — `apex-bulk-soql`
   (`force-app/skills/development/performance/apex-bulk-soql.md`).
3. **Measure** — `apex-method-monitor`
   (`force-app/skills/development/performance/apex-method-monitor.md`).

Skip the chain only for genuinely single‑record operations, or async Batch Apex
that chunks by design.

## SOQL: exclude soft‑deleted rows (MANDATORY — applies automatically)

Whenever you write or edit Apex that queries a custom object carrying a
`RecordStatus__c` field, follow the **`soql-exclude-deleted`** skill
(`force-app/skills/development/task-skill/guide/soql-exclude-deleted-guide.md`) without
being asked. The guide defines the required `WHERE`‑clause rule and the only
allowed exception.

## Governor‑limit guard (MANDATORY)

Apply [guard/apex-governor-limit-guard](force-app/skills/development/guard/apex-governor-limit-guard.md)
whenever a **bulk query** (a `SELECT` returning more than one record) or a
**bulk command** (DML — `insert`/`update`/`delete`/`upsert` — over more than one
record) is written or edited, to catch governor‑limit (CPU/SOQL/DML/heap) and
N+1 risks before they ship. This stays in effect long‑term.

## Bulk‑SOQL rewrite (MANDATORY)

Apply [performance/apex-bulk-soql](force-app/skills/development/performance/apex-bulk-soql.md)
whenever a **bulk query** or **bulk command** is written or edited — and
whenever `apex-governor-limit-guard` flags an N+1 pattern — to rewrite it into
the bulk‑safe shape (one query per object into a `Map<Id, SObject>`, in‑memory
validation, one DML per object after the loop) so the SOQL/DML count stays flat
as the input grows. This stays in effect long‑term.

## Method profiling (MANDATORY)

Apply [performance/apex-method-monitor](force-app/skills/development/performance/apex-method-monitor.md)
after creating or editing any `@AuraEnabled` controller method whose body does
SOQL, SOSL, or DML, to profile it against a real governor‑limit test and record
the result. It asks before running, via the interactive `AskUserQuestion` tool,
so it never profiles without consent. This stays in effect long‑term.

## Reports: check API version, read the matching Apex Reference (MANDATORY)

Whenever you implement or edit a **report** (any work against the `Reports`
namespace classes — e.g. `ReportManager`, `ReportResults`, `ReportInstance`,
`ReportFactWithDetails`, etc.):

1. Read the org's API version from `sourceApiVersion` in `sfdx-project.json`
   .
2. For each `Reports` class you are working on, fetch the Apex Reference page for
   that class at the URL matching that API version, then implement against what it
   documents (available methods, signatures, and behavior for that version):

   ```
   https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_reports_<classname>.htm
   ```

   where `<classname>` is the class name **lowercased**. Example for
   `ReportManager`:

   ```
   https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_reports_reportmanager.htm
   ```

Do not implement report logic from memory — confirm the API surface against the
reference for the current API version first. This stays in effect long‑term.

## Interview discipline (MANDATORY)

Apply [guard/interview-discpline](guard/interview-discpline) on every sub‑skill
whenever an iteration has an FAQ / question step. This stays in effect long‑term.
