import { LightningElement, track } from 'lwc';
import createTransition from '@salesforce/apex/WorkflowTransitionController.createTransition';
import loadStatuses from '@salesforce/apex/StatusController.loadStatuses';
import loadWorkflows from '@salesforce/apex/WorkflowController.loadWorkflows';

export default class DataWorkflowTransition extends LightningElement {
    @track newTransition = {
        name: '',
        workflowId: '',
        fromStatusId: '',
        toStatusId: '',
        recordStatus: ''
    };
    
    @track workflowOptions = [];
    @track statusOptions = [];
    @track projectId = null;
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

    connectedCallback() {
        this.loadWorkflowOptions();
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
                            value: workflow.Id,
                            projectId: workflow.Project__c
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
     * Load statuses for selected workflow's project
     */
    loadStatusOptions() {
        if (!this.projectId) {
            this.statusOptions = [{ label: 'Select a Status...', value: '' }];
            return;
        }

        loadStatuses({ projectId: this.projectId })
            .then(response => {
                if (response.success && response.data) {
                    this.statusOptions = [
                        { label: 'Select a Status...', value: '' },
                        ...response.data.map(status => ({
                            label: status.Name,
                            value: status.Id
                        }))
                    ];
                } else {
                    this.errorMessage = response.message || 'Failed to load statuses';
                    this.statusOptions = [{ label: 'Select a Status...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading statuses: ' + (error.body?.message || error.message);
                this.statusOptions = [{ label: 'Select a Status...', value: '' }];
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
     * Handle transition name change
     */
    handleNameChange(event) {
        this.newTransition.name = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle workflow selection
     */
    handleWorkflowChange(event) {
        this.newTransition.workflowId = event.target.value;
        
        // Find and set project ID from selected workflow
        const selectedWorkflow = this.workflowOptions.find(w => w.value === event.target.value);
        if (selectedWorkflow) {
            this.projectId = selectedWorkflow.projectId;
            this.loadStatusOptions();
        }
        
        this.errorMessage = '';
    }

    /**
     * Handle from status selection
     */
    handleFromStatusChange(event) {
        this.newTransition.fromStatusId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle to status selection
     */
    handleToStatusChange(event) {
        this.newTransition.toStatusId = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle record status change
     */
    handleRecordStatusChange(event) {
        this.newTransition.recordStatus = event.target.value;
        this.errorMessage = '';
    }

    /**
     * Handle create transition
     */
    handleCreateTransition() {
        // Validate required fields
        if (!this.newTransition.name || !this.newTransition.workflowId || 
            !this.newTransition.fromStatusId || !this.newTransition.toStatusId) {
            this.errorMessage = 'Please fill in Name, Workflow, From Status, and To Status fields';
            return;
        }

        this.isLoading = true;
        createTransition({
            name: this.newTransition.name,
            workflowId: this.newTransition.workflowId,
            fromStatusId: this.newTransition.fromStatusId,
            toStatusId: this.newTransition.toStatusId,
            recordStatus: this.newTransition.recordStatus
        })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Workflow Transition created successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to create workflow transition';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error creating workflow transition: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Reset form fields
     */
    resetForm() {
        this.newTransition = {
            name: '',
            workflowId: '',
            fromStatusId: '',
            toStatusId: '',
            recordStatus: ''
        };
        this.projectId = null;
        this.statusOptions = [{ label: 'Select a Status...', value: '' }];
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
