# manageProjectMember — Creation Report

This report documents the conversation that produced the new parent LWC
`manageProjectMember`: every question the AI asked, the user's answer, and
every file the AI read along the way — in chronological order.

---

## 1. FAQ — Questions Asked and Answers Received

Listed in the order the AI asked them. Each entry shows the skill step that
drove the question, the question itself, and the user's exact answer.

### Q1 — Component location

- **Skill step:** `create-new-parent-lwc-component` → Step 1 (scaffold).
- **Question:** *"Where should the new parent component `manageProjectMember` live?"*
- **Options:** Default path / Custom path.
- **Answer:** **Default path** — `force-app/main/default/lwc/manageProjectMember/`.

### Q2 — Iteration 1 path selection

- **Skill step:** `create-new-parent-lwc-component` → Step 2 (loop tracker).
- **Question:** *"For the next iteration on `manageProjectMember`, which path?"*
- **Options:** A (new functionality) / B (handle child event) / C (stop).
- **Answer:** **A — Add new functionality**. Delegates to
  `add-interactive-with-data-persistance-functionality-in-pather` sub-skill.

### Q3 — Sub-components + functionality label (Step 2.1, first pass)

- **Skill step:** `add-interactive-with-data-persistance-functionality-in-pather`
  → Step 2.1.
- **Question:** *"Which sub-components does this new functionality apply to?
  (Also, what would you like to call this functionality — e.g. 'addMember',
  'removeMember', 'changeRole'?)"*
- **Options:** "I'll describe them" / "No sub-components".
- **Answer:** **I'll describe them** — followed by the full *Project Members
  Manager — State & Behavior Spec*: default state, project switch, search
  with 180ms debounce + 2-char minimum, "+ Add" affordance, edit modal,
  delete confirmation modal, toast behavior. The AI treated this as the
  Step 2.3 behavior prompt (deferred) and re-asked Step 2.1.

### Q4 — Sub-components (Step 2.1, re-ask)

- **Skill step:** Step 2.1 (re-ask, discipline: do not infer).
- **Question:** *"Which sub-components (custom child LWCs) does this
  `manageMembers` functionality apply to?"*
- **Options:** "I'll list them" / "None — base components only".
- **Answer:** **None — base components only**.

### Q5 — User stories (Step 2.2)

- **Skill step:** Step 2.2.
- **Question:** *"Please write the user stories for `manageMembers` — one
  per operation."*
- **Answer:** **Five stories** (verbatim):
  1. "As a user, I want to select a project so I can see its team members."
  2. "As a user, I want to search for a user so I can add them to the project."
  3. "As a user, I want to add a member so I can give them access to the project."
  4. "As a user, I want to edit a member so I can update their name or role."
  5. "As a user, I want to remove a member so I can revoke their access to the project."

### Q6 — Validation rules (Step 2.4)

- **Skill step:** Step 2.4. (Step 2.3 was covered semantically by the spec
  in Q3; the AI ran a coverage table and proceeded without re-asking.)
- **Question:** *"Which validations must run before each Apex call?"*
- **Options:** "Use those 4 rules (Recommended)" / "I'll write the rules".
- **Answer:** **Use those 4 rules**:
  - **Add** — reject if user already a member.
  - **Edit** — role is in the allowed list.
  - **Delete** — user confirmed in modal.
  - **Search** — query length ≥ 2.

### Q7 — Data state (Step 2.5)

- **Skill step:** Step 2.5. AI flagged two discrepancies between the spec
  and the existing schema (role picklist values, no display-name field).
- **Question:** *"Step 2.5 data state — confirm the object + fields backing
  `manageMembers`. (Note the role picklist + display-name discrepancies.)"*
- **Options:** Use existing schema as-is / Extend the schema / I'll write the data state.
- **Answer:** **Use existing schema as-is**.
  - Object: `ProjectMember__c` { `Project__c`, `User__c`, `Role__c`, `RecordStatus__c` }.
  - Display name = `User.Name` via the lookup (read-only in the edit modal).
  - Role picklist: PPO, Consultant, Test Factory, Scrum Master, Developer.
  - Spec adjustment: Step 2.4 (b) reduces to "role in allowed list" — the
    "name non-empty" check is dropped because name is read-only.

### Q8 — Base components (Step 2.6, multi-select)

- **Skill step:** Step 2.6.
- **Question:** *"Which existing base components should `manageProjectMember`
  reuse instead of writing UI from scratch?"*
- **Options:** c-ao-input / c-ao-btn / c-ao-combobox / None.
- **Answer:** **c-ao-input + c-ao-btn + c-ao-combobox** (all three).

### Q9 — Apex method resolution branch (Step 2.7)

- **Skill step:** Step 2.7. AI inventoried existing service methods first
  (`loadProjects`, `loadProjectMembers`, `createProjectMember`,
  `findActiveMemberByUserAndProject`) and identified 3 missing.
- **Question:** *"We need 5 @AuraEnabled methods on the parent. Which
  branch?"*
- **Options:** C (create new controller) / A (point to existing) / B (search
  a folder).
- **Answer:** **C — Create new `ManageProjectMemberController`**.

### Q10 — Confirm controller method specs + location (Step 2.7.1 / 2.7.2)

- **Skill step:** Step 2.7 Creation Sub-Loop (Branch C).
- **Question:** *"Do the 5 method specs above match your intent? And where
  should the new controller live?"*
- **Options:** Confirm + `force-app/.../controller/manageProjectMember/` /
  Confirm + different path / Amend method specs.
- **Answer:** **Confirm + default path**.
  - Controller: `force-app/main/default/classes/controller/manageProjectMember/ManageProjectMemberController.cls`.
  - Services live in existing `force-app/main/default/classes/domain/ProjectService.cls`.

### Feedback intervention — SOSL, not SOQL, for user search

- **Trigger:** AI's first attempt to extend `ProjectService.cls` used SOQL
  `Name LIKE '%query%'` and named the method `searchEligibleUsers`.
- **User's correction (verbatim):**
  > "no you use soql you should use sosl for search by term and change the
  > method name to be search by term. you can monitor :
  > `loadTicketBySearchTerm` in `manageBacklogController` in line 59"
- **AI response:** Read `ManageBacklogController.loadTicketBySearchTerm`
  (lines 59–114), adopted the same SOSL pattern (`Search.query` with
  special-character escaping), and renamed the method to
  `searchUsersByTerm`. The "already a member" filter happens in-memory
  after the SOSL call.

### Q11 — Iteration 2 path selection

- **Skill step:** `create-new-parent-lwc-component` → Step 2 (loop tracker).
- **Question:** *"For iteration 2 on `manageProjectMember`, which path?"*
- **Options:** A / B / C (Recommended).
- **Answer:** **C — Stop and finalise**.

### Q12 — Apex method monitor (mandated by CLAUDE.md)

- **Skill step:** `apex-method-monitor` (post-controller hook from
  CLAUDE.md).
- **Question:** *"Create a governor-limit monitoring report for the 6 new
  @AuraEnabled methods on `ManageProjectMemberController`?"*
- **Options:** Yes (generate + run + append) / No (skip).
- **Answer:** **No — skip monitoring**.

---

## 2. Files Read by the AI — In Order

Chronological list of every file the AI inspected, with a one-line note on
why. Glob and grep calls that returned listings only (no file body read)
are still included because they shaped subsequent decisions.

