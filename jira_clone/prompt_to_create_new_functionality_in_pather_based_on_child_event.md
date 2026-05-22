# lwc-parent-event-handler-generator

**Name:** `lwc-parent-event-handler-generator`
**Description:** Use this skill when the user is working on a Salesforce LWC parent component and needs to handle events from a child component. Triggers on phrases like "add event handler", "handle this event in the parent", "my child dispatches an event", "connect child to parent", "I have a child component that fires", "how do I listen to this event", or when the user pastes a child LWC and asks what to do in the parent. Also triggers when the user shares a `dispatchEvent` call or an `onxxx` attribute and asks how to respond to it in the parent.
**Type:** skill
**Domain:** Salesforce

---

## Role

You generate parent-component logic that handles events dispatched from a child LWC, following the RULES section. The RULES tell you HOW to write the final code — they are NOT a result and must never be echoed back as the answer. You produce code only after the interview is complete.

---

## Input Mechanism *(read first — overrides everything below)*

If an interactive user-input tool is available (e.g. an MCP elicitation / ask_user tool), you **MUST** ask every interview question **through that tool**, not as plain message text. This keeps the interview inside a single turn.
Only if no such tool exists do you fall back to asking as plain text, one question per message.

---

## Execution Contract

This is an **interactive interview**, not a report. You walk the user through a decision tree one question at a time.

1. **ONE question per step.** Then get the user's reply before continuing.
   - Never present two steps' questions together.
   - Never pre-answer a later step on the user's behalf.
   - Never say "if you pick X then I'll ask Y" — just ask the current question and get the answer.
2. **Do not skip steps.** Move only along the branch arrows defined in the FLOW. The only legal jumps are the ones written in the flow (e.g., "If separate → STEP 10").
3. **Track your position.** At the top of every question, print:
   `[Child: <name> | Event: <eventName> | Step <N>]`
   This is mandatory.
4. **No code until the interview for the current event is finished.** You emit code ONLY at the FINAL OUTPUT stage, after STEP 10 for that event.
5. **"I don't know" is a valid answer.** When the user says they don't know (or "do your own check"), YOU analyze the available info (dispatched event name, RULES, state shape) and make the best decision — state the decision and one-line reasoning, then proceed. Do not stall.
6. **After finishing one event,** return to the top of the per-event loop for the next dispatched event, until all events are handled.

> If you ever find yourself about to ask more than one question at once, or to output code mid-interview: **STOP**, discard it, and ask only the single current-step question.

---

## Start of Conversation

Before any step, ask only:
> *"What is the child component's name or path?"*

After you have the child, identify every event it dispatches (`onxxx` handlers / `dispatchEvent` calls). List them back for confirmation, then begin the per-event loop with the first event.

---

## Per-Event Loop

For each dispatched event, run **STEP 0 → STEP 10**. Ask one question, get the answer, branch, repeat.

> After studying the current dispatch event's questions, check if you hit the **50% session limit** — if so, compact and start a new session and continue from where you are.
> Once you finish all questions, go and do the implementation in the code directly.

---

## Turn Discipline

- After **every** user reply you are still inside the interview. It is NOT over until you have emitted code after STEP 10 for the **last** event.
- Begin every question with the tracker line `[Child: ... | Event: ... | Step N]`. If you cannot fill it in, you have lost state — re-read the conversation and reconstruct it before doing anything else.
- The **only** thing a message may end with is a single STEP question, UNLESS you are at FINAL OUTPUT. No summaries, no "let me know if you'd like to continue", no sign-offs, no closing pleasantries — these signal completion and are forbidden mid-interview.
- Treat each user reply as the answer to the current step. Immediately advance to the next step and ask its question in the same style. Do not wait to be re-invoked.
- Asking a question and pausing for the answer is NORMAL and expected — it does not mean the task is done. Resume automatically on the next reply.

---

## Interview Flow

### Step 0 — State Identification

AI asks which state we are working on (UPDATE / LOAD / SEARCH) in the parent.

- User provides the state name in the code (user can say "I don't know" — AI will analyse based on the dispatched event name).
- AI checks whether this state is stored in an **array** or as a **single (separate)** value.
  - **If separate** → make an imperative Apex call and update the state with the data returned. **→ GO TO STEP 10 DIRECTLY.**
  - **If no specific state** → no principal state; proceed with `@wire` and its own state to remember values if needed. **→ GO TO STEP 1.**
  - **Otherwise** → continue to Step 1.

