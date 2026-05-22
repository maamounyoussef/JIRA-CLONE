# Name: lwc-child

# Description:

	Use this skill when the user wants to build a new LWC child component or add functionality to an existing one. Triggers include: "create a child component", "add a sub-component to my LWC", "I need a new child for my LWC", "add functionality to this child", "build me an LWC child", or any request that involves building presentation-layer Lightning Web Components that dispatch events to a parent

# lwc Child — Question-by-Question Interview Prompt
## ROLE

	You generate **child-component** logic for Lightning Web Components (LWC).
	Children are presentation layers that hold local presentation state, validate
	input, and **dispatch events** — they never call Apex and never mutate `@api`
	state. The RULES section below tells you HOW to write the final code — the
	RULES are NOT a result and must never be echoed back as the answer. You
	produce code only after the interview is complete.

## INPUT MECHANISM (read first — overrides everything below)

	If an interactive user-input tool is available (e.g. an MCP elicitation /
	ask_user tool), you MUST ask every interview question THROUGH that tool, not
	as plain message text. This keeps the interview inside a single turn.
	Only if no such tool exists do you fall back to asking as plain text, one
	question per message.

## EXECUTION CONTRACT

	This is an interactive interview, not a report. You walk the user through a
	decision tree one question at a time.

	1 - ONE question per Question. Then get the user's reply before continuing.
		- Never present two Questions' questions together.
		- Never pre-answer a later Question on the user's behalf.
		- Never say "if you pick X then I'll ask Y" — just ask the current
		  question and get the answer.
	2 - Do not skip Questions. Move only along the branch arrows defined in the FLOW.
		The only legal jumps are the ones written in the flow
		(e.g., "If add-to-existing → Question 0b").
	3 - Track your position. At the top of every question, print:
		[Child: <name> | Sub-component: <subName> | Question <N>]
		This is mandatory.
	4 - No code until the interview for ALL sub-components is finished. 
	5 - "I don't know" is a valid answer ONLY for analysis the AI is allowed to
		make itself (event payload shape, event name, derived tasks/sub-tasks).
		For user stories, behavior, validations, data state, and base-component
		names, the user is the source of truth — if the user says "I don't know"
		there, you re-ask; you do NOT invent them. When the user defers a decision
		you ARE allowed to make, analyze the available info (user stories, RULES,
		state shape, dispatched event name) and make the best decision — state the
		decision and one-line reasoning, then proceed. Do not stall.
	6 - After finishing one sub-component (Question 0 → Question 5), return to the top of
		the per-sub-component loop for the next sub-component, until the user has
		no more to add and runs `compact`.

	If you ever find yourself about to ask more than one question at once, or to
	output code mid-interview: STOP, discard it, and ask only the single
	current-Question question.

## START OF CONVERSATION

	Before any Question, ask only:
		"Do you want to CREATE A NEW CHILD, or ADD a sub-component / new
		 functionality to an EXISTING child? And in one line — what do you need?"

	- If CREATE NEW CHILD → ask for the new child's name, then begin the
	  per-sub-component loop at Question 1 for the first sub-component.
	- If ADD TO EXISTING CHILD → ask for the existing child's name/path AND its
	  current code (JS + HTML, and any validator). Do not assume the existing
	  code — request it. Then begin the per-sub-component loop at Question 1, scoped
	  to that existing child; the final `compact` build MODIFIES that child in
	  place rather than generating a new one.

## PER-SUB-COMPONENT LOOP

	For each sub-component, run Question 0 → Question 5. Ask one question, get the answer,
	branch, repeat.

	AFTER STUDYING THE CURRENT SUB-COMPONENT'S QUESTIONS, CHECK IF YOU HIT THE 50%
	SESSION LIMIT — IF SO, COMPACT AND START A NEW SESSION AND CONTINUE FROM WHERE
	WE ARE.
	ONCE THE USER RUNS `compact` AND ALL SUB-COMPONENTS ARE DONE, GO AND DO THE
	IMPLEMENTATION IN THE CODE DIRECTLY.

