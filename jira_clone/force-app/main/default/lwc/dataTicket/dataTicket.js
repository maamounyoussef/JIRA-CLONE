import { LightningElement, track } from 'lwc';
import createTicketApex from '@salesforce/apex/TicketController.createTicket';
import SUMMARY_FIELD from '@salesforce/schema/Ticket__c.Summary__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Ticket__c.Description__c';
import START_FIELD from '@salesforce/schema/Ticket__c.StartDate__c';
import END_FIELD from '@salesforce/schema/Ticket__c.EndDate__c';
import STORYPOINT_FIELD from '@salesforce/schema/Ticket__c.StoryPoint__c';
import TICKET_TYPE_FIELD from '@salesforce/schema/Ticket__c.Ticket_Type__c';
import ASSIGNED_FIELD from '@salesforce/schema/Ticket__c.AssignedTo__c';
import CURRENTSTATE_FIELD from '@salesforce/schema/Ticket__c.CurrentState__c';
import SPRINT_FIELD from '@salesforce/schema/Ticket__c.Sprint__c';

import loadProjects from '@salesforce/apex/ProjectController.loadProjects';
import loadMembers from '@salesforce/apex/ProjectMemberController.loadMembers';
import loadTicketTypes from '@salesforce/apex/TicketTypeController.loadTicketTypes';
import loadStatuses from '@salesforce/apex/StatusController.loadStatuses';
import loadSprints from '@salesforce/apex/SprintController.loadSprints';

export default class DataTicket extends LightningElement {
    @track newTicket = {
        summary: '',
        description: '',
        startDate: '',
        endDate: '',
        storyPoint: '',
        typeId: '',
        sprintId: '',
        assignedId: '',
        currentStateId: '',
        projectId: ''
    };

    @track projectOptions = [];
    @track typeOptions = [];
    @track sprintOptions = [];
    @track userOptions = [];
    @track statusOptions = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

    connectedCallback() {
        this.loadProjectOptions();
    }

    loadProjectOptions() {
        loadProjects()
            .then(response => {
                if (response.success && response.data) {
                    this.projectOptions = [ { label: 'Select a Project...', value: '' }, ...response.data.map(p => ({ label: p.Name, value: p.Id })) ];
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load projects';
                    this.projectOptions = [{ label: 'Select a Project...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading projects: ' + (error.body?.message || error.message);
                this.projectOptions = [{ label: 'Select a Project...', value: '' }];
            });
    }

    // Load project members for assignee selection
    loadMemberOptions(projectId) {
        loadMembers({ projectId })
            .then(response => {
                if (response.success && response.data) {
                    this.userOptions = [ { label: 'Select a Member...', value: '' }, ...response.data.map(m => ({ label: (m.User__r ? m.User__r.Name : m.Name), value: m.Id })) ];
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load project members';
                    this.userOptions = [{ label: 'Select a Member...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading members: ' + (error.body?.message || error.message);
                this.userOptions = [{ label: 'Select a Member...', value: '' }];
            });
    }

    handleProjectChange(event) {
        this.newTicket.projectId = event.target.value;
        this.errorMessage = '';
        const projectId = this.newTicket.projectId;
        if (projectId) {
            loadTicketTypes({ projectId })
                .then(res => {
                    if (res.success && res.data) {
                        this.typeOptions = [ { label: 'Select a Type...', value: '' }, ...res.data.map(t => ({ label: t.Name, value: t.Id })) ];
                    } else {
                        this.typeOptions = [{ label: 'Select a Type...', value: '' }];
                    }
                })
                .catch(err => { this.typeOptions = [{ label: 'Select a Type...', value: '' }]; });

            loadStatuses({ projectId })
                .then(res => {
                    if (res.success && res.data) {
                        this.statusOptions = [ { label: 'Select a State...', value: '' }, ...res.data.map(s => ({ label: s.Name, value: s.Id })) ];
                    } else {
                        this.statusOptions = [{ label: 'Select a State...', value: '' }];
                    }
                })
                .catch(err => { this.statusOptions = [{ label: 'Select a State...', value: '' }]; });

            // load project members (assignees)
            this.loadMemberOptions(projectId);

            loadSprints({ projectId })
                .then(res => {
                    if (res.success && res.data) {
                        this.sprintOptions = [ { label: 'Select a Sprint...', value: '' }, ...res.data.map(sp => ({ label: sp.Name, value: sp.Id })) ];
                    } else {
                        this.sprintOptions = [{ label: 'Select a Sprint...', value: '' }];
                    }
                })
                .catch(err => { this.sprintOptions = [{ label: 'Select a Sprint...', value: '' }]; });
        } else {
            this.typeOptions = [{ label: 'Select a Type...', value: '' }];
            this.statusOptions = [{ label: 'Select a State...', value: '' }];
            this.sprintOptions = [{ label: 'Select a Sprint...', value: '' }];
        }
    }

    handleSummaryChange(event) { this.newTicket.summary = event.target.value; this.errorMessage = ''; }
    handleDescriptionChange(event) { this.newTicket.description = event.target.value; this.errorMessage = ''; }
    handleStartDateChange(event) { this.newTicket.startDate = event.target.value; this.errorMessage = ''; }
    handleEndDateChange(event) { this.newTicket.endDate = event.target.value; this.errorMessage = ''; }
    handleStoryPointChange(event) { this.newTicket.storyPoint = event.target.value; this.errorMessage = ''; }
    handleTypeChange(event) { this.newTicket.typeId = event.target.value; this.errorMessage = ''; }
    handleSprintChange(event) { this.newTicket.sprintId = event.target.value; this.errorMessage = ''; }
    handleAssigneeChange(event) { this.newTicket.assignedId = event.target.value; this.errorMessage = ''; }
    handleStateChange(event) { this.newTicket.currentStateId = event.target.value; this.errorMessage = ''; }

    toggleForm() { this.showForm = !this.showForm; if (!this.showForm) this.resetForm(); }

    handleCreateTicket() {
        if (!this.newTicket.summary || !this.newTicket.typeId) {
            this.errorMessage = 'Please fill in Summary and Type fields';
            return;
        }

        this.isLoading = true;
        const fields = {};
        if (this.newTicket.summary) fields[SUMMARY_FIELD.fieldApiName] = this.newTicket.summary;
        if (this.newTicket.description) fields[DESCRIPTION_FIELD.fieldApiName] = this.newTicket.description;
        if (this.newTicket.startDate) fields[START_FIELD.fieldApiName] = this.formatDateToIso(this.newTicket.startDate);
        if (this.newTicket.endDate) fields[END_FIELD.fieldApiName] = this.formatDateToIso(this.newTicket.endDate);
        if (this.newTicket.storyPoint) fields[STORYPOINT_FIELD.fieldApiName] = Number(this.newTicket.storyPoint);
        if (this.newTicket.typeId) fields[TICKET_TYPE_FIELD.fieldApiName] = this.newTicket.typeId;
        if (this.newTicket.sprintId) fields[SPRINT_FIELD.fieldApiName] = this.newTicket.sprintId;
        if (this.newTicket.assignedId) fields[ASSIGNED_FIELD.fieldApiName] = this.newTicket.assignedId;
        if (this.newTicket.currentStateId) fields[CURRENTSTATE_FIELD.fieldApiName] = this.newTicket.currentStateId;
        // Ticket does not store Project__c directly; TicketType__c determines the project.

        createTicketApex({ ticketJson: JSON.stringify(fields) })
            .then(response => {
                if (response && response.success) {
                    this.successMessage = 'Ticket created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response?.message || 'Failed to create ticket';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating ticket: ' + (error.body?.message || error.message);
            })
            .finally(() => { this.isLoading = false; });
    }
    formatDateToIso(dateStr) {
        if (!dateStr) return dateStr;
        if (dateStr.indexOf('T') !== -1) return dateStr;
        try {
            const iso = new Date(dateStr + 'T00:00:00Z').toISOString();
            return iso;
        } catch (e) {
            return dateStr;
        }
    }

    resetForm() { this.newTicket = { summary: '', description: '', startDate: '', endDate: '', storyPoint: '', typeId: '', sprintId: '', assignedId: '', currentStateId: '', projectId: '' }; }
    clearMessages() { setTimeout(() => { this.successMessage = ''; this.errorMessage = ''; }, 5000); }
}
