# Project Instructions — Jira Clone

These instructions say **which** discipline applies and **when**. The **how** lives
in the referenced skill / guide `.md` files — read those for the rules, checklists,
and examples. Do not duplicate implementation detail here.

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

## Mandatory‑guides step: optional vs required (MANDATORY)

Every task‑skill under `force-app/skills/development/task-skill/**` opens with a
**"Mandatory guides"** step listing guides from `task-skill/guide/**`. Each guide is
tagged **optional** or **required**, and that tag decides how you read it:

- **optional** → a question for the user determines whether the guide is read.
  Apply it only when the user answers yes; never apply it silently.
- **required** → no question. Look at the scope of the change: read and apply the
  guide when its trigger matches that scope; otherwise skip it and state the skip
  reason in the iteration message.

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

## Interview discipline (MANDATORY)

Apply [guard/interview-discpline](guard/interview-discpline) on every sub‑skill
whenever an iteration has an FAQ / question step. This stays in effect long‑term.
