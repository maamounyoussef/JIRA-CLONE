import { LightningElement, api } from 'lwc';
import createStatus from '@salesforce/apex/StatusController.createStatus';

export default class CreateStatusModal extends LightningElement {
    @api isOpen = false;
    
    statusName = '';
    isLoading = false;
    errorMessage = '';

    /**
     * Get projectId from localStorage
     */
    get projectId() {
        return localStorage.getItem('selectedProjectId');
    }

    /**
     * Handle input change for status name
     */
    handleStatusNameChange(event) {
        this.statusName = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create status
     */
    handleCreate() {
        if (!this.statusName.trim()) {
            this.errorMessage = 'Please enter a status name';
            return;
        }

        const projectId = this.projectId;
        if (!projectId) {
            this.errorMessage = 'Project ID not found. Please select a project first.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        createStatus({ name: this.statusName, projectId: projectId })
            .then(result => {
                console.log('Status created:', result);
                
                if (result.success) {
                    // Dispatch success event with the new status
                    this.dispatchEvent(new CustomEvent('statuscreated', {
                        detail: result.data,
                        bubbles: true,
                        composed: true
                    }));
                    this.closeModal();
                } else {
                    this.errorMessage = result.message || 'Failed to create status';
                }
            })
            .catch(error => {
                console.error('Error creating status:', error);
                this.errorMessage = error.body?.message || 'An error occurred while creating the status';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle close modal
     */
    closeModal() {
        this.statusName = '';
        this.errorMessage = '';
        this.isLoading = false;
        
        this.dispatchEvent(new CustomEvent('close', {
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Handle key press (Enter to submit, Escape to close)
     */
    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleCreate();
        } else if (event.key === 'Escape') {
            this.closeModal();
        }
    }
}

