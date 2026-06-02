Before presenting the generated code, walk the checklist. If any row fails, fix
it before emitting code:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Is principal state updated from the Apex **response data**, not from optimistic local values? (Rule 0) | Move the `_patchXxx` call inside `.then()` / the wired-function body. |
| 2 | Is `@wire` used in **wired-function form** when it must update principal state? (Rule 0) | Replace `@wire(...) prop;` with `@wire(...) wiredXxx(result) { ... }`. |
| 3 | Is there one handler function per dispatched event, named `handle<Child><Event>`? (Rule 1) | Split combined handlers; rename per pattern. |
| 4 | Are child props derived from principal state via getters, not stored in a new data state? (Rule 2) | Replace the `@track` field with `get childProp() { return ... }`. |
| 5 | Is every presentation state exposed through a getter? (Rule 3) | Wrap in `get isXxxOpen() { return this._xxxId !== null; }`. |
| 6 | Is the active-object ID stored separately from the principal state? (Rule 4) | Add `@track _activeXxxId = null`. |
| 7 | Are there find / update / delete / create mutators (e.g. `_patchTicketEverywhere`)? (Rule 5) | Add them; never mutate state inline inside a handler. |
| 8 | On Apex failure, is a `ShowToastEvent` dispatched? (Rule 6) | Add the toast in the `.then()` failure branch. |
| 9 | When updating, are all levels on the path to the leaf spread, and is `_key` regenerated to flag the change? (Rule 7) | Apply the spread pattern; use `Id` to find, `_key` to flag. |
| 10 | Does every dispatched event from the child have a handler wired via `onxxx={handler}` in the template? | Add the missing `on<event>={handle<Child><Event>}` attribute. |

## Example

Anti-pattern to detect:

```javascript
// ❌ Optimistic mutation; wired-property form; duplicates child data into
//     parent state; loads on activeObjectId when the user wanted expand-gated.
@wire(loadTicketLinkedTo, { ticketId: '$activeTicketViewId' }) ticketLinkedTo;

handleTicketSummaryUpdate(event) {
    const { ticketId, summary } = event.detail;
    // mutate principal state BEFORE Apex returns
    this._patchTicketEverywhere(ticketId, { Summary__c: summary });
    saveTicketSummary({ ticketId, summary }); // fire-and-forget
}
```

Correct form (per the rules, after the interview):

```javascript
// ✅ Wired-function form, expand-gated where requested, state updated FROM
//    the Apex response (Rule 0), one handler per event (Rule 1).
@track _linkedToTargetTicketId = null;

handleTicketLinkedToExpand(event) {
    this._linkedToTargetTicketId = event.detail.ticketId;
}

@wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
wiredTicketLinkedTo(result) {
    if (result.data && result.data.success && this._linkedToTargetTicketId) {
        const linkedTo = result.data.data?.ticketLinkTo || [];
        this._patchTicketEverywhere(this._linkedToTargetTicketId, { linkedTo });
    }
}

handleTicketSummaryUpdate(event) {
    const { ticketId, summary } = event.detail;
    updateTicketSummary({ ticketId, summary })
        .then(res => {
            if (res?.success) {
                this._patchTicketEverywhere(ticketId, { Summary__c: summary });
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Update failed', message: res?.message, variant: 'error'
                }));
            }
        });
}
```