AI SHOULD ASK ABOUT THE APEX  CONTROLLER NAME METHOD NAME 
AI SHOULD ASK ME ABOUT THE STATE THAT I NEED TO UPDATE BEFORE START 


how to handle apex response  : 
in the returned object we have success field : 
if success is false  so showEventToast  with show ing the message error in the request  if no message so show based on the mehod caller name .
if success true call the format function  to  format the response enrich or delete or update (based on the method semantic name mean that we call ) then showEventToasSuccess
	
	examples : 

    handleBacklogTicketCreate(event) {
        const data = event.detail;
        createTicketFromBacklog(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from backlog');
                this._enrichBacklogWithTicket(formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId));
                this.showBacklogTicketModal = false;
                this._showSuccess('Ticket created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from backlog'));
    }
	
	
    _enrichBacklogWithTicket(ticket) {
        this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
    }
	
	
	    handleSprintTicketCreate(event) {
        const data = event.detail;
        createTicketFromSprint(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from sprint');
                const ticket        = formatTicket(res.data.createdTicket, this.ticketTypeOptions, data.ticketTypeId);
                const updatedSprint = formatSprint(res.data.updatedSprint);
                this._enrichSprintWithAddedTicket(updatedSprint, ticket);
                this.showSprintTicketModal = false;
                this._showSuccess('Ticket added to sprint');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from sprint'));
    }
	
	
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
    }