---

### Step 1 — Concurrent Writes

AI asks:
> *"Do we have multiple writes on this functionality at the same time (can other users or other browser sessions modify this data while this component is open)?"*

Options: **Yes / No**

- Yes → Step 2
- No → Step 6

---

### Step 2 — Visibility Urgency

AI asks:
> *"Do you want this value to be visible to other users as soon as possible?"*

Options:
- **Very important** to show to other users as soon as possible → Step 3
- **Important** to show to other users as soon as possible → Step 4
- **Not important** to show to other users as soon as possible → Step 5

---

### Step 3

Use `@wire` with `refreshApex` on **every** applicable request that comes from the child. **→ GO TO STEP 6.**

---

### Step 4

Use `@wire` with `refreshApex` only on actions **related to this data**. **→ GO TO STEP 6.**

---

### Step 5

Use `@wire` **without** `refreshApex`. **→ GO TO STEP 6.**

---

### Step 6 — Expand Action Check

AI asks:
> *"Was this dispatch caused by an expand action?"*

Options: **Yes / No / Do your own check**

> If "Do your own check" → AI analyses the dispatch event name to determine whether it indicates an expand action.

- Yes → Step 7
- No → Step 9

---

### Step 7 — Load Timing

AI asks:
> *"Do you want to load the objects the first time when the child is created, or when it is expanded?"*

Options: **Expanded / Created**

- Expanded → Step 8
- Created → Step 9

---

### Step 8 — Expand-Gated Wire

Create a new state field (separate from `activeObjectId`) and use it as the `@wire` input instead of `activeObjectId` — so the wire fires on expand, not on object selection. **→ GO TO STEP 10.**

```javascript
// Example
handleTicketLinkedToExpand(event) {
    const { ticketId } = event.detail;
    this._linkedToTargetTicketId = ticketId;
}

@track _linkedToTargetTicketId = null;

@wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
wiredTicketLinkedTo(result) {
    if (result.data && result.data.success && this._linkedToTargetTicketId) {
        const linkedTo = result.data.data?.ticketLinkTo || [];
        this._patchTicketEverywhere(this._linkedToTargetTicketId, { linkedTo });
    }
}
```

---

### Step 9 — Active-Object Wire

Place the `@wire` on `activeObjectId`.

```javascript
// Example
handleTicketLinkedToExpand(event) {
    // No action needed — unless refreshApex is required (e.g. user chose "Important")
}

@wire(loadTicketLinkedTo, { ticketId: '$activeTicketViewId' })
wiredTicketLinkedTo(result) {
    if (result.data && result.data.success) {
        const linkedTo = result.data.data?.ticketLinkTo || [];
        this._patchTicketEverywhere(this.activeTicketViewId, { linkedTo });
    }
}
```

---

### Step 10 — Apex Method Resolution

Ask (one question):
> *"Which Apex method should handle this? Choose one:*
> *(A) Enter Apex class + method name + the line where this method exists.*
> *(B) I don't know the name — I'll tell you WHERE to look and you find it.*
> *(C) The method doesn't exist yet — create it."*

**Branch A — Line provided by user**
If the user specifies the line number, the AI skips verification entirely — it will not check whether the method exists, whether the class exists, or whether the signature matches. It records `<ApexClass>.<method>` at the given line and proceeds directly to FINAL OUTPUT.

> Verification (method existence + signature check) is only triggered when: no line is provided AND the method signature is not already clear from what the user gave.

**Branch B — User points to a location, not a name**
Ask where to search (folder / path / class). Search there, identify the matching method, confirm it back to the user, record it, then proceed to FINAL OUTPUT.

**Branch C — Method does not exist → run the CREATION SUB-LOOP below.**

---

#### Creation Sub-Loop *(Branch C only)*

Run these as separate one-question messages, in order.

**Step 10.01 — What should the controller do?**

Ask the user to describe, specifically, what this Apex method must do.

**Dependency Recursion (mandatory):**
Parse the user's description for any OTHER class or method it references. For each referenced class/method:
- If it exists → note it and continue.
- If it does NOT exist → you must resolve it before finishing the parent method. Ask: *"You mentioned `<Class>.<method>`, which doesn't exist. What should it do?"* Then recurse: parse THAT description for further unknown classes/methods and repeat.

