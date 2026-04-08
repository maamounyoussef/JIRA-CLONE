import { LightningElement, track, wire } from 'lwc';
import getWorkflow from '@salesforce/apex/workflow.WorkflowController.getWorkflow';
import addValidationRule from '@salesforce/apex/workflow.WorkflowController.addValidationRule';
import deleteValidationRule from '@salesforce/apex/workflow.WorkflowController.deleteValidationRule';
import addWorkflowTransition from '@salesforce/apex/workflow.WorkflowController.addWorkflowTransition';
import activateValidationRule from '@salesforce/apex/workflow.WorkflowController.activateValidationRule';
import activateWorkflowTransition from '@salesforce/apex/workflow.WorkflowController.activateWorkflowTransition';
import updateWorkflow from '@salesforce/apex/workflow.WorkflowController.updateWorkflow';

export default class ManageWorkflow extends LightningElement {
    @track workflowId = '';
    @track workflowData = null;
    @track selectedTransition = null;
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showAddValidationRuleModal = false;
    @track showAddTransitionModal = false;
    @track showEditValidationRuleModal = false;
    @track editingRuleId = '';
    
    @track newValidationRule = {
        ticketField: '',
        type: 'not equals'
    };

    @track newTransition = {
        name: '',
        fromStatus: '',
        toStatus: ''
    };

    connectedCallback() {
        // Get workflow ID from URL parameters or props
        const params = new URLSearchParams(window.location.search);
        this.workflowId = params.get('workflowId');
        
        if (this.workflowId) {
            this.loadWorkflow();
        }
    }

