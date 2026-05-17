


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
}Why not spread name? Because name is a primitive — "Alex" is the new value. 
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


	
