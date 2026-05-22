# Name: lwc-architecture

# Description:

	Use this skill BEFORE creating or scaffolding any new Lightning Web Component
	(or the Apex it talks to) in this project. It is the umbrella architecture
	guide that decides WHICH kind of component you are building, WHERE every file
	goes, and HOW the LWC ↔ Apex layers connect. Triggers include: "create a new
	LWC", "add a new page/screen", "scaffold a component", "I need a new feature
	in the UI", "what's the right structure for X", "where should this Apex method
	live", or any request that starts a new component from scratch.

	This skill orchestrates the two detailed skills:
	- `lwc-child` — how to build presentation child components that dispatch events.
	- `lwc-parent-event-handler-generator` — how the page handles those events and
	  calls Apex.
	Use THIS skill to choose the architecture; use those two to write the code.

---

## ROLE

	You are the architecture gatekeeper. When a new component is requested you do
	NOT immediately write code. You first place the work inside the project's
	layered architecture, decide the component type, confirm the data flow, and
	only then hand off to the implementation skills. The RULES below tell you HOW
	the project is structured — they are the source of truth, not a suggestion.

---

## THE ARCHITECTURE AT A GLANCE

	Data flows in one direction per request and back as a single wrapped response:

	```
	┌──────────────────────────────────────────────────────────────────────┐
	│  LWC LAYER                                                             │
	│                                                                        │
	│   PAGE component (smart)            CHILD components (presentation)    │
	│   - owns principal state            - receive data via @api           │
	│   - calls Apex (imperative/@wire)   - own local presentation state    │
	│   - handles child events            - dispatch CustomEvents up         │
	│   - sidecar: <feature>Utils.js,     - NEVER call Apex                  │
	│     <feature>Validator.js           - NEVER mutate @api                │
	└───────────────┬────────────────────────────────────────────────────────┘
	                │ @salesforce/apex/<Controller>.<method>
	                ▼
	┌──────────────────────────────────────────────────────────────────────┐
	│  APEX LAYER                                                            │
	│                                                                        │
	│   controller/<feature>/<Name>Controller.cls   (thin, @AuraEnabled)    │
	│     • returns APIResponse(success, message, data) ALWAYS              │
	│     • wraps everything in try/catch                                    │
	│     • validates preconditions via DomainCorrectness.requireXExists()   │
	│     • delegates business logic to a Service                            │
	│                          │                                             │
	│                          ▼                                             │
	│   domain/<Name>Service.cls    (business logic + SOQL/DML)             │
	│     • throws ServiceException on failure                               │
	│   domain/DomainCorrectness.cls (existence / precondition guards)       │
	│   domain/<Name>Dto.cls / WorkflowConfigDTO.cls (composite shapes)      │
	│                                                                        │
	│   shared/APIResponse.cls       (the response envelope)                 │
	│   shared/ServiceException.cls  (the only exception services throw)     │
	│   shared/<...>Enum/Util/Constants.cls                                  │
	└──────────────────────────────────────────────────────────────────────┘
	```

	Reference implementations to copy from:
	- Page: `lwc/manageBacklog/` and `lwc/manageWorkflow/`
	- Controller: `classes/controller/managebacklog/ManageBacklogController.cls`
	- Service: `classes/domain/StatusService.cls`, `TicketService.cls`
	- Guards: `classes/domain/DomainCorrectness.cls`
	- Envelope: `classes/shared/APIResponse.cls`

---

## EXECUTION CONTRACT

	1. Do NOT write code until you have answered the DECISION FLOW questions
	   below. Ask the user one question at a time when the answer is not derivable
	   from the request or the codebase.
	2. "I don't know" is valid for analysis you may do yourself (state shape, event
	   payloads, which existing Service/Controller to reuse). For product behavior,
	   user stories, and field-level rules, the user is the source of truth.
	3. When the work crosses layers (new UI that needs new Apex), resolve the Apex
	   side first (does the method exist? if not, where does it go?) so the LWC has
	   a real method to import — never import a method you haven't confirmed/created.
	4. After the architecture is fixed, hand off: child code → `lwc-child` skill;
	   parent/event/Apex wiring → `lwc-parent-event-handler-generator` skill.

---

## DECISION FLOW (run for every new component)

	### Q1 — Is this a PAGE or a CHILD?

	- **PAGE (smart/container):** It is dropped on a Lightning page (App/Home/Record),
	  owns the data, and calls Apex. It is the top of a feature.
	  → It needs `.js`, `.html`, `.css`, `.js-meta.xml` with `isExposed=true` and
	    targets, plus sidecar `<feature>Utils.js` and `<feature>Validator.js`.
	  → Build it like `manageBacklog` / `manageWorkflow`. Use the
	    `lwc-parent-event-handler-generator` skill for its Apex + event handlers.

	- **CHILD (presentation):** It renders a slice of the page's data and reports
	  user intent upward via events. It never talks to Apex.
	  → Build it with the `lwc-child` skill.
	  → If the project convention for this feature is "truly single page" (all
	    sub-sections inline in ONE LWC, no child LWCs — see `manageWorkflow`), then
	    do NOT create a child; render the section inline in the page template and
	    keep its presentation state on the page.

	> Rule of thumb: one PAGE per screen/feature. Reach for a CHILD only when a
	> piece of UI is reused across pages OR is complex enough to isolate. When in
	> doubt for this project, prefer inlining sections in the page (single-page
	> style) over proliferating components.

	### Q2 — What is the PRINCIPAL STATE?

	The page owns one de-normalized object/array tree that mirrors what the screen
	shows (see `manageBacklog.sprints` / `manageWorkflow.workflowData`). Decide its
	shape now. Children receive slices of it via `@api`; they never keep their own
	copy of server data.

	### Q3 — How does the page ENTER / load data?

	This project's pages read their context from `localStorage` in
	`connectedCallback`, then load via Apex:
	- `localStorage.getItem('projectId')` — current project (used by manageBacklog,
	  manageWorkflow, status creation).
	- Feature-specific keys as needed (e.g. manageWorkflow also reads
	  `'ticketTypeId'` and resolves the workflow from it).
	If the key is missing, set `errorMessage` and stop — do not guess.

	### Q4 — What APEX does it call? Does it exist?

	List every operation (Load / Create / Update / Delete / Search). For each, find
	the matching `@AuraEnabled` method in `classes/controller/<feature>/`.
	- Exists → import it: `@salesforce/apex/<Controller>.<method>`.
	- Missing → create it following the APEX RULES below BEFORE wiring the LWC.

	### Q5 — What EVENTS flow up (children only)?

	Per `lwc-child`: lowercase event names; payloads follow Create (data, + parent
	id if nested) / Update (id + changed field) / Delete (id) / Load (parent id).
	The page handles each with one handler (`lwc-parent-event-handler-generator`).

---

