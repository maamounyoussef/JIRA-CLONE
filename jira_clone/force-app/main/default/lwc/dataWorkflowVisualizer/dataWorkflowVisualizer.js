import { LightningElement, api, track } from 'lwc';
import { 
    calculatePositions, 
    calculateTransitionLines, 
    getSvgViewBox, 
    getStatusesWithSVGData, 
    getMarkerArrow,
    VISUALIZATION_CONFIG,
    toggleClick,
    clearClicks
} from './dataWorkflowVisualizerUtil.js';

export default class DataWorkflowVisualizer extends LightningElement {
    @api workflowData;
    @track statusPositions = {};
    @track activeTransitionLines = [];
    @track pendingTransitionLines = [];
    @track sortedStatuses = [];
    @track showCreateModal = false;
    @track showCreateTransitionModal = false;
    @track selectedFromStatus = null;
    @track selectedToStatus = null;
    @track showTransitionDetail = false;
    @track selectedTransitionId = null;
    @track clickedStatusIds = [];
    
    // Use visualization config from util
    config = VISUALIZATION_CONFIG;

    get startPointRadius() {
        return this.config.startPointRadius || 5;
    }

    get endPointRadius() {
        return this.config.endPointRadius || 5;
    }
    
    get rectRadius() {
        return this.config.rectRadius || 10;
    }

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

        // Separate transitions into active and pending
        let activeTransitions = [];
        let pendingTransitions = [];
        
        if (this.workflowData.workflow.transitions) {
            activeTransitions = this.workflowData.workflow.transitions.filter(
                transition => transition.recordStatus === 'active'
            );
            pendingTransitions = this.workflowData.workflow.transitions.filter(
                transition => transition.recordStatus === 'pending'
            );
        }

        // Extract statuses from both active and pending transitions
        const allTransitions = [...activeTransitions, ...pendingTransitions];
        if (allTransitions && allTransitions.length > 0) {
            allTransitions.forEach(transition => {
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
        
        // Calculate transition lines for active transitions
        const activeWorkflowData = {
            ...this.workflowData,
            workflow: {
                ...this.workflowData.workflow,
                transitions: activeTransitions
            }
        };
        this.activeTransitionLines = calculateTransitionLines(activeWorkflowData, this.statusPositions, this.config);
        
        // Calculate transition lines for pending transitions
        const pendingWorkflowData = {
            ...this.workflowData,
            workflow: {
                ...this.workflowData.workflow,
                transitions: pendingTransitions
            }
        };
        this.pendingTransitionLines = calculateTransitionLines(pendingWorkflowData, this.statusPositions, this.config);
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
        return getStatusesWithSVGData(this.sortedStatuses, this.statusPositions, this.config, this.clickedStatusIds);
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

        // Toggle clicked visual state for the status (use util helper)
        this.clickedStatusIds = toggleClick(this.clickedStatusIds, statusId);
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

        // Clear any clicked status visual state
        this.clickedStatusIds = clearClicks();

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
    handleTransitionCreated(event) {
        const transitionData = event.detail;
        console.log('Transition created successfully:', transitionData);

        // Create a new transition object with proper structure
        const newTransition = {
            id: transitionData.id,
            name: transitionData.name,
            fromStatus: transitionData.fromStatus,
            toStatus: transitionData.toStatus,
            recordStatus: transitionData.recordStatus || 'pending'
        };

        // Add new transition to workflow data - create new array reference for reactivity
        if (!this.workflowData.workflow.transitions) {
            this.workflowData = {
                ...this.workflowData,
                workflow: {
                    ...this.workflowData.workflow,
                    transitions: [newTransition]
                }
            };
        } else {
            this.workflowData = {
                ...this.workflowData,
                workflow: {
                    ...this.workflowData.workflow,
                    transitions: [...this.workflowData.workflow.transitions, newTransition]
                }
            };
        }

        // Recalculate positions and lines
        this.processWorkflowData();

        this.clickedStatusIds = clearClicks();

        // Close modal
        this.showCreateTransitionModal = false;
    }

    /**
     * Handle close event from create transition modal
     */
    handleCloseCreateTransitionModal() {
        this.showCreateTransitionModal = false;
        this.selectedFromStatus = null;
        // Clear clicked visual state when closing the transition modal
        this.clickedStatusIds = clearClicks();
    }

    /**
     * Stop event propagation for modal clicks
     */
    stopPropagation(event) {
        event.stopPropagation();
    }

    /**
     * Handle transition deleted event from transition detail component
     */
    handleTransitionDeleted(event) {
        const deletedTransitionId = event.detail.id;
        console.log('Transition deleted:', deletedTransitionId);

        // Remove transition from workflow data - create new array reference for reactivity
        if (this.workflowData.workflow.transitions) {
            this.workflowData = {
                ...this.workflowData,
                workflow: {
                    ...this.workflowData.workflow,
                    transitions: this.workflowData.workflow.transitions.filter(
                        transition => transition.id !== deletedTransitionId
                    )
                }
            };

            // Recalculate positions and lines
            this.processWorkflowData();
        }
    }

    /**
     * Handle close event from transition detail component
     */
    handleCloseTransitionDetail() {
        this.showTransitionDetail = false;
        this.selectedTransitionId = null;
    }
}
