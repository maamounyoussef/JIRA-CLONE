import { LightningElement, api, track } from 'lwc';
import addWorkflowTransition from '@salesforce/apex/WorkflowTransitionController.addWorkflowTransition';

export default class CreateTransitionModal extends LightningElement {
    @api fromStatus = null;
    @api toStatus = null;
    @api isOpen = false;
    @api workflowId = null;
    
    @track transitionName = '';
    @track isCreating = false;
    @track errorMessage = '';

    /**
     * Handle transition name input change
     */
    handleInputChange(event) {
        this.transitionName = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create transition button click
     */
    handleCreateTransition() {
        if (!this.transitionName.trim()) {
            this.errorMessage = 'Please enter a transition name';
            return;
        }

        if (!this.fromStatus || !this.toStatus) {
            this.errorMessage = 'From and To statuses are required';
            return;
        }

        if (!this.workflowId) {
            this.errorMessage = 'Workflow ID is required';
            return;
        }

        this.isCreating = true;
        this.errorMessage = '';

        // Call Apex method to persist transition
        addWorkflowTransition({
            workflowId: this.workflowId,
            name: this.transitionName,
            fromStatusId: this.fromStatus.id,
            toStatusId: this.toStatus.id
        })
        .then(result => {
            console.log('Transition saved to database:', result);
            
            if (result.success) {
                // Dispatch success event with the created transition
                const transitionData = {
                    id: result.data.Id,
                    name: this.transitionName,
                    fromStatus: this.fromStatus.id,
                    toStatus: this.toStatus.id,
                    fromStatusName: this.fromStatus.name,
                    toStatusName: this.toStatus.name
                };

                this.dispatchEvent(new CustomEvent('transitioncreated', {
                    detail: transitionData,
                    bubbles: true,
                    composed: true
                }));

                // Reset and close
                this.resetModal();
            } else {
                this.errorMessage = result.message || 'Failed to create transition';
            }
        })
        .catch(error => {
            console.error('Error creating transition:', error);
            this.errorMessage = error.body?.message || 'An error occurred while creating the transition';
        })
        .finally(() => {
            this.isCreating = false;
        });
    }

    /**
     * Handle cancel button click
     */
    handleCancel() {
        this.closeModal();
    }

    /**
     * Close modal and dispatch close event
     */
    closeModal() {
        this.resetModal();
        this.dispatchEvent(new CustomEvent('close', {
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Reset modal state
     */
    resetModal() {
        this.transitionName = '';
        this.errorMessage = '';
        this.isCreating = false;
    }

    /**
     * Stop event propagation
     */
    handleStopPropagation(event) {
        event.stopPropagation();
    }

    /**
     * Handle overlay click (close on outside click)
     */
    handleOverlayClick(event) {
        if (event.target.classList.contains('modal-overlay')) {
            this.closeModal();
        }
    }
}
