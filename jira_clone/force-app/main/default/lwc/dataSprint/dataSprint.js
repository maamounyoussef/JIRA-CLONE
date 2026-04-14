import { LightningElement, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import SPRINT_OBJECT from '@salesforce/schema/Sprint__c';
import NAME_FIELD from '@salesforce/schema/Sprint__c.Name';
import START_FIELD from '@salesforce/schema/Sprint__c.StartDate__c';
import DURATION_FIELD from '@salesforce/schema/Sprint__c.Duration__c';
import GOAL_FIELD from '@salesforce/schema/Sprint__c.Goal__c';
import RECORDSTATUS_FIELD from '@salesforce/schema/Sprint__c.RecordStatus__c';
import PROJECT_FIELD from '@salesforce/schema/Sprint__c.Project__c';
import loadProjects from '@salesforce/apex/ProjectController.loadProjects';

export default class DataSprint extends LightningElement {
    @track newSprint = {
        name: '',
        startDate: '',
        duration: '',
        goal: '',
        recordStatus: '',
        projectId: ''
    };

    @track projectOptions = [];
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
                    this.projectOptions = [
                        { label: 'Select a Project...', value: '' },
                        ...response.data.map(project => ({ label: project.Name, value: project.Id }))
                    ];
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

    toggleForm() {
        this.showForm = !this.showForm;
        if (!this.showForm) this.resetForm();
    }

    handleNameChange(event) {
        this.newSprint.name = event.target.value;
        this.errorMessage = '';
    }

    handleStartDateChange(event) {
        this.newSprint.startDate = event.target.value;
        this.errorMessage = '';
    }

    handleDurationChange(event) {
        this.newSprint.duration = event.target.value;
        this.errorMessage = '';
    }

    handleGoalChange(event) {
        this.newSprint.goal = event.target.value;
        this.errorMessage = '';
    }

    handleRecordStatusChange(event) {
        this.newSprint.recordStatus = event.target.value;
        this.errorMessage = '';
    }

    handleProjectChange(event) {
        this.newSprint.projectId = event.target.value;
        this.errorMessage = '';
    }

    handleCreateSprint() {
        if (!this.newSprint.name) {
            this.errorMessage = 'Please fill in the Sprint Name field';
            return;
        }

        this.isLoading = true;

        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.newSprint.name;
        if (this.newSprint.startDate) fields[START_FIELD.fieldApiName] = this.newSprint.startDate;
        if (this.newSprint.duration) fields[DURATION_FIELD.fieldApiName] = Number(this.newSprint.duration);
        if (this.newSprint.goal) fields[GOAL_FIELD.fieldApiName] = this.newSprint.goal;
        if (this.newSprint.recordStatus) fields[RECORDSTATUS_FIELD.fieldApiName] = this.newSprint.recordStatus;
        if (this.newSprint.projectId) fields[PROJECT_FIELD.fieldApiName] = this.newSprint.projectId;

        const recordInput = { apiName: SPRINT_OBJECT.objectApiName, fields };

        createRecord(recordInput)
            .then(() => {
                this.successMessage = 'Sprint created successfully!';
                this.resetForm();
                this.clearMessages();
            })
            .catch(error => {
                this.errorMessage = 'Error creating sprint: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    resetForm() {
        this.newSprint = {
            name: '',
            startDate: '',
            endDate: '',
            duration: '',
            goal: '',
            recordStatus: '',
            projectId: ''
        };
    }

    clearMessages() {
        setTimeout(() => {
            this.successMessage = '';
            this.errorMessage = '';
        }, 5000);
    }
}