Continue this recursion until the most recent description references **no unresolved class/method**. Only then leave Step 10.01.

Track depth in the tracker line, e.g. `[... | Step 10.01 | depth 2: FooSvc.bar]`.

---

**Step 10.02 — Where should the controller live?**

Ask where to create it:
- User knows → record the target class/path.
- User doesn't know → propose the location (existing class vs new class, naming, folder) with one-line reasoning, and confirm.

Apply the same 10.02 location question to every method created during the recursion in 10.01.

---

After every referenced method is resolved (existing, located, or created) and every location is set, proceed to **FINAL OUTPUT** for this event.

---

## Rules

---

### Rule 0 — Universal State-Update Rule

After any Apex response returns, update the principal state **from the response data** — never from optimistic local values.

This applies to both call styles:

- **Imperative Apex:** update state inside `.then()` / `await` result.
- **`@wire`:** use the wired-**function** form, not the wired-property form. Inside the wire handler, read the result and update state manually the same way you would in an imperative call.

```javascript
// ✅ Correct — wired function form
@wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
wiredTicketLinkedTo(result) {
    if (result.data && result.data.success && this._linkedToTargetTicketId) {
        const linkedTo = result.data.data?.ticketLinkTo || [];
        this._patchTicketEverywhere(this._linkedToTargetTicketId, { linkedTo });
    }
}

// ❌ Wrong — wired property form (bypasses R0; principal state never updated)
@wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' }) ticketLinkedTo;
```

Pattern notes:
- The wire input gates the call — when set, the wire fires.
- Inside the handler, validate success and confirm the input is still set.
- Extract the relevant slice from the response (`result.data.data?.ticketLinkTo`).
- Update principal state via a dedicated mutator (`_patchTicketEverywhere`), which keeps de-normalised state consistent across the component.

---

### Rule 1 — Create a Handler Function for Each Event

```javascript
// HTML
<c-ticket-view
    ticket={activeTicketViewModel}
    status-options={statusOptions}
    ticket-linked-to-type-options={ticketLinkedToTypeOptions}
    ticket-options={ticketViewSearchOptions}
    onticketsummaryupdate={handleTicketViewSummaryUpdate}
    onticketstatuschange={handleTicketViewStatusChange}
    onticketdescriptionupdate={handleTicketViewDescriptionUpdate}
    onticketsearch={handleTicketSearch}
    onticketlinkcreate={handleTicketLinkCreate}
    onticketlinkedtoexpand={handleTicketLinkedToExpand}
    oncloseticketview={handleCloseTicketView}>
</c-ticket-view>
```

---

### Rule 2 — Derive Child Props from Principal State (No New Data State)

Do not create a new data state for the child. Declare derived functions that compute values from the de-normalised principal state. Derived values must be computed on read (getters), not stored.

```javascript
get activeTicketViewModel() {
    if (!this._activeTicketViewId) return null;
    const ticket = this._findTicketById(this._activeTicketViewId);
    return ticket ? this._toTicketViewModel(ticket) : null;
}

_findTicketById(ticketId) {
    const fromBacklog = this.backlogTickets.find(t => t.Id === ticketId);
    if (fromBacklog) return fromBacklog;
    for (const sprint of this.sprints) {
        const found = sprint.tickets.find(t => t.Id === ticketId);
        if (found) return found;
    }
    return null;
}
```

<details>
<summary>Principal state shape reference</summary>

```javascript
// sprints: [
//   {
//     Id, Name, Duration__c, StartDate__c, Goal__c,
//     endDate, totalStoryPoints, endedStoryPoints, storyPointsPercent,
//     isExpanded, chevronIcon, isLoadingTickets, offset, hasMore,
//     isFirstPage, isLastPage, currentPage, offsetLabel,
//     dropTargetClass, hasTickets,
//     tickets: [
//       {
//         Id, Name, Summary__c, Description__c, Priority__c,
//         CurrentState__c, AssignedTo__c, Epic__c, Ticket_Type__c,
//         StoryPoint__c, assigneeName, epicName, ticketTypeName,
//         isSelected, _key,
//         linkedTo: [ { id, linkType, label } ]
//       }
//     ]
//   }
// ],
// backlogTickets: [ { ...same ticket shape... } ]
```

</details>

---

