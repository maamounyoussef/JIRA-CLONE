import { LightningElement, api, track } from 'lwc';
import getWorkflowTransitionById from '@salesforce/apex/WorkflowTransitionController.getWorkflowTransitionById';
import activateWorkflowTransition from '@salesforce/apex/WorkflowTransitionController.activateWorkflowTransition';
import deleteWorkflowTransition from '@salesforce/apex/WorkflowTransitionController.deleteWorkflowTransition';

export default class WorkflowTransitionDetail extends LightningElement {
    @api transitionId;
    @track transitionData = null;
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track isActivating = false;
    @track isDeleting = false;

    connectedCallback() {
        if (this.transitionId) {
            this.loadTransitionDetail();
        }
    }

    /**
     * Load transition details from apex controller
     */
    loadTransitionDetail() {
        this.isLoading = true;
        this.errorMessage = '';
        
        getWorkflowTransitionById({ transitionId: this.transitionId })
            .then(response => {
                if (response.success && response.data) {
                    this.transitionData = response.data;
                    console.log('Transition Detail Loaded:', this.transitionData);
                } else {
                    this.errorMessage = response.message || 'Failed to load transition';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading transition: ' + (error.body?.message || error.message);
                console.error('Error loading transition:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle close button click
     */
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * Activate workflow transition
     */
    handleActivateTransition() {
        if (!this.transitionData || !this.transitionData.Id) {
            this.errorMessage = 'Cannot activate: Transition data not loaded';
            return;
        }

        this.isActivating = true;
        this.errorMessage = '';
        this.successMessage = '';

        activateWorkflowTransition({ workflowTransitionId: this.transitionData.Id })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Transition activated successfully!';
                    // Update local state to show active status
                    this.transitionData.RecordStatus__c = 'active';
                    console.log('Transition activated:', this.transitionData.Id);
                    // Clear success message after 3 seconds
                    setTimeout(() => {
                        this.successMessage = '';
                    }, 3000);
                } else {
                    this.errorMessage = response.message || 'Failed to activate transition';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error activating transition: ' + (error.body?.message || error.message);
                console.error('Error activating transition:', error);
            })
            .finally(() => {
                this.isActivating = false;
            });
    }

    /**
     * Delete workflow transition
     */
    handleDeleteTransition() {
        if (!this.transitionData || !this.transitionData.Id) {
            this.errorMessage = 'Cannot delete: Transition data not loaded';
            return;
        }

        // Confirm deletion
        if (!confirm(`Are you sure you want to delete the transition "${this.transitionData.Name}"?`)) {
            return;
        }

        this.isDeleting = true;
        this.errorMessage = '';
        this.successMessage = '';

        deleteWorkflowTransition({ workflowTransitionId: this.transitionData.Id })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Transition deleted successfully!';
                    console.log('Transition deleted:', this.transitionData.Id);
                    // Close panel after successful deletion
                    setTimeout(() => {
                        this.dispatchEvent(new CustomEvent('close'));
                    }, 1500);
                } else {
                    this.errorMessage = response.message || 'Failed to delete transition';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error deleting transition: ' + (error.body?.message || error.message);
                console.error('Error deleting transition:', error);
            })
            .finally(() => {
                this.isDeleting = false;
            });
    }

    /**
     * Get formatted date
     */
    get formattedCreatedDate() {
        if (!this.transitionData || !this.transitionData.CreatedDate) {
            return '';
        }
        const date = new Date(this.transitionData.CreatedDate);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    /**
     * Get from status name
     */
    get fromStatusName() {
        if (!this.transitionData) {
            return '';
        }
        return this.transitionData.FromStatus__r?.Name || this.transitionData.FromStatus__c || '';
    }

    /**
     * Get to status name
     */
    get toStatusName() {
        if (!this.transitionData) {
            return '';
        }
        return this.transitionData.ToStatus__r?.Name || this.transitionData.ToStatus__c || '';
    }

    /**
     * Check if transition can be activated (only if pending)
     */
    get canActivate() {
        return this.transitionData && this.transitionData.RecordStatus__c === 'pending';
    }
}