## TURN DISCIPLINE

	- Create a complete FAQ section for this topic. Include multiple questions and answers in one response only. Do not ask follow-up questions and do not continue in another message.
	- After EVERY user reply you are STILL inside the interview. It is NOT over
	  until the user has run `compact` AND you have emitted the code at FINAL
	  OUTPUT for the LAST sub-component.
	- Begin every question with the tracker line
	  [Child: ... | Sub-component: ... | Question N]. If you cannot fill it in, you
	  have lost state — re-read the conversation and reconstruct it before doing
	  anything else.
	- The ONLY thing a message may end with is a single Question question, UNLESS you
	  are at FINAL OUTPUT. No summaries, no "let me know if you'd like to
	  continue", no sign-offs, no closing pleasantries. These signal completion
	  and are forbidden mid-interview.
	- Treat each user reply as the answer to the current Question. Immediately advance
	  to the next Question and ask its question in the same style. Do not wait to be
	  re-invoked.
	- Asking a question and pausing for the answer is NORMAL and expected — it
	  does not mean the task is done. Resume automatically on the next reply.

## THE COMPACT Question — Ending the Interview and Triggering the Build

	`compact` is the signal that the interview is finished and you should now
	produce all the code.

	- **Trigger:** the user types `compact`, OR gives any unambiguous instruction
	  meaning "we're done, build it now."
	- **Before building, you compact** — consolidate everything gathered across
	  all loops into one specification:
		- the full list of **user stories**, grouped per sub-component;
		- the derived **tasks and sub-tasks** for each story (Load / Update /
		  Create / Delete and their UI work);
		- the **behavior** for each sub-component;
		- the **validation rules**;
		- the **data state** (`@api` source) each sub-component reads from;
		- the **reusable base components** to use;
		- the **events** each operation dispatches (per the Create / Update /
		  Delete / Load payload rules in the RULES section).
	- **Coverage gate:** confirm every collected user story maps to at least one
	  task and one dispatched event. If any story is uncovered, report the gap and
	  ask the user to resolve it BEFORE coding — do not silently fill it.
	- **Then, and only then, code everything in one pass**, generating the `.js`,
	  `.html`, and validator files in line with all RULES below.

---

## Overview

	This document defines the architectural patterns, rules, and process for building Lightning Web Components (LWC). Children are presentation layers that dispatch events.

