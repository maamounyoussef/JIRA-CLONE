import { LightningElement, api, track } from 'lwc';
import addWorkflowTransition from '@salesforce/apex/WorkflowTransitionController.addWorkflowTransition';
import { 
    calculatePositions, 
    calculateTransitionLines, 
    getSvgViewBox, 
    getStatusesWithSVGData, 
    getMarkerArrow,
    VISUALIZATION_CONFIG
} from './dataWorkflowVisualizerUtil.js';

export default class DataWorkflowVisualizer extends LightningElement {
    @api workflowData;
    @track statusPositions = {};
    @track transitionLines = [];
    @track sortedStatuses = [];
    @track showCreateModal = false;
    @track showCreateTransitionModal = false;
    @track selectedFromStatus = null;
    @track selectedToStatus = null;
    @track newTransitionName = '';
    @track showTransitionDetail = false;
    @track selectedTransitionId = null;
    
    // Use visualization config from util
    config = VISUALIZATION_CONFIG;

    connectedCallback() {
        this.processWorkflowData();
    }

    @api
    get workflow() {
        return this.workflowData;
    }

    set workflow(value) {
        this.workflowData = value;
        this.processWorkflowData();
    }

    /**
     * Process workflow data and calculate positions
     */
    processWorkflowData() {
        if (!this.workflowData || !this.workflowData.workflow) {
            return;
        }

        // Extract all statuses using ID as key (prevents duplicates)
        const statusMap = new Map();
        
        // Add all statuses from projectStatus
        if (this.workflowData.projectStatus && this.workflowData.projectStatus.length > 0) {
            this.workflowData.projectStatus.forEach(status => {
                statusMap.set(status.id, { id: status.id, name: status.name });
            });
        }

        // Also extract any statuses mentioned in transitions that aren't in projectStatus
        if (this.workflowData.workflow.transitions) {
            this.workflowData.workflow.transitions.forEach(transition => {
                if (transition.fromStatus && !statusMap.has(transition.fromStatus)) {
                    statusMap.set(transition.fromStatus, { id: transition.fromStatus, name: transition.fromStatus });
                }
                if (transition.toStatus && !statusMap.has(transition.toStatus)) {
                    statusMap.set(transition.toStatus, { id: transition.toStatus, name: transition.toStatus });
                }
            });
        }

        this.sortedStatuses = Array.from(statusMap.values());
        this.statusPositions = calculatePositions(this.sortedStatuses, this.config);
        this.transitionLines = calculateTransitionLines(this.workflowData, this.statusPositions, this.config);
    }

    /**
     * Get SVG viewBox dimensions
     */
    get svgViewBox() {
        return getSvgViewBox(this.sortedStatuses, this.config);
    }

    /**
     * Get statuses with SVG rendering data
     * Uses status ID as unique key, displays status name
     */
    get statusesWithSVGData() {
        return getStatusesWithSVGData(this.sortedStatuses, this.statusPositions, this.config);
    }

    /**
     * Get marker arrow path for line endings
     */
    get markerArrow() {
        return getMarkerArrow();
    }

    /**
     * Handle transition line click
     */
    handleTransitionClick(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const transition = this.workflowData.workflow.transitions.find(t => t.id === lineId);
        
        console.log('Transition Clicked:', {
            id: lineId,
            name: transition?.name,
            fromStatus: transition?.fromStatus,
            toStatus: transition?.toStatus,
            fullObject: transition
        });

        // Set state to show transition detail
        this.selectedTransitionId = lineId;
        this.showTransitionDetail = true;
    }

    /**
     * Handle status rectangle click (for drawing line/creating transition)
     */
    handleStatusClick(event) {
        const statusId = event.currentTarget.dataset.statusId;
        const status = this.sortedStatuses.find(s => s.id === statusId);
        
        if (!this.selectedFromStatus) {
            // First click - select from status
            this.selectedFromStatus = status;
            console.log('From Status selected:', status.name);
        } else if (this.selectedFromStatus.id === statusId) {
            // Deselect if clicking same status
            this.selectedFromStatus = null;
            console.log('Selection cleared');
        } else {
            // Second click - select to status and open create transition dialog
            this.selectedToStatus = status;
            console.log('To Status selected:', status.name);
            this.openCreateTransitionModal();
        }
    }

    /**
     * Open modal to create new status
     */
    openCreateStatusModal() {
        this.showCreateModal = true;
        this.newStatusName = '';
    }

    /**
     * Close create modal
     */
    closeCreateModal() {
        this.showCreateModal = false;
        this.selectedFromStatus = null;
        this.selectedToStatus = null;
        this.newTransitionName = '';
    }

    /**
     * Handle status created event from createStatusModal
     */
    handleStatusCreated(event) {
        const newStatus = event.detail;
        console.log('Status created successfully:', newStatus);

        // Create a new status object with proper structure
        const statusToAdd = {
            id: newStatus.Id,
            name: newStatus.Name
        };

        // Add new status to workflow data - create new array reference for reactivity
        if (!this.workflowData.projectStatus) {
            this.workflowData = {
                ...this.workflowData,
                projectStatus: [statusToAdd]
            };
        } else {
            this.workflowData = {
                ...this.workflowData,
                projectStatus: [...this.workflowData.projectStatus, statusToAdd]
            };
        }

        // Recalculate positions and lines
        this.processWorkflowData();

        // Close modal
        this.showCreateModal = false;
    }

    /**
     * Handle close event from create status modal
     */
    handleCreateStatusModalClose() {
        this.showCreateModal = false;
    }

    /**
     * Handle create status - now simplified to open modal
     */
    handleCreateStatus() {
        this.openCreateStatusModal();
    }

    /**
     * Open modal to create transition
     */
    openCreateTransitionModal() {
        this.showCreateTransitionModal = true;
        this.newTransitionName = '';
    }

    /**
     * Handle create transition from modal component
     */
    handleCreateTransitionFromModal(event) {
        const { name, fromStatusId, toStatusId, fromStatusName, toStatusName } = event.detail;
        
        console.log('New Transition Created:', {
            name: name,
            from: fromStatusName,
            to: toStatusName
        });
        
        // Call apex method to persist transition
        addWorkflowTransition({ 
            workflowId: this.workflowData.workflow.id,
            name: name,
            fromStatusId: fromStatusId,
            toStatusId: toStatusId
        })
        .then(result => {
            console.log('Transition saved to database:', result);
            
            // Add new transition to frontend data
            const newTransition = {
                id: result.id,
                name: name,
                fromStatus: fromStatusId,
                toStatus: toStatusId
            };
            
            if (!this.workflowData.workflow.transitions) {
                this.workflowData.workflow.transitions = [];
            }
            this.workflowData.workflow.transitions.push(newTransition);
            this.transitionLines = calculateTransitionLines(this.workflowData, this.statusPositions, this.config);
        })
        .catch(error => {
            console.error('Error saving transition:', error);
            alert('Failed to create transition: ' + error.body?.message);
        })
        .finally(() => {
            this.handleCloseCreateTransitionModal();
        });
    }

    /**
     * Handle close event from create transition modal
     */
    handleCloseCreateTransitionModal() {
        this.showCreateTransitionModal = false;
        this.selectedFromStatus = null;
    }

    handleTransitionNameChange(event) {
        this.newTransitionName = event.target.value;
    }

    /**
     * Stop event propagation for modal clicks
     */
    stopPropagation(event) {
        event.stopPropagation();
    }

    /**
     * Handle close event from transition detail component
     */
    handleCloseTransitionDetail() {
        this.showTransitionDetail = false;
        this.selectedTransitionId = null;
    }
}
