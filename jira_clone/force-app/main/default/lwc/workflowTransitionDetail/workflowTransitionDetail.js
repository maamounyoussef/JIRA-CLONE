import { LightningElement, api, track } from 'lwc';
import getWorkflowTransitionById from '@salesforce/apex/WorkflowTransitionController.getWorkflowTransitionById';

export default class WorkflowTransitionDetail extends LightningElement {
    @api transitionId;
    @track transitionData = null;
    @track isLoading = false;
    @track errorMessage = '';

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
}
