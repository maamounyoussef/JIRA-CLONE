count = 5 → user changes it to 6. New reference? (Trick question — primitives don't have "references" the same way. Assignment is always a new value.)

user = { name, email } → user changes name. To trigger LWC, you must reassign:
this.user = { ...this.user, name: newName }. ✓

todos = [t1, t2, t3] → user adds t4. You must reassign:
this.todos = [...this.todos, t4]. ✓

profile = { name, hobbies: [...] } → user edits hobbies[1]. You must reassign:
this.profile = { ...this.profile, hobbies: [...] with index 1 replaced }. ✓

company = { team: { lead: { name: "Sam" } } }
this.company = {
  ...this.company,
  team: {
    ...this.company.team,
    lead: {
      ...this.company.team.lead,
      name: "Alex"   // ← this is a primitive, just assigned, not spread
    }
  }
}
Why not spread name? Because name is a primitive — "Alex" is the new value. 
Rule : Spread every object/array on the path from the root down to (but not including) the leaf you're changing. The leaf itself is just assigned.


Every level you reach into, you must reassign at the top. You can't just spread the inner array — you also have to spread the outer object.

company = { team: { lead: { name: "Sam", skills: ["js", "apex"] } } }
User adds "lwc" to skills
i should spread skills , because it was a array of object taht compared by reference and i should still company , team , lead because each of them is complex object taht compared by reference 
code : this.company = {
  ...this.company,
  team: {
    ...this.company.team,
    lead: {
      ...this.company.team.lead,
      skills: [...this.company.team.lead.skills, "lwc"]
    }
  }
}
EXAMPLE FROM PROJECT : 
    _enrichBacklogWithTicket(ticket) {
        this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
    }
EXAMPLE FROM PROJECT : 
	  _deleteTicketFromSprints(ticketId, updatedSprint) {
        this.sprints = this.sprints.map(s => {
            const tickets = s.tickets.filter(t => t.Id !== ticketId);
            if (s.Id === updatedSprint?.Id) {
                return {
                    ...s,
                    tickets,
                    hasTickets: tickets.length > 0,
                    totalStoryPoints: updatedSprint.totalStoryPoints,
                    endedStoryPoints: updatedSprint.endedStoryPoints,
                    storyPointsPercent: updatedSprint.storyPointsPercent
                };
            }
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });


OPTIMIZATION : GIVE EACH ITEM A GENERATED KEY (NOT THE RECORD Id)

Problem with arrays : to update one ticket immutably you must .map() over the whole list. Even though only one ticket changed, .map() rebuilds the entire array and walks every element → O(n).

tickets = [t1, t2, t3] → update t2.Priority__c
this.tickets = this.tickets.map(t =>
  t.Id === id ? { ...t, Priority__c: "High" } : t
);
// new array reference + visits every element

Why NOT use the record Id as the change key : the Id never changes. It is stable for the lifetime of the record, so it tells you nothing about whether the data inside changed. If you key your template / cache on Id, the key is identical before and after the edit, so a key comparison can't see that the ticket was updated. The Id is good for *finding* the ticket, not for *detecting a change* to it.

Better : give each item its own generated key that you regenerate every time you change that item. The key changes → the diff knows that item changed, without re-scanning the others.

generate a fresh key on each update (uuid, crypto.randomUUID(), or a counter)
this.ticketsById = {
  ...this.ticketsById,
  [id]: {
    ...this.ticketsById[id],
    Priority__c: "High",
    _key: crypto.randomUUID()   // ← new key signals "this one changed"
  }
};
// O(1) update : only the changed ticket gets a new reference AND a new key

Why this still follows the spreading rule : ticketsById is a complex object compared by reference, so we spread it (...this.ticketsById). The single ticket we change is also a complex object compared by reference, so we spread it too ({ ...this.ticketsById[id] }). Priority__c and _key are primitives, so they're just assigned. Same path-from-root-to-leaf rule — we jump straight to the entry by id, then stamp it with a new generated key so the change is detectable.

Id vs generated key — two different jobs :
- Id   → locating the record (stable, never regenerated)
- _key → detecting that the record's data changed (regenerated on every edit)

Trade-off : a plain object doesn't guarantee display order the way an array index does. If order matters, keep a separate ids array for ordering and the object for the data :
ids = ["t1", "t2", "t3"]   // controls order
ticketsById = { t1, t2, t3 } // controls data
orderedTickets = ids.map(id => ticketsById[id]); // rebuild for the template

EXAMPLE FROM PROJECT : here the ticket gets a fresh generated key on update, not its Id
    handleTicketDragEnd(evt) {
        const { ticketId }         = evt.detail;
        const newCurrentStatusId   = this._dragToStatusId;
        if (ticketId && newCurrentStatusId) {
            this._sprint = {
                ...this._sprint,
                tickets: this.tickets.map(t =>
                    t.Id === ticketId ? { ...t, key: newTicketKey(), CurrentState__c: newCurrentStatusId } : t
                )
            };
        }
        this._clearDragState();
    }
Notice : t.Id === ticketId only *finds* the dragged ticket (Id is stable), while key: newTicketKey() *flags the change* by stamping a fresh generated key. _sprint and the matched ticket are both spread because they're complex objects compared by reference; CurrentState__c and key are primitives, just assigned.

Summary :
- array + .map() → simple, preserves order, but O(n) per update
- object keyed by Id, with a generated _key per item → O(1) update, and the regenerated key (not the stable Id) is what flags the change; manage order separately

ALWAYS THINK IN OPTIMISATION : every time you update state, ask "am I touching more than I need to?" Don't rebuild a whole array when one item changed, don't spread levels you aren't on the path to, and use a stable Id to locate but a regenerated key to signal the change. Reaching for the cheapest correct update should be the default habit, not an afterthought.