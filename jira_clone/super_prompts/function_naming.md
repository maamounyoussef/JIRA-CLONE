function naming : 
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


as you can see this function update the  ticket array for a specific sprint 
so name start with <Sprint> then <Ticket> then the actual handling <Create>