    /**
     * Load workflow configuration from controller
     */
    loadWorkflow() {
        this.isLoading = true;
        this.errorMessage = '';
        
        getWorkflow({ workflowId: this.workflowId })
            .then(response => {
                if (response.success) {
                    this.workflowData = response.data;
                    this.successMessage = 'Workflow loaded successfully';
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Error loading workflow';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading workflow: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle transition selection from diagram
     */
    selectTransition(event) {
        const transitionId = event.currentTarget.dataset.transitionId;
        if (this.workflowData && this.workflowData.workflow) {
            this.selectedTransition = this.workflowData.workflow.transitions.find(
                t => t.id === transitionId
            );
        }
    }

    /**
     * Get transitions with computed CSS classes
     */
    get transitionsWithClasses() {
        if (!this.workflowData || !this.workflowData.workflow) {
            return [];
        }
        return this.workflowData.workflow.transitions.map(transition => ({
            ...transition,
            cssClass: this.getTransitionCssClass(transition)
        }));
    }

    /**
     * Get CSS class for transition box based on status
     */
    getTransitionCssClass(transition) {
        let cssClass = 'slds-m-bottom_medium transition-box';
        if (transition.recordStatus === 'active') {
            cssClass += ' transition-box--active';
        } else if (transition.recordStatus === 'pending') {
            cssClass += ' transition-box--pending';
        }
        return cssClass;
    }

    /**
     * Handle Ticket Field change in validation rule form
     */
    handleTicketFieldChange(event) {
        this.newValidationRule.ticketField = event.detail.value;
    }

    /**
     * Handle Validation Type change in validation rule form
     */
    handleValidationTypeChange(event) {
        this.newValidationRule.type = event.detail.value;
    }

    /**
     * Handle Transition Name change in transition form
     */
    handleTransitionNameChange(event) {
        this.newTransition.name = event.detail.value;
    }

    /**
     * Handle From Status change in transition form
     */
    handleFromStatusChange(event) {
        this.newTransition.fromStatus = event.detail.value;
    }

    /**
     * Handle To Status change in transition form
     */
    handleToStatusChange(event) {
        this.newTransition.toStatus = event.detail.value;
    }

    /**
     * Handle add validation rule
     */
    handleAddValidationRule() {
        if (!this.newValidationRule.ticketField || !this.newValidationRule.type) {
            this.errorMessage = 'Please fill all required fields';
            return;
        }

        this.isLoading = true;
        addValidationRule({
            workflowTransitionId: this.selectedTransition.id,
            ticketField: this.newValidationRule.ticketField,
            validationType: this.newValidationRule.type
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.closeAddValidationRuleModal();
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error adding validation rule: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle delete validation rule
     */
    handleDeleteValidationRule(event) {
        const ruleId = event.currentTarget.dataset.ruleId;
        
        if (!confirm('Are you sure you want to delete this validation rule?')) {
            return;
        }

        this.isLoading = true;
        deleteValidationRule({ validationRuleId: ruleId })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error deleting validation rule: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle activate validation rule
     */
    handleActivateValidationRule(event) {
        const ruleId = event.currentTarget.dataset.ruleId;
        
        if (!confirm('Are you sure you want to activate this validation rule?')) {
            return;
        }

        this.isLoading = true;
        activateValidationRule({ validationRuleId: ruleId })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error activating validation rule: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Open add workflow transition modal
     */
    openAddTransitionModal() {
        this.showAddTransitionModal = true;
        this.newTransition = { name: '', fromStatus: '', toStatus: '' };
    }

    /**
     * Close add workflow transition modal
     */
    closeAddTransitionModal() {
        this.showAddTransitionModal = false;
        this.newTransition = { name: '', fromStatus: '', toStatus: '' };
    }

    /**
     * Handle add workflow transition
     */
    handleAddWorkflowTransition() {
        if (!this.newTransition.name || !this.newTransition.fromStatus || !this.newTransition.toStatus) {
            this.errorMessage = 'Please fill all required fields';
            return;
        }

        this.isLoading = true;
        addWorkflowTransition({
            workflowId: this.workflowId,
            name: this.newTransition.name,
            fromStatusId: this.newTransition.fromStatus,
            toStatusId: this.newTransition.toStatus
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.closeAddTransitionModal();
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error adding workflow transition: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle activate workflow transition
     */
    handleActivateTransition(event) {
        const transitionId = event.currentTarget.dataset.transitionId;
        
        if (!confirm('Are you sure you want to activate this transition?')) {
            return;
        }

        this.isLoading = true;
        activateWorkflowTransition({ workflowTransitionId: transitionId })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error activating transition: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle final workflow update
     */
    handleUpdateWorkflow() {
        if (!confirm('This will activate all pending transitions and validation rules. Continue?')) {
            return;
        }

        this.isLoading = true;
        updateWorkflow({ workflowId: this.workflowId })
            .then(response => {
                if (response.success) {
                    this.successMessage = response.message;
                    this.loadWorkflow();
                } else {
                    this.errorMessage = response.message;
                }
            })
            .catch(error => {
                this.errorMessage = 'Error updating workflow: ' + error.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Clear success message after 5 seconds
     */
    clearMessages() {
        setTimeout(() => {
            this.successMessage = '';
        }, 5000);
    }

    /**
     * Get status options for combobox
     */
    get statusOptions() {
        if (!this.workflowData || !this.workflowData.projectStatus) {
            return [];
        }
        return this.workflowData.projectStatus.map(status => ({
            label: status.name,
            value: status.id
        }));
    }

    /**
     * Get ticket field options for combobox
     */
    get ticketFieldOptions() {
        return [
            { label: 'Assigned To', value: 'AssignedTo__c' },
            { label: 'Creator', value: 'Creator__c' },
            { label: 'Current State', value: 'CurrentState__c' },
            { label: 'Description', value: 'Description__c' },
            { label: 'End Date', value: 'EndDate__c' },
            { label: 'Epic', value: 'Epic__c' },
            { label: 'Priority', value: 'Priority__c' },
            { label: 'Start Date', value: 'StartDate__c' },
            { label: 'Story Point', value: 'StoryPoint__c' },
            { label: 'Summary', value: 'Summary__c' },
            { label: 'Type', value: 'Type__c' }
        ];
    }

    /**
     * Get validation type options
     */
    get validationTypeOptions() {
        return [
            { label: 'Not Equals', value: 'not equals' }
        ];
    }

    /**
     * Get pending transitions
     */
    get pendingTransitions() {
        if (!this.workflowData || !this.workflowData.workflow) {
            return [];
        }
        return this.workflowData.workflow.transitions.filter(t => t.recordStatus === 'pending');
    }

    /**
     * Get active transitions
     */
    get activeTransitions() {
        if (!this.workflowData || !this.workflowData.workflow) {
            return [];
        }
        return this.workflowData.workflow.transitions.filter(t => t.recordStatus === 'active');
    }

    /**
     * Get pending validation rules for selected transition
     */
    get pendingValidationRules() {
        if (!this.selectedTransition || !this.selectedTransition.validationRules) {
            return [];
        }
        return this.selectedTransition.validationRules.filter(r => r.recordStatus === 'pending');
    }

    /**
     * Get active validation rules for selected transition
     */
    get activeValidationRules() {
        if (!this.selectedTransition || !this.selectedTransition.validationRules) {
            return [];
        }
        return this.selectedTransition.validationRules.filter(r => r.recordStatus === 'active');
    }
}
