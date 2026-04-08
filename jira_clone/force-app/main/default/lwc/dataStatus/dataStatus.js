import { LightningElement, track } from 'lwc';
import createStatus from '@salesforce/apex/StatusController.createStatus';
import loadProjects from '@salesforce/apex/ProjectController.loadProjects';

export default class DataStatus extends LightningElement {
    @track newStatus = {
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
     * Toggle form visibility
     */
    toggleForm() {
        this.showForm = !this.showForm;
        if (!this.showForm) {
            this.resetForm();
        }
    }

    /**
     * Handle status name change
     */
    handleNameChange(event) {
        this.newStatus.name = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle Project selection
     */
    handleProjectChange(event) {
        this.newStatus.projectId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create status
     */
    handleCreateStatus() {
        // Validate required fields
        if (!this.newStatus.name || !this.newStatus.projectId) {
            this.errorMessage = 'Please fill in Name and Project fields';
            return;
        }

        this.isLoading = true;
        createStatus({
            name: this.newStatus.name,
            projectId: this.newStatus.projectId
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Status created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to create status';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating status: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Reset form fields
     */
    resetForm() {
        this.newStatus = {
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