## AI Process — Pass-Through Loop

	The following process guides the AI in building sub-components. Repeat this loop for each new sub-component.

	```
	while (the user wants to add a new sub-component) {
		execute Questions 1–5 below
	}
	```
	
	### QUESTION 0 - AI ask user for if we need to create a full child or we need add sub component to it 

	### QUESTION 1 — Ask for the User Stories

	The AI asks the user for the user stories that apply to this sub-component. Each operation (Load, Update, Create, Delete — or any combination of them) must have its **own** user story. The user writes the stories.

	**Example:**
	- *As a user, I want to see the summary.*
	- *As a user, I want to update the summary.*

	---

	### QUESTION 2 — Ask for the Behavior Prompt

	The AI says: *"Give me the component behavior prompt. It must cover every user story."*

	The AI verifies coverage by **semantic comparison**, not keyword matching.

	#### Coverage Verification Rule

	> ⚠️ **If the behavior prompt does not cover every user story, the AI must reply exactly with:**
	> - *"The following user story is not covered: `<quote the story>`"*
	> - *"Please provide the behavior prompt again, including this part."*
	>
	> **The AI never suggests what the missing behavior should be — the user must write it themselves.**

	**Example — Summary component behavior:**
	> Create an inline editable text field with two states.
	>
	> **State 1 (view mode):** a bold plain-text label with no border, clickable.
	>
	> **State 2 (edit mode):** clicking the label replaces it with a focused, full-width single-line text input bordered in blue. Below the input, right-aligned, two small square icon buttons appear — a checkmark (confirm) and an X (cancel). Confirm saves and returns to view mode; Cancel discards and returns to view mode.

	---

	### Question 3 — Ask for Validation Rules

	The AI asks the user for the validations to enforce before dispatching any event. The user provides them.

	**Example:**
	- *The summary cannot be null or empty.*
	- *The summary cannot exceed 255 characters.*

	---

	### Question 4 — Ask for the Data State

	The AI asks the user which `@api` state provides the data for this sub-component. The user supplies it.

	**Example:**
	- *Use the `ticket` state — its `summary` field.*

	---

	### Question 5 — Ask About Reusable Base Components

	The AI asks whether an existing base LWC component should be used instead of writing the UI from scratch. The user provides the name.

	**Example:**
	- *Use the `c-ao-input` component.*

	---

	## Sub-component Example — Description

	### Question 1 — User Stories
		- *As a user, I want to see the description.*
		- *As a user, I want to update the description.*

	### Question 2 — Behavior

		**State 1 — View mode (default):**
		- A bold "Description" label.
		- A muted placeholder beneath it: *"Add a description..."*.
		- Clicking switches to edit mode.

		**State 2 — Edit mode:**
		- The same "Description" label.
		- A rich-text editor with a formatting toolbar (text size, bold, lists, text color, image, code, emoji, insert, link, undo, redo, history).
		- A drag handle and placeholder inside the editor: *"Type [] to jot down things that don't need to be tracked elsewhere."*
		- A **Save** button and a **Cancel** button below.
		- Cancel returns to view mode. Save stores the content and displays it in view mode in place of the placeholder.

	### Question 3 — Validation
		None.

	### Question 4 — Data State
		Use the `ticket` state — its `description` field.

	### Question 5 — Reusable Component
		`lightning-input-rich-text`.

	---

	## Generated JS Output

	### File: `ticketViewValidator.js`

	```javascript
	/**
	 * Ticket View Validator
	 * LWC-side validation for the Ticket View screen.
	 * Required fields per OBJECT_VALIDATION_LWC_APEX.md (LWC table).
	 */

	const REQUIRED_MSG = {
		summary:      'Summary is required.',
		currentState: 'Current State is required.',
		linkType:     'Link type is required.',
		linkedTicket: 'Linked ticket is required.'
	};

	export function validateTicketSummary(value) {
		const trimmed = (value || '').trim();
		if (!trimmed) return REQUIRED_MSG.summary;
		if (trimmed.length > 255) return 'Summary must be 255 characters or fewer.';
		return null;
	}

	export function validateTicketCurrentState(statusId) {
		if (!statusId) return REQUIRED_MSG.currentState;
		return null;
	}

	export function validateTicketLink({ linkType, toTicketId }) {
		if (!linkType)   return REQUIRED_MSG.linkType;
		if (!toTicketId) return REQUIRED_MSG.linkedTicket;
		return null;
	}
	```

	---

	### File: `ticketView.js`

	```javascript
	export default class TicketView extends LightningElement {

		// ─── @api INPUTS ────────────────────────────────────────────────

		/**
		 * The ticket being viewed. Expected shape:
		 *   {
		 *     id, summary, currentStatusId, description,
		 *     priority, assigneeName,
		 *     linkedTo: [ { linkId, type, ticketId, ticketName, summary,
		 *                   statusId, priority, assigneeName } ]
		 *   }
		 */
		_ticket = {};

		@api
		get ticket() { return this._ticket; }
		set ticket(value) {
			this._ticket = value || {};
			this._draftSummary     = this._ticket.summary     || '';
			this._draftDescription = this._ticket.description || '';
		}

		@api statusOptions = [];

		@api ticketLinkedToTypeOptions = [];

		@api ticketOptions = [];


		// ─── LOCAL EDIT STATE ───────────────────────────────────────────
		@track _isSummaryEditing     = false;
		@track _draftSummary         = '';
		@track _summaryError         = null;

		@track _isDescriptionEditing = false;
		@track _draftDescription     = '';

		@track _statusError          = null;

		@track _isLinkedToExpanded   = false;
		@track _showLinkedToAddForm  = false;
		@track _selectedLinkType     = '';
		@track _selectedLinkedTicket = '';
		@track _linkedToError        = null;


		// ─── GETTERS ────────────────────────────────────────────────────
		get isSummaryEditing()     { return this._isSummaryEditing; }
		get draftSummary()         { return this._draftSummary; }
		get summaryError()         { return this._summaryError; }

		get currentStatusId()      { return this._ticket.currentStatusId || ''; }
		get statusError()          { return this._statusError; }

		get isDescriptionEditing() { return this._isDescriptionEditing; }
		get draftDescription()     { return this._draftDescription; }
		get hasDescription()       { return !!(this._ticket.description && this._ticket.description.trim()); }

		get isLinkedToExpanded()   { return this._isLinkedToExpanded; }
		get chevronIcon()          { return this._isLinkedToExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
		get showLinkedToAddForm()  { return this._showLinkedToAddForm; }
		get linkedToError()        { return this._linkedToError; }

		get isLinkDisabled() {
			return !this._selectedLinkType || !this._selectedLinkedTicket;
		}

		get linkedItems() {
			return Array.isArray(this._ticket.linkedTo) ? this._ticket.linkedTo : [];
		}

		get hasLinkedItems() {
			return this.linkedItems.length > 0;
		}


		// ╔════════════════════════════════════════════════════════════╗
		// ║                      SUMMARY SECTION                       ║
		// ╚════════════════════════════════════════════════════════════╝
		handleTicketSummaryEdit() {
			this._draftSummary     = this._ticket.summary || '';
			this._summaryError     = null;
			this._isSummaryEditing = true;
		}

		handleTicketSummaryChange(event) {
			this._draftSummary = event.detail.value;
			if (this._summaryError) this._summaryError = null;
		}

		handleTicketSummarySave() {
			const error = validateTicketSummary(this._draftSummary);
			if (error) { this._summaryError = error; return; }

			const detail = { ticketId: this._ticket.id, summary: this._draftSummary.trim() };
			console.log('[ticket-view] dispatch ticketsummaryupdate', detail);
			this.dispatchEvent(new CustomEvent('ticketsummaryupdate', {
				detail, bubbles: true, composed: true
			}));
			this._isSummaryEditing = false;
		}

		handleTicketSummaryCancel() {
			this._draftSummary     = this._ticket.summary || '';
			this._summaryError     = null;
			this._isSummaryEditing = false;
		}


		// ╔════════════════════════════════════════════════════════════╗
		// ║                       STATUS SECTION                       ║
		// ╚════════════════════════════════════════════════════════════╝
		handleTicketStatusChange(event) {
			const newStatusId = event.detail.value;
			const error = validateTicketCurrentState(newStatusId);
			if (error) { this._statusError = error; return; }
			this._statusError = null;

			const detail = {
				ticketId:     this._ticket.id,
				fromStatusId: this._ticket.currentStatusId || null,
				toStatusId:   newStatusId
			};
			console.log('[ticket-view] dispatch ticketstatuschange', detail);
			this.dispatchEvent(new CustomEvent('ticketstatuschange', {
				detail, bubbles: true, composed: true
			}));
		}


		// ╔════════════════════════════════════════════════════════════╗
		// ║                     DESCRIPTION SECTION                    ║
		// ╚════════════════════════════════════════════════════════════╝
		handleTicketDescriptionEdit() {
			this._draftDescription     = this._ticket.description || '';
			this._isDescriptionEditing = true;
		}

		handleTicketDescriptionChange(event) {
			this._draftDescription = event.target.value;
		}

		handleTicketDescriptionSave() {
			const detail = { ticketId: this._ticket.id, description: this._draftDescription };
			console.log('[ticket-view] dispatch ticketdescriptionupdate', detail);
			this.dispatchEvent(new CustomEvent('ticketdescriptionupdate', {
				detail, bubbles: true, composed: true
			}));
			this._isDescriptionEditing = false;
		}

		handleTicketDescriptionCancel() {
			this._draftDescription     = this._ticket.description || '';
			this._isDescriptionEditing = false;
		}


		// ╔════════════════════════════════════════════════════════════╗
		// ║                   LINKED-TO LIST SECTION                   ║
		// ╚════════════════════════════════════════════════════════════╝
		handleTicketLinkedToToggle() {
			this._isLinkedToExpanded = !this._isLinkedToExpanded;
			if (this._isLinkedToExpanded) {
				const detail = { ticketId: this._ticket.id };
				console.log('[ticket-view] dispatch ticketlinkedtoexpand', detail);
				this.dispatchEvent(new CustomEvent('ticketlinkedtoexpand', {
					detail, bubbles: true, composed: true
				}));
			} else {
				this._showLinkedToAddForm = false;
				this._linkedToError       = null;
			}
		}

		handleTicketLinkedToAdd() {
			this._isLinkedToExpanded   = true;
			this._showLinkedToAddForm  = true;
			this._selectedLinkType     = '';
			this._selectedLinkedTicket = '';
			this._linkedToError        = null;
		}

		handleTicketLinkedToTypeChange(event) {
			this._selectedLinkType = event.detail.value;
			if (this._linkedToError) this._linkedToError = null;
		}

		handleTicketLinkedToTicketChange(event) {
			this._selectedLinkedTicket = event.detail.value;
			if (this._linkedToError) this._linkedToError = null;
		}

		handleTicketLinkedToTicketSearch(event) {
			const searchTerm = (event.detail.searchTerm || '').trim();
			if (searchTerm.length < 2) return;
			this.dispatchEvent(new CustomEvent('ticketsearch', {
				detail: { searchTerm },
				bubbles: true,
				composed: true
			}));
		}

		handleTicketLinkCreate() {
			const error = validateTicketLink({
				linkType:   this._selectedLinkType,
				toTicketId: this._selectedLinkedTicket
			});
			if (error) { this._linkedToError = error; return; }

			const data = {
				fromTicketId: this._ticket.id,
				toTicketId:   this._selectedLinkedTicket,
				linkType:     this._selectedLinkType
			};

			this.dispatchEvent(new CustomEvent('ticketlinkcreate', {
				detail: data, bubbles: true, composed: true
			}));

			this._showLinkedToAddForm  = false;
			this._selectedLinkType     = '';
			this._selectedLinkedTicket = '';
		}

		handleTicketLinkedToCancel() {
			this._showLinkedToAddForm  = false;
			this._selectedLinkType     = '';
			this._selectedLinkedTicket = '';
			this._linkedToError        = null;
		}


		// ╔════════════════════════════════════════════════════════════╗
		// ║                           CLOSE                            ║
		// ╚════════════════════════════════════════════════════════════╝
		handleClose() {
			this.dispatchEvent(new CustomEvent('closeticketview', {
				bubbles: true, composed: true
			}));
		}
	}

	````````````````````````````````````````````````````
	RULES : 
	---
	
	
	
	### A. Create

		The payload contains the data to be created.

		Always send the new data of the object that we need to create. 

		**Rule of thumb:** Check whether the entity sits at the top level of the denormalized state or inside an array of a higher-level object. If it sits inside an array, include the ID of the containing object.

	### B. Update

		Always send the object's ID together with the changed data.

		- **Single-field update:** the event name reflects that field
		  - Example: `ticketsummaryupdate` for a summary change
		- **Full-object update:** the event name reflects the object
		  - Example: `ticketupdate`
		- **Nested object in an array:** same rule as a single object — send the ID plus the changed data

		**Example — Updating a ticket's summary:**

		```javascript
		const detail = { ticketId: this._ticket.id, summary: this._draftSummary.trim() };
		this.dispatchEvent(new CustomEvent('ticketsummaryupdate', {
			detail, bubbles: true, composed: true
		}));
		// `_draftSummary` is the current edited value.
		```

	### C. Delete

		Send only the object's ID.

	### D. Load

		A load event means "fetch a nested object or array that belongs to a higher-level object." Send the **ID of the higher-level object**.

		**Example — Expanding the linked items of a ticket:** send the `ticketId`.

	---


	## Rule 1 — Children Never Call Apex

		A child component must not invoke Apex directly. It only dispatches a `CustomEvent`.

		### Example

		```javascript
		handleTicketSummarySave() {
			const error = validateTicketSummary(this._draftSummary);
			if (error) { this._summaryError = error; return; }

			const detail = { ticketId: this._ticket.id, summary: this._draftSummary.trim() };
			console.log('[ticket-view] dispatch ticketsummaryupdate', detail);
			this.dispatchEvent(new CustomEvent('ticketsummaryupdate', {
				detail, bubbles: true, composed: true
			}));
			this._isSummaryEditing = false;
		}

		handleTicketLinkedToToggle() {
			this._isLinkedToExpanded = !this._isLinkedToExpanded;
			if (this._isLinkedToExpanded) {
				const detail = { ticketId: this._ticket.id };
				console.log('[ticket-view] dispatch ticketlinkedtoexpand', detail);
				this.dispatchEvent(new CustomEvent('ticketlinkedtoexpand', {
					detail, bubbles: true, composed: true
				}));
			} else {
				this._showLinkedToAddForm = false;
				this._linkedToError       = null;
			}
		}
	```

	---

	## Rule 2 — Data State Comes from `@api`

		Any data the child displays must be received `@api` property. The child stores it in a private backing field (`_ticket`) and exposes it through an `@api` getter.

		### Example

		```javascript
		_ticket = {};

		set ticket(value) {
			this._ticket = value || {};
			this._draftSummary     = this._ticket.summary     || '';
			this._draftDescription = this._ticket.description || '';
		}

		@api
		get ticket() { return this._ticket; }

		@api statusOptions = [];
		@api ticketLinkedToTypeOptions = [];
		@api ticketOptions = [];
		```

	---

	## Rule 3 — The Child Never Mutates `@api` State Directly

		Any change to data state must be sent  via a dispatched event. The child does not modify the `@api` object in place.

	---

	## Rule 4 — The Child Owns Its Local Presentation State

		Presentation state (edit mode flags, draft values, validation errors, expand/collapse flags, local selections) lives in the child and is fully managed by the child. The child can read and update this state freely without dispatch.

		### Example

		```javascript
		// ─── LOCAL EDIT STATE ───────────────────────────────────────────────
		@track _isSummaryEditing     = false;
		@track _draftSummary         = '';
		@track _summaryError         = null;

		@track _isDescriptionEditing = false;
		@track _draftDescription     = '';

		@track _statusError          = null;

		@track _isLinkedToExpanded   = false;
		@track _showLinkedToAddForm  = false;
		@track _selectedLinkType     = '';
		@track _selectedLinkedTicket = '';
		@track _linkedToError        = null;


		// ─── GETTERS ────────────────────────────────────────────────────────
		get isSummaryEditing()     { return this._isSummaryEditing; }
		get draftSummary()         { return this._draftSummary; }
		get summaryError()         { return this._summaryError; }

		get currentStatusId()      { return this._ticket.currentStatusId || ''; }
		get statusError()          { return this._statusError; }

		get isDescriptionEditing() { return this._isDescriptionEditing; }
		get draftDescription()     { return this._draftDescription; }
		get hasDescription()       { return !!(this._ticket.description && this._ticket.description.trim()); }

		get isLinkedToExpanded()   { return this._isLinkedToExpanded; }
		get chevronIcon()          { return this._isLinkedToExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
		get showLinkedToAddForm()  { return this._showLinkedToAddForm; }
		get linkedToError()        { return this._linkedToError; }

		get isLinkDisabled() {
			return !this._selectedLinkType || !this._selectedLinkedTicket;
		}

		get linkedItems() {
			return Array.isArray(this._ticket.linkedTo) ? this._ticket.linkedTo : [];
		}

		get hasLinkedItems() {
			return this.linkedItems.length > 0;
		}
		```

		### Handler Methods

		#### Summary Section

		```javascript
		// ╔════════════════════════════════════════════════════════════════╗
		// ║                       SUMMARY SECTION                          ║
		// ╚════════════════════════════════════════════════════════════════╝

		handleTicketSummaryEdit() {
			this._draftSummary     = this._ticket.summary || '';
			this._summaryError     = null;
			this._isSummaryEditing = true;
		}

		handleTicketSummaryChange(event) {
			this._draftSummary = event.detail.value;
			if (this._summaryError) this._summaryError = null;
		}

		handleTicketSummaryCancel() {
			this._draftSummary     = this._ticket.summary || '';
			this._summaryError     = null;
			this._isSummaryEditing = false;
		}
		```

		#### Description Section

		```javascript
		// ╔════════════════════════════════════════════════════════════════╗
		// ║                     DESCRIPTION SECTION                        ║
		// ╚════════════════════════════════════════════════════════════════╝

		handleTicketDescriptionEdit() {
			this._draftDescription     = this._ticket.description || '';
			this._isDescriptionEditing = true;
		}

		handleTicketDescriptionChange(event) {
			this._draftDescription = event.target.value;
		}

		handleTicketDescriptionCancel() {
			this._draftDescription     = this._ticket.description || '';
			this._isDescriptionEditing = false;
		}
		```

	---

	## Rule 5 — All Sub-components Live Inside the Same LWC

		Sub-components (Summary, Status, Description, Linked Items, etc.) are rendered inside one  LWC template — they are **not** extracted into separate LWC files. Each sub-component is a section in the same HTML template.

		### Example

		```html
		<template>
			<article class="ticket-view">

				<header class="tv-header">
					<c-ao-btn
						icon-name="utility:close"
						variant="bare"
						size="sm"
						title="Close"
						onclick={handleClose}>
					</c-ao-btn>
				</header>

				<!-- ╔══════════════════════════════════════════════════════╗ -->
				<!-- ║                       SUMMARY                        ║ -->
				<!-- ╚══════════════════════════════════════════════════════╝ -->
				<!-- The Summary sub-component is rendered here, NOT in a separate LWC. -->
				<section class="tv-section tv-summary">
					<template if:false={isSummaryEditing}>
						<h1 class="tv-summary__label" onclick={handleTicketSummaryEdit} title="Click to edit">
							{ticket.summary}
						</h1>
					</template>

					<template if:true={isSummaryEditing}>
						<div class="tv-summary__editor">
							<c-ao-input
								class="tv-summary__input"
								variant="label-hidden"
								value={draftSummary}
								required
								onchange={handleTicketSummaryChange}>
							</c-ao-input>
							<template if:true={summaryError}>
								<p class="tv-error">{summaryError}</p>
							</template>
							<div class="tv-summary__actions">
								<c-ao-btn
									icon-name="utility:check"
									variant="primary"
									size="sm"
									title="Confirm"
									onclick={handleTicketSummarySave}>
								</c-ao-btn>
								<c-ao-btn
									icon-name="utility:close"
									variant="secondary"
									size="sm"
									title="Cancel"
									onclick={handleTicketSummaryCancel}>
								</c-ao-btn>
							</div>
						</div>
					</template>
				</section>

				<!-- ╔══════════════════════════════════════════════════════╗ -->
				<!-- ║                    CURRENT STATUS                    ║ -->
				<!-- ╚══════════════════════════════════════════════════════╝ -->
				<!-- The Current Status sub-component is rendered here, NOT in a separate LWC. -->
				<section class="tv-section tv-status">
					<span class="tv-section__label">Status</span>
					<c-ao-combobox
						class="tv-status__combo"
						variant="label-hidden"
						placeholder="Select status"
						value={currentStatusId}
						options={statusOptions}
						onchange={handleTicketStatusChange}>
					</c-ao-combobox>
					<template if:true={statusError}>
						<p class="tv-error">{statusError}</p>
					</template>
				</section>

				<!-- ╔══════════════════════════════════════════════════════╗ -->
				<!-- ║                     DESCRIPTION                      ║ -->
				<!-- ╚══════════════════════════════════════════════════════╝ -->
				<!-- The Description sub-component is rendered here, NOT in a separate LWC. -->
				<section class="tv-section tv-description">
					<h2 class="tv-section__label tv-section__label--bold">Description</h2>

					<template if:false={isDescriptionEditing}>
						<template if:true={hasDescription}>
							<div class="tv-description__view" onclick={handleTicketDescriptionEdit}>
								<lightning-formatted-rich-text value={ticket.description}></lightning-formatted-rich-text>
							</div>
						</template>
						<template if:false={hasDescription}>
							<p class="tv-description__placeholder" onclick={handleTicketDescriptionEdit}>
								Add a description...
							</p>
						</template>
					</template>

					<template if:true={isDescriptionEditing}>
						<lightning-input-rich-text
							value={draftDescription}
							placeholder="Type [] to jot down things that don't need to be tracked elsewhere."
							onchange={handleTicketDescriptionChange}>
						</lightning-input-rich-text>
						<div class="tv-description__actions">
							<c-ao-btn label="Save" variant="primary" size="sm" onclick={handleTicketDescriptionSave}></c-ao-btn>
							<c-ao-btn label="Cancel" variant="ghost" size="sm" onclick={handleTicketDescriptionCancel}></c-ao-btn>
						</div>
					</template>
				</section>

				<!-- ╔══════════════════════════════════════════════════════╗ -->
				<!-- ║                  LINKED WORK ITEMS                   ║ -->
				<!-- ╚══════════════════════════════════════════════════════╝ -->
				<!-- The Linked Work Items sub-component is rendered here, NOT in a separate LWC. -->
				<section class="tv-section tv-linked">

					<header class="tv-linked__header">
						<button class="tv-linked__toggle" type="button" onclick={handleTicketLinkedToToggle}>
							<lightning-icon icon-name={chevronIcon} size="xx-small"></lightning-icon>
							<span class="tv-linked__title">Linked work items</span>
						</button>

						<template if:true={isLinkedToExpanded}>
							<c-ao-btn
								icon-name="utility:add"
								variant="bare"
								size="sm"
								title="Add linked item"
								onclick={handleTicketLinkedToAdd}>
							</c-ao-btn>
						</template>
					</header>

					<template if:true={isLinkedToExpanded}>
						<div class="tv-linked__body">
							<p class="tv-linked__sublabel">blocks</p>

							<template if:true={hasLinkedItems}>
								<template for:each={linkedItems} for:item="item">
									<div key={item.linkId} class="tv-linked__row">
										<input type="checkbox" class="tv-linked__check" data-link-id={item.linkId} />
										<!-- ID intentionally hidden per spec -->
										<span class="tv-linked__hidden-id">{item.ticketId}</span>
										<span class="tv-linked__name">{item.ticketName}</span>
										<span class="tv-linked__summary">{item.summary}</span>
										<c-ao-combobox
											class="tv-linked__status"
											variant="label-hidden"
											placeholder="State"
											value={item.statusId}
											options={statusOptions}>
										</c-ao-combobox>
										<span class="tv-linked__priority">{item.priority}</span>
										<span class="tv-linked__assignee">{item.assigneeName}</span>
									</div>
								</template>
							</template>

							<template if:false={hasLinkedItems}>
								<p class="tv-linked__empty">No linked items.</p>
							</template>

							<template if:true={showLinkedToAddForm}>
								<div class="tv-linked__form">
									<div class="tv-linked__form-row">
										<c-ao-combobox
											class="tv-linked__form-type"
											variant="label-hidden"
											placeholder="Link type..."
											options={ticketLinkedToTypeOptions}
											onchange={handleTicketLinkedToTypeChange}>
										</c-ao-combobox>

										<c-auto-complete-combo-box
											class="tv-linked__form-ticket"
											variant="label-hidden"
											placeholder="Search ticket (min 2 chars)..."
											options={ticketOptions}
											onchange={handleTicketLinkedToTicketChange}
											onsearch={handleTicketLinkedToTicketSearch}>
										</c-auto-complete-combo-box>
									</div>

									<template if:true={linkedToError}>
										<p class="tv-error">{linkedToError}</p>
									</template>

									<div class="tv-linked__form-actions">
										<c-ao-btn label="Cancel" variant="ghost" size="sm" onclick={handleTicketLinkedToCancel}></c-ao-btn>
										<c-ao-btn label="Link" variant="primary" size="sm" disabled={isLinkDisabled} onclick={handleTicketLinkCreate}></c-ao-btn>
									</div>
								</div>
							</template>
						</div>
					</template>

				</section>
			</article>
		</template>
		```

	---

	## Rule 6 — Event Names Are Lowercase

	All dispatched `CustomEvent` names use lowercase letters only — no camelCase, no hyphens.

		**Examples:**
		- ✅ `ticketsummaryupdate`
		- ✅ `ticketstatuschange`
		- ❌ `ticketSummaryUpdate`
		- ❌ `ticket-summary-update`

	---

	## Rule 7 — Event Payload Shape Depends on Operation Type



	## Rule 8 — Always Expose Values to HTML Through Getters

		Without exception, every value bound in the template is exposed via a getter — never a raw class field.

	---

	## Rule 9 — Local (Presentation) State Variables Always Start with `_`

		Every private/local state field is prefixed with an underscore.

		**Examples:**
		- ✅ `_draftSummary`
		- ✅ `_isSummaryEditing`
		- ✅ `_linkedToError`
		- ❌ `draftSummary`
		- ❌ `isSummaryEditing`

	---