| # | Path | Purpose |
|---|---|---|
| 1 | [force-app/skills/create-new-parent-lwc-component-skill.md](force-app/skills/create-new-parent-lwc-component-skill.md) | Read the entry-point skill the IDE had open. |
| 2 | `force-app/main/default/lwc/manageProjectMember/**/*` (glob) | Confirm no existing component at this name. |
| 3 | `force-app/main/default/lwc/manageBacklog/*` (glob) | Inspect sibling parent's file layout. |
| 4 | `force-app/main/default/lwc/manageWorkflow/*` (glob) | Inspect another sibling parent's file layout. |
| 5 | [force-app/main/default/lwc/manageWorkflow/manageWorkflow.js-meta.xml](force-app/main/default/lwc/manageWorkflow/manageWorkflow.js-meta.xml) | Match the project's `.js-meta.xml` conventions for the new scaffold. |
| 6 | [force-app/skills/add-interactive-with-data-persistance-functionality-in-pather-skill.md](force-app/skills/add-interactive-with-data-persistance-functionality-in-pather-skill.md) | Path A delegation target — read full sub-skill before running the interview. |
| 7 | `force-app/main/default/objects/ProjectMember__c/fields/*.field-meta.xml` (glob) | Enumerate the data-state object's fields. |
| 8 | `force-app/main/default/objects/Project__c/fields/*.field-meta.xml` (glob) | Confirm Project__c has only `BacklogMaxScore__c` custom. |
| 9 | [force-app/main/default/objects/ProjectMember__c/fields/User__c.field-meta.xml](force-app/main/default/objects/ProjectMember__c/fields/User__c.field-meta.xml) | Confirm `User__c` is a Lookup to `User`. |
| 10 | [force-app/main/default/objects/ProjectMember__c/fields/Role__c.field-meta.xml](force-app/main/default/objects/ProjectMember__c/fields/Role__c.field-meta.xml) | Discover the actual Role picklist values (PPO, Consultant, Test Factory, Scrum Master, Developer) — drove the Step 2.5 discrepancy flag. |
| 11 | `ls force-app/main/default/lwc/` filter `^ao*` (bash) | Enumerate available base components for Step 2.6. |
| 12 | `ls force-app/main/default/classes/controller/` (bash) | See controller folder convention. |
| 13 | `ls force-app/main/default/classes/controller/chooseproject/` (bash) | See an existing thin controller's file layout. |
| 14 | `grep -l "ProjectMember" force-app/main/default/classes/` (bash) | Locate any class already touching ProjectMember__c. |
| 15 | `grep "ProjectMember" ProjectService.cls` (bash) | Identify the 4 existing ProjectMember service methods. |
| 16 | [force-app/main/default/classes/domain/ProjectService.cls](force-app/main/default/classes/domain/ProjectService.cls) | Read the existing service to plan additions and reuse. |
| 17 | [force-app/main/default/classes/controller/chooseproject/ProjectSplashController.cls](force-app/main/default/classes/controller/chooseproject/ProjectSplashController.cls) | Confirm thin-controller pattern: try/catch → service → APIResponse. |
| 18 | [OBJECT_VALIDATION_LWC_APEX.md](OBJECT_VALIDATION_LWC_APEX.md) | Apply `object-required-fields` rule: ProjectMember__c required = Project__c (LWC) + User__c (Apex). |
| 19 | `ls force-app/main/default/classes/` (bash) | Locate the `shared/` folder. |
| 20 | `find APIResponse* ServiceException*` (bash) | Resolve the envelope + exception types. |
| 21 | [force-app/main/default/classes/guide/APIResponse.cls](force-app/main/default/classes/guide/APIResponse.cls) | Confirm `APIResponse(success, message, data)` constructor signature. |
| 22 | `ls force-app/main/default/lwc/manageBacklog` (bash find) | Locate manageBacklog reference files. |
| 23 | [force-app/main/default/lwc/manageBacklog/manageBacklog.js](force-app/main/default/lwc/manageBacklog/manageBacklog.js) (lines 1–100) | Study a real parent's wire/import/state conventions. |
| 24 | `grep "localStorage\|projectId" manageBacklog.js` (bash) | Decide whether this parent needs the localStorage projectId entry; opted for self-contained selector instead. |
| 25 | `ls force-app/skills/` (bash) | Discover the CSS design skill. |
| 26 | [force-app/skills/lwc-css-design-skill.md](force-app/skills/lwc-css-design-skill.md) (lines 1–60) | Read the design-system overview (palette, fonts). |
| 27 | [force-app/skills/lwc-css-design-skill.md](force-app/skills/lwc-css-design-skill.md) (lines 60–260) | Read color / typography / spacing / state recipes. |
| 28 | [force-app/main/default/lwc/aoBtn/aoBtn.js](force-app/main/default/lwc/aoBtn/aoBtn.js) | Learn the `c-ao-btn` API (variant, size, icon-name, label, title). |
| 29 | [force-app/main/default/lwc/aoInput/aoInput.js](force-app/main/default/lwc/aoInput/aoInput.js) | Learn the `c-ao-input` API (value, variant, change event shape). |
| 30 | [force-app/main/default/lwc/aoCombobox/aoCombobox.js](force-app/main/default/lwc/aoCombobox/aoCombobox.js) | Learn the `c-ao-combobox` API (options, value, change event shape). |
| 31 | `grep "modal\|scrim\|overlay" manageBacklog.css` (bash) | Locate reusable modal CSS classes. |
| 32 | [force-app/main/default/lwc/manageBacklog/manageBacklog.css](force-app/main/default/lwc/manageBacklog/manageBacklog.css) (lines 100–200) | Copy modal-backdrop + modal + modal__title / __footer / __error recipes verbatim. |
| 33 | [force-app/main/default/classes/controller/managebacklog/ManageBacklogController.cls](force-app/main/default/classes/controller/managebacklog/ManageBacklogController.cls) (lines 50–130) | After user feedback: study `loadTicketBySearchTerm` (line 59) for the SOSL escape + `Search.query` pattern. |
| 34 | [force-app/main/default/classes/controller/chooseproject/ProjectSplashController.cls-meta.xml](force-app/main/default/classes/controller/chooseproject/ProjectSplashController.cls-meta.xml) | Match the apiVersion / status in the new controller's meta. |
| 35 | `ls docs/` (bash) | Confirm `docs/` folder before writing this report. |

