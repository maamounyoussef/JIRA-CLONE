import { LightningElement, track } from 'lwc';

export default class ManageWorkflowContainer extends LightningElement {
    @track showForm = true;
    @track showWorkflow = false;
    @track selectedWorkflowId = '';
    @track selectedTicketType = '';
    @track selectedProjectId = '';

    /**
     * Handle launch workflow event from form
     */
    handleLaunchWorkflow(event) {
        const { ticketType, projectId } = event.detail;
        this.selectedTicketType = ticketType;
        this.selectedProjectId = projectId;
        
        // TODO: Query for workflow ID based on ticket type and project ID
        // TODO: call getWorkflow in WorkflowController for now just display the returned object
        
        this.showForm = false;
        this.showWorkflow = true;
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
    }
}
