import { LightningElement, track } from 'lwc';
import getProjectStatuses from '@salesforce/apex/workflow.WorkflowController.getProjectStatuses';
import loadProjects from '@salesforce/apex/project.ProjectController.loadProjects';
import loadTicketTypes from '@salesforce/apex/tickettype.TicketTypeController.loadTicketTypes';

export default class ManageWorkflowForm extends LightningElement {
    @track ticketTypeOptions = [];
    @track projectOptions = [];
    @track selectedTicketType = '';
    @track selectedProject = '';
    @track isLoading = false;
    @track errorMessage = '';

    connectedCallback() {
        this.loadTicketTypes();
        this.loadProjects();
    }

    /**
     * Load all ticket types from Salesforce
     */
    loadTicketTypes() {
        if (!this.selectedProject) {
            this.ticketTypeOptions = [];
            return;
        }
        
        this.isLoading = true;
        loadTicketTypes({ projectId: this.selectedProject })
            .then(response => {
                if (response.success && response.data) {
                    this.ticketTypeOptions = response.data.map(ticketType => ({
                        label: ticketType.Name,
                        value: ticketType.Id
                    }));
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load ticket types';
                    this.ticketTypeOptions = [];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading ticket types: ' + error.body?.message || error.message;
                this.ticketTypeOptions = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Load all projects from Salesforce
     */
    loadProjects() {
        this.isLoading = true;
        loadProjects()
            .then(response => {
                if (response.success && response.data) {
                    this.projectOptions = response.data.map(project => ({
                        label: project.Name,
                        value: project.Id
                    }));
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load projects';
                    this.projectOptions = [];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading projects: ' + error.body?.message || error.message;
                this.projectOptions = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle ticket type selection change
     */
    handleTicketTypeChange(event) {
        this.selectedTicketType = event.detail.value;
        this.errorMessage = '';
    }

    /**
     * Handle project selection change
     */
    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        this.selectedTicketType = ''; // Reset ticket type when project changes
        this.errorMessage = '';
        this.loadTicketTypes(); // Reload ticket types for the selected project
    }

    /**
     * Handle button click to launch manage workflow page
     */
    handleLaunchWorkflow() {
        // Validate selections
        if (!this.selectedTicketType || !this.selectedProject) {
            this.errorMessage = 'Please select both Ticket Type and Project';
            return;
        }

        // Dispatch event to parent component with selected values
        const event = new CustomEvent('launchworkflow', {
            detail: {
                ticketType: this.selectedTicketType,
                projectId: this.selectedProject
            }
        });
        this.dispatchEvent(event);
    }

    /**
     * Handle form reset
     */
    handleReset() {
        this.selectedTicketType = '';
        this.selectedProject = '';
        this.errorMessage = '';
    }
}