---

## 3. Files Written / Modified

For completeness — not part of the FAQ, but the artifacts those answers
produced.

| Action | Path |
|---|---|
| Created | [force-app/main/default/lwc/manageProjectMember/manageProjectMember.js-meta.xml](force-app/main/default/lwc/manageProjectMember/manageProjectMember.js-meta.xml) |
| Created | [force-app/main/default/lwc/manageProjectMember/manageProjectMember.js](force-app/main/default/lwc/manageProjectMember/manageProjectMember.js) |
| Created | [force-app/main/default/lwc/manageProjectMember/manageProjectMember.html](force-app/main/default/lwc/manageProjectMember/manageProjectMember.html) |
| Created | [force-app/main/default/lwc/manageProjectMember/manageProjectMember.css](force-app/main/default/lwc/manageProjectMember/manageProjectMember.css) |
| Created | [force-app/main/default/lwc/manageProjectMember/manageProjectMemberValidator.js](force-app/main/default/lwc/manageProjectMember/manageProjectMemberValidator.js) |
| Created | [force-app/main/default/classes/controller/manageProjectMember/ManageProjectMemberController.cls](force-app/main/default/classes/controller/manageProjectMember/ManageProjectMemberController.cls) |
| Created | [force-app/main/default/classes/controller/manageProjectMember/ManageProjectMemberController.cls-meta.xml](force-app/main/default/classes/controller/manageProjectMember/ManageProjectMemberController.cls-meta.xml) |
| Modified | [force-app/main/default/classes/domain/ProjectService.cls](force-app/main/default/classes/domain/ProjectService.cls) — added `searchUsersByTerm` (SOSL), `updateMemberRole`, `softDeleteMember`; added `Role__c` to the `loadProjectMembers` SELECT list. |