## LWC LAYER RULES

	### Files in every bundle
	- `<name>.js` — logic. Organize with section banners (see `manageBacklog.js`):
	  `PAGE`, then one section per domain area, each with PROPERTIES & STATE / APEX
	  CALLS / EVENT HANDLERS / GETTERS / PRIVATE HELPERS.
	- `<name>.html` — template. Bind only to getters/fields, never to expressions.
	- `<name>.css` — scoped styles; design tokens live on the root container.
	- `<name>.js-meta.xml` — `apiVersion`, `isExposed`, `targets`. Pages expose
	  `lightning__AppPage/RecordPage/HomePage`; pure children set `isExposed=false`.

	### Sidecar files (page-level helpers, NO Apex)
	- `<feature>Utils.js` — pure functions: formatting, enrichment, geometry,
	  normalization of Apex shapes → client shapes (see
	  `manageWorkflow/workflowUtils.js`, `manageBacklog/backlogTicketUtils.js`).
	- `<feature>Validator.js` — pure validation; each function returns an error
	  STRING when invalid or `null` when valid (see `backlogSprintValidator.js`,
	  `workflowValidator.js`). Validate on the page before calling Apex AND/OR in
	  the child before dispatching.

	### Page (smart) component — see `lwc-parent-event-handler-generator`
	- Owns principal state; stores active object ids separately (`_activeXId`).
	- Updates state from the Apex RESPONSE, never from optimistic local values
	  (`@wire` → use the wired-FUNCTION form and update state inside it).
	- Provides find / patch / delete / create mutators; spreads immutably down the
	  path to the changed leaf; uses `_key` (not `Id`) to flag a row as changed.
	- Surfaces failures via `ShowToastEvent` (or an inline error region per the
	  feature's existing pattern).

	### Child (presentation) component — see `lwc-child`
	- Data in via `@api` (stored in a `_`-backed getter); presentation state is
	  local and `_`-prefixed; every template value is exposed through a getter.
	- Never calls Apex; never mutates `@api`; only dispatches lowercase
	  `CustomEvent`s (`bubbles: true, composed: true`).

---

## APEX LAYER RULES

	### Controller — `classes/controller/<feature>/<Name>Controller.cls`
	- Thin orchestration only. Every public method is `@AuraEnabled`
	  (`@AuraEnabled(cacheable=true)` for pure reads used by `@wire`).
	- ALWAYS return `APIResponse`: `new APIResponse(true, 'msg', data)` on success,
	  `new APIResponse(false, 'msg')` on failure.
	- Wrap the body in try/catch; on `Exception ex` return
	  `new APIResponse(false, 'Error ...: ' + ex.getMessage())`.
	- Guard inputs: `String.isBlank(...)` checks, then
	  `DomainCorrectness.requireXExists(id)` for every referenced record.
	- Delegate real work to a Service. Do not put SOQL/DML business logic here.

	```apex
	@AuraEnabled
	public static APIResponse createStatus(String name, String projectId) {
	    try {
	        if (String.isBlank(name)) return new APIResponse(false, 'name is required');
	        if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
	        DomainCorrectness.requireProjectExists(projectId);
	        Status__c status = StatusService.createStatus(name, projectId);
	        return new APIResponse(true, 'Status created successfully', status);
	    } catch (Exception ex) {
	        return new APIResponse(false, 'Error creating status: ' + ex.getMessage());
	    }
	}
	```

	### Service — `classes/domain/<Name>Service.cls`
	- `public with sharing`. Holds the SOQL/DML and business rules.
	- Throws `ServiceException` (never bare `Exception`) on failure.
	- Static methods named for the use case (`createStatus`, `loadStatuses`,
	  `findStatus`). One Service per domain object.

	### Guards — `classes/domain/DomainCorrectness.cls`
	- `requireXExists(id)` returns the record or throws `ServiceException`.
	- `requireOptionalXExists(id)` no-ops on blank, else asserts. Reuse these;
	  add a new `requireXExists` here when introducing a new object.

	### DTOs — `classes/domain/<Name>Dto.cls` (or `WorkflowConfigDTO.cls`)
	- Use a DTO when a response is a composite/nested shape (not a single SObject),
	  with `@AuraEnabled` properties matching the client shape the LWC expects.

	### Shared — `classes/shared/`
	- `APIResponse` (envelope), `ServiceException` (only thrown type), plus
	  enums/utils/constants. Don't duplicate these per feature.

	### Creating NEW Apex for a new component
	1. Method belongs in the feature's existing `<Name>Controller`, or a new one
	   under `controller/<feature>/`.
	2. If business logic/DML is new, add it to the matching `<Name>Service`
	   (create the Service if the object has none).
	3. Add `requireXExists` guards to `DomainCorrectness` for any new object.
	4. Add a test class alongside (`<Name>ControllerTest.cls`) — every controller
	   in this project ships with a `*Test` class.

---

## NAMING & FOLDER CONVENTIONS

	- LWC bundle folder = camelCase feature name (`manageWorkflow`); referenced in
	  markup as `c-manage-workflow`.
	- Sidecars: `<feature>Utils.js`, `<feature>Validator.js` inside the bundle.
	- Apex controllers grouped by feature folder: `controller/<feature>/`.
	- Services, guards, DTOs, trigger handlers live flat in `domain/`.
	- Cross-cutting types live in `shared/`.
	- Event names: lowercase, no camelCase, no hyphens (`ticketsummaryupdate`).
	- LWC local/presentation state fields: `_`-prefixed; bound via getters.

---

## HANDOFF CHECKLIST (before writing code)

	| # | Decision | Source |
	|---|----------|--------|
	| a | Page or child (or inline section)? | Q1 |
	| b | Principal state shape | Q2 |
	| c | localStorage entry keys + load call | Q3 |
	| d | Apex methods: exist or to-create (+ Service + guards + test) | Q4 |
	| e | Event names + payloads (children) | Q5 |
	| f | Sidecar Utils/Validator functions needed | LWC rules |
	| g | meta.xml exposure + targets | LWC rules |

	Once a–g are settled:
	- CHILD code → run the `lwc-child` skill.
	- PAGE event handlers + Apex wiring → run the
	  `lwc-parent-event-handler-generator` skill.
