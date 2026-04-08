import { LightningElement, track } from 'lwc';
import createProject from '@salesforce/apex/ProjectController.createProject';

export default class DataProject extends LightningElement {
    @track newProject = {
        name: ''
    };
    
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

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
     * Handle project name change
     */
    handleNameChange(event) {
        this.newProject.name = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create project
     */
    handleCreateProject() {
        // Validate required fields
        if (!this.newProject.name) {
            this.errorMessage = 'Please fill in the Project Name field';
            return;
        }

        this.isLoading = true;
        createProject({
            name: this.newProject.name
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Project created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to create project';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating project: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Reset form fields
     */
    resetForm() {
        this.newProject = {
            name: ''
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
