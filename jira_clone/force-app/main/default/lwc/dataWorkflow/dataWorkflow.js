import { LightningElement, track } from 'lwc';
import createWorkflow from '@salesforce/apex/WorkflowController.createWorkflow';
import loadProjects from '@salesforce/apex/ProjectController.loadProjects';

export default class DataWorkflow extends LightningElement {
    @track newWorkflow = {
        name: '',
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

    /**
     * Load all projects from Salesforce
     */
    loadProjectOptions() {
        this.isLoading = true;
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
     * Handle workflow name change
     */
    handleNameChange(event) {
        this.newWorkflow.name = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle project selection change
     */
    handleProjectChange(event) {
        this.newWorkflow.projectId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create workflow
     */
    handleCreateWorkflow() {
        // Validate required fields
        if (!this.newWorkflow.name || !this.newWorkflow.projectId) {
            this.errorMessage = 'Please fill in Name and Project fields';
            return;
        }

        this.isLoading = true;
        createWorkflow({
            name: this.newWorkflow.name,
            projectId: this.newWorkflow.projectId
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Workflow created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to create workflow';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating workflow: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Reset form fields
     */
    resetForm() {
        this.newWorkflow = {
            name: '',
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
