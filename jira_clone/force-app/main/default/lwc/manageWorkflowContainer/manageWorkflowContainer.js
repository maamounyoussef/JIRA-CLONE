import { LightningElement, track } from 'lwc';
import getTicketTypeById from '@salesforce/apex/TicketTypeController.getTicketTypeById';
import getWorkflow from '@salesforce/apex/ManageWorkflowPageController.getWorkflow';

export default class ManageWorkflowContainer extends LightningElement {
    @track showForm = true;
    @track showWorkflow = false;
    @track selectedWorkflowId = '';
    @track selectedTicketType = '';
    @track selectedProjectId = '';
    @track workflowData = null;
    @track isLoading = false;
    @track errorMessage = '';

    /**
     * Handle launch workflow event from form
     * Queries ticket type by ID to get workflow ID, then loads the workflow configuration
     */
    handleLaunchWorkflow(event) {
        const { ticketType, projectId } = event.detail;
        this.selectedTicketType = ticketType;
        this.selectedProjectId = projectId;
        
        // Save project ID to localStorage
        localStorage.setItem('selectedProjectId', projectId);
        
        this.isLoading = true;
        this.errorMessage = '';
        
        // Step 1: Get ticket type by ID to retrieve workflow ID
        getTicketTypeById({ ticketTypeId: ticketType })
            .then(response => {
                if (response.success && response.data) {
                    const ticketTypeRecord = response.data;
                    const workflowId = ticketTypeRecord.Workflow__c;
                    
                    if (!workflowId) {
                        this.errorMessage = 'Ticket type does not have a workflow assigned';
                        this.isLoading = false;
                        return;
                    }
                    
                    this.selectedWorkflowId = workflowId;
                    
                    // Step 2: Load workflow configuration
                    return getWorkflow({ workflowId: workflowId });
                } else {
                    this.errorMessage = response.message || 'Failed to load ticket type';
                    this.isLoading = false;
                    throw new Error(this.errorMessage);
                }
            })
            .then(response => {
                if (response && response.success && response.data) {
                    console.log('Workflow data loaded:', response.data);
                    // Set workflow data for visualization component (dataWorkflowVisualizer)
                    this.workflowData = response.data;
                    this.showForm = false;
                    this.showWorkflow = true;
                } else if (response) {
                    this.errorMessage = response.message || 'Failed to load workflow';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading workflow: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle back button to return to form
     */
    handleBack() {
        this.showWorkflow = false;
        this.showForm = true;
        this.selectedWorkflowId = '';
        this.selectedTicketType = '';
        this.selectedProjectId = '';
        this.workflowData = null;
        this.errorMessage = '';
        
        // Clear project ID from localStorage
        localStorage.removeItem('selectedProjectId');
    }
}