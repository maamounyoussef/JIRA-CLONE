import { LightningElement, track } from 'lwc';
import createTicketType from '@salesforce/apex/TicketTypeController.createTicketType';
import loadWorkflows from '@salesforce/apex/WorkflowController.loadWorkflows';
import loadProjects from '@salesforce/apex/ProjectController.loadProjects';

export default class DataTicketType extends LightningElement {
    @track newTicketType = {
        name: '',
        description: '',
        iconUrl: '',
        workflowId: '',
        projectId: ''
    };
    
    @track workflowOptions = [];
    @track projectOptions = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

    connectedCallback() {
        this.loadProjectOptions();
        this.loadWorkflowOptions();
    }

    /**
     * Load all projects from Salesforce
     */
    loadProjectOptions() {
        loadProjects()
            .then(response => {
                if (response.success && response.data) {
                    this.projectOptions = [
                        { label: 'Select a Project...', value: '' },
                        ...response.data.map(project => ({
                            label: project.Name,
                            value: project.Id
                        }))
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

    /**
     * Load all workflows from Salesforce
     */
    loadWorkflowOptions() {
        this.isLoading = true;
        loadWorkflows()
            .then(response => {
                if (response.success && response.data) {
                    this.workflowOptions = [
                        { label: 'Select a Workflow...', value: '' },
                        ...response.data.map(workflow => ({
                            label: workflow.Name,
                            value: workflow.Id
                        }))
                    ];
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load workflows';
                    this.workflowOptions = [{ label: 'Select a Workflow...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading workflows: ' + (error.body?.message || error.message);
                this.workflowOptions = [{ label: 'Select a Workflow...', value: '' }];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Toggle form visibility
     */
    toggleForm() {
        this.showForm = !this.showForm;
        if (!this.showForm) {
            this.resetForm();
        }
    }

    /**
     * Handle ticket type name change
     */
    handleNameChange(event) {
        this.newTicketType.name = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle description change
     */
    handleDescriptionChange(event) {
        this.newTicketType.description = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle icon URL change
     */
    handleIconUrlChange(event) {
        this.newTicketType.iconUrl = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle Project selection
     */
    handleProjectChange(event) {
        this.newTicketType.projectId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle Workflow selection
     */
    handleWorkflowChange(event) {
        this.newTicketType.workflowId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create ticket type
     */
    handleCreateTicketType() {
        // Validate required fields
        if (!this.newTicketType.name || !this.newTicketType.projectId || !this.newTicketType.workflowId) {
            this.errorMessage = 'Please fill in Name, Project, and Workflow fields';
            return;
        }

        this.isLoading = true;
        createTicketType({
            name: this.newTicketType.name,
            description: this.newTicketType.description,
            iconUrl: this.newTicketType.iconUrl,
            workflowId: this.newTicketType.workflowId,
            projectId: this.newTicketType.projectId
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Ticket Type created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to create ticket type';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating ticket type: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Reset form fields
     */
    resetForm() {
        this.newTicketType = {
            name: '',
            description: '',
            iconUrl: '',
            workflowId: '',
            projectId: ''
        };
    }

    /**
     * Clear messages after 5 seconds
     */
    clearMessages() {
        setTimeout(() => {
            this.successMessage = '';
            this.errorMessage = '';
        }, 5000);
    }
}
