import { LightningElement, api, track } from 'lwc';

export default class CreateTransitionModal extends LightningElement {
    @api fromStatus = null;
    @api toStatus = null;
    @api isOpen = false;
    
    @track transitionName = '';
    @track isCreating = false;

    /**
     * Handle transition name input change
     */
    handleInputChange(event) {
        this.transitionName = event.target.value;
    }

    /**
     * Handle create transition button click
     */
    handleCreateTransition() {
        if (!this.transitionName.trim()) {
            alert('Please enter a transition name');
            return;
        }

        this.isCreating = true;

        // Dispatch event with transition data
        const event = new CustomEvent('createtransition', {
            detail: {
                name: this.transitionName,
                fromStatusId: this.fromStatus?.id,
                toStatusId: this.toStatus?.id,
                fromStatusName: this.fromStatus?.name,
                toStatusName: this.toStatus?.name
            }
        });
        this.dispatchEvent(event);

        // Reset and close
        this.transitionName = '';
        this.isCreating = false;
        this.closeModal();
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
        this.transitionName = '';
        const event = new CustomEvent('close');
        this.dispatchEvent(event);
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