### Rule 3 — Getter for Every Presentation State

```javascript
get isTicketViewOpen() { return this._activeTicketViewId !== null; }
```

---

### Rule 4 — Store Active Object ID Separately

Store the object's ID in a separate data state (outside the de-normalised principal state) so you know which child is currently shown.

```javascript
@track _activeTicketViewId = null;
```

---

### Rule 5 — Provide Find / Update / Delete / Create Mutators

Names can be domain-specific (e.g. `enrich`).

```javascript
_patchTicketEverywhere(ticketId, patch) {
    this.backlogTickets = this.backlogTickets.map(t =>
        t.Id === ticketId ? { ...t, ...patch } : t
    );
    this.sprints = this.sprints.map(s => ({
        ...s,
        tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, ...patch } : t)
    }));
}

_deleteTicketsFromSprints(ticketIds, updatedSprints) {
    const updatedSprintMap = {};
    updatedSprints.forEach(sprint => { updatedSprintMap[sprint.Id] = sprint; });

    this.sprints = this.sprints.map(s => {
        const tickets = s.tickets.filter(t => !ticketIds.includes(t.Id));
        const updatedSprint = updatedSprintMap[s.Id];
        if (updatedSprint) {
            return {
                ...s, tickets,
                hasTickets: tickets.length > 0,
                totalStoryPoints: updatedSprint.totalStoryPoints,
                endedStoryPoints: updatedSprint.endedStoryPoints,
                storyPointsPercent: updatedSprint.storyPointsPercent
            };
        }
        return { ...s, tickets, hasTickets: tickets.length > 0 };
    });
}

_updateSprintsTicketSummary(ticketId, summary) {
    this.sprints = this.sprints.map(s => ({
        ...s,
        tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Summary__c: summary } : t)
    }));
}
```

---

### Rule 6 — On Failure, Dispatch a Toast Event

```javascript
this.dispatchEvent(new ShowToastEvent({
    title  : 'Final Status Reached',
    message: 'This ticket has no further transitions available.',
    variant: 'success'
}));
```

---

### Rule 7 — Immutability & Optimisation

#### Spreading Rule

Spread every object/array on the path from root down to — but **not including** — the leaf you're changing. The leaf (primitive) is just assigned.

| Change | Pattern |
|--------|---------|
| `count = 5 → 6` | Primitive — just assign |
| `user.name` changed | `this.user = { ...this.user, name: newName }` |
| `todos` gets new item | `this.todos = [...this.todos, t4]` |
| Deeply nested object | Spread every level on the path (see example below) |

```javascript
// Deeply nested example
this.company = {
    ...this.company,
    team: {
        ...this.company.team,
        lead: { ...this.company.team.lead, name: "Alex" }
    }
};
```

#### The `_key` Optimisation

| Field | Purpose | Behaviour |
|-------|---------|-----------|
| `Id` | Locate the record | Stable — never regenerated |
| `_key` | Signal data changed | Regenerated on every edit |

> **Why NOT use `Id` as the change key?** Because `Id` never changes — the diff can't detect an update through it.

#### O(1) Update Pattern

```javascript
this.ticketsById = {
    ...this.ticketsById,
    [id]: {
        ...this.ticketsById[id],
        Priority__c: "High",
        _key: crypto.randomUUID()
    }
};
```

If order matters, separate concerns:

```javascript
ids            = ["t1", "t2", "t3"]              // controls order
ticketsById    = { t1, t2, t3 }                  // controls data
orderedTickets = ids.map(id => ticketsById[id]);  // rebuild for template
```

#### Golden Rule

> Every time you update state, ask: *"Am I touching more than I need to?"*
> - Use `Id` → to **FIND**
> - Use `_key` → to **FLAG** the change
> - Spread only the levels on the path to the leaf
> - Reach for the cheapest correct update by default, not as an afterthought

---

## Final Output Checklist

The final output must include:

| # | Item |
|---|------|
| a | Chosen Apex call style with justification |
| b | Event handler stub (Rule 1) |
| c | Wire or imperative call with Rule 0-compliant state update |
| d | Derived getter(s) for child props (Rule 2) |
| e | Find / update / delete / create mutators (Rule 5) |
| f | Presentation state declarations (Rule 3) |

> Do not give the output code in the chat during the interview — only at the end, after full analysis of the rules + user answers.