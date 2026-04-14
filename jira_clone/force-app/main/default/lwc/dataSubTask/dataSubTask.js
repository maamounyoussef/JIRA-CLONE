import { LightningElement, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import SUBTASK_OBJECT from '@salesforce/schema/Subtask__c';
import SUMMARY_FIELD from '@salesforce/schema/Subtask__c.Summary__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Subtask__c.Description__c';
import START_FIELD from '@salesforce/schema/Subtask__c.StartDate__c';
import STORYPOINT_FIELD from '@salesforce/schema/Subtask__c.StoryPoint__c';
import TICKET_FIELD from '@salesforce/schema/Subtask__c.Ticket__c';
import ASSIGNEE_FIELD from '@salesforce/schema/Subtask__c.Assignee__c';
import CURRENTSTATE_FIELD from '@salesforce/schema/Subtask__c.CurrentState__c';

import loadTickets from '@salesforce/apex/TicketController.loadTickets';
import loadMembers from '@salesforce/apex/ProjectMemberController.loadMembers';
import loadStatuses from '@salesforce/apex/StatusController.loadStatuses';

export default class DataSubTask extends LightningElement {
    @track newSubtask = {
        summary: '',
        description: '',
        startDate: '',
        storyPoint: '',
        ticketId: '',
        assigneeId: '',
        currentStateId: ''
    };

    @track ticketOptions = [];
    @track userOptions = [];
    @track statusOptions = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

    // Map ticketId -> projectId for loading statuses
    ticketProjectMap = {};

    connectedCallback() {
        this.loadTicketOptions();
        // user/member options are loaded per-ticket (project) when ticket is selected
    }

    loadTicketOptions() {
        loadTickets()
            .then(response => {
                if (response.success && response.data) {
                    this.ticketOptions = [
                        { label: 'Select a Ticket...', value: '' },
                        ...response.data.map(t => ({ label: t.Summary__c || t.Id, value: t.Id }))
                    ];
                    // populate map from ticket's ticket type -> project
                    this.ticketProjectMap = {};
                    response.data.forEach(t => { this.ticketProjectMap[t.Id] = t.Ticket_Type__r ? t.Ticket_Type__r.Project__c : null; });
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load tickets';
                    this.ticketOptions = [{ label: 'Select a Ticket...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading tickets: ' + (error.body?.message || error.message);
                this.ticketOptions = [{ label: 'Select a Ticket...', value: '' }];
            });
    }

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

    toggleForm() {
        this.showForm = !this.showForm;
        if (!this.showForm) this.resetForm();
    }

    handleSummaryChange(event) { this.newSubtask.summary = event.target.value; this.errorMessage = ''; }
    handleDescriptionChange(event) { this.newSubtask.description = event.target.value; this.errorMessage = ''; }
    handleStartDateChange(event) { this.newSubtask.startDate = event.target.value; this.errorMessage = ''; }
    handleStoryPointChange(event) { this.newSubtask.storyPoint = event.target.value; this.errorMessage = ''; }

    handleTicketChange(event) {
        this.newSubtask.ticketId = event.target.value;
        this.errorMessage = '';
        const projectId = this.ticketProjectMap[this.newSubtask.ticketId];
        if (projectId) {
            loadStatuses({ projectId })
                .then(res => {
                    if (res.success && res.data) {
                        this.statusOptions = [ { label: 'Select a State...', value: '' }, ...res.data.map(s => ({ label: s.Name, value: s.Id })) ];
                        this.errorMessage = '';
                    } else {
                        this.errorMessage = res.message || 'Failed to load statuses';
                        this.statusOptions = [{ label: 'Select a State...', value: '' }];
                    }
                })
                .catch(err => {
                    this.errorMessage = 'Error loading statuses: ' + (err.body?.message || err.message);
                    this.statusOptions = [{ label: 'Select a State...', value: '' }];
                });
            // also load project members for assignee select
            this.loadMemberOptions(projectId);
        } else {
            this.statusOptions = [{ label: 'Select a State...', value: '' }];
        }
    }

    handleAssigneeChange(event) { this.newSubtask.assigneeId = event.target.value; this.errorMessage = ''; }
    handleStateChange(event) { this.newSubtask.currentStateId = event.target.value; this.errorMessage = ''; }

    handleCreateSubtask() {
        if (!this.newSubtask.summary || !this.newSubtask.ticketId) {
            this.errorMessage = 'Please fill in Summary and Ticket fields';
            return;
        }

        this.isLoading = true;

        const fields = {};
        fields[SUMMARY_FIELD.fieldApiName] = this.newSubtask.summary;
        if (this.newSubtask.description) fields[DESCRIPTION_FIELD.fieldApiName] = this.newSubtask.description;
        if (this.newSubtask.startDate) fields[START_FIELD.fieldApiName] = this.newSubtask.startDate;
        if (this.newSubtask.storyPoint) fields[STORYPOINT_FIELD.fieldApiName] = Number(this.newSubtask.storyPoint);
        fields[TICKET_FIELD.fieldApiName] = this.newSubtask.ticketId;
        if (this.newSubtask.assigneeId) fields[ASSIGNEE_FIELD.fieldApiName] = this.newSubtask.assigneeId;
        if (this.newSubtask.currentStateId) fields[CURRENTSTATE_FIELD.fieldApiName] = this.newSubtask.currentStateId;

        const recordInput = { apiName: SUBTASK_OBJECT.objectApiName, fields };

        createRecord(recordInput)
            .then(() => {
                this.successMessage = 'Subtask created successfully!';
                this.resetForm();
                this.clearMessages();
            })
            .catch(error => {
                this.errorMessage = 'Error creating subtask: ' + (error.body?.message || error.message);
            })
            .finally(() => { this.isLoading = false; });
    }

    resetForm() {
        this.newSubtask = { summary: '', description: '', startDate: '', storyPoint: '', ticketId: '', assigneeId: '', currentStateId: '' };
    }

    clearMessages() { setTimeout(() => { this.successMessage = ''; this.errorMessage = ''; }, 5000); }
}
