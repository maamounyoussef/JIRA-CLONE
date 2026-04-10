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
import { workflowVisualizerStatusFromApex, workflowVisualizerTransitionFromApex } from './data/WorkflowVisualizerDTO.js';
import { mapWorkflowVisualizer } from './logic/WorkflowVisualizerMapper.js';
import { validateWorkflowVisualizerStatusName, createWorkflowVisualizerStatus } from './logic/WorkflowVisualizerService.js';

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
    @track workflowModel = null;
    @track newStatusName = '';
    @track isCreatingStatus = false;
    @track createStatusErrorMessage = '';
    
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
        if (!this.workflowData || (!this.workflowData.projectStatus && !this.workflowData.workflow)) {
            return;
        }

        // Normalize incoming data (Apex DTOs or client DTOs) to a predictable DTO shape
        const raw = this.workflowData;
        const normalized = {
            id: raw?.workflow?.id || raw?.id,
            projectStatus: [],
            workflow: { transitions: [] }
        };

        // Normalize statuses (handle Apex shape with Id/Name or already normalized id/name)
        if (Array.isArray(raw.projectStatus) && raw.projectStatus.length) {
            normalized.projectStatus = raw.projectStatus.map(s => {
                if (s.Id || s.Name) return workflowVisualizerStatusFromApex(s);
                return { id: s.id || s.Id || '', name: s.name || s.Name || '' };
            });
        }

        // Normalize transitions (handle Apex shape or already-normalized)
        if (raw.workflow && Array.isArray(raw.workflow.transitions) && raw.workflow.transitions.length) {
            normalized.workflow.transitions = raw.workflow.transitions.map(t => {
                if (t.Id || t.Name || t.FromStatusId) return workflowVisualizerTransitionFromApex(t);
                return {
                    id: t.id || t.Id || '',
                    name: t.name || t.Name || '',
                    fromStatus: t.fromStatus || t.FromStatus || t.from || '',
                    toStatus: t.toStatus || t.ToStatus || t.to || '',
                    recordStatus: t.recordStatus || t.RecordStatus || 'pending'
                };
            });
        }

        // Map to business model using the mapper
        const workflowModel = mapWorkflowVisualizer(normalized);
        this.workflowModel = workflowModel;

        // Gather statuses and transitions from the business model
        const statusMap = new Map();
        workflowModel.statuses.forEach(s => statusMap.set(s.id, { id: s.id, name: s.name }));

        // Ensure any statuses referenced by transitions are included
        const allTransitions = workflowModel.transitions.map(t => ({ id: t.id, name: t.name, fromStatus: t.fromStatus, toStatus: t.toStatus, recordStatus: t.recordStatus }));
        allTransitions.forEach(transition => {
            if (transition.fromStatus && !statusMap.has(transition.fromStatus)) {
                statusMap.set(transition.fromStatus, { id: transition.fromStatus, name: transition.fromStatus });
            }
            if (transition.toStatus && !statusMap.has(transition.toStatus)) {
                statusMap.set(transition.toStatus, { id: transition.toStatus, name: transition.toStatus });
            }
        });

        this.sortedStatuses = Array.from(statusMap.values());
        this.statusPositions = calculatePositions(this.sortedStatuses, this.config);

        // Split transitions by recordStatus
        const activeTransitions = allTransitions.filter(t => t.recordStatus === 'active');
        const pendingTransitions = allTransitions.filter(t => t.recordStatus === 'pending');

        // Calculate transition lines
        this.activeTransitionLines = calculateTransitionLines({ workflow: { transitions: activeTransitions } }, this.statusPositions, this.config);
        this.pendingTransitionLines = calculateTransitionLines({ workflow: { transitions: pendingTransitions } }, this.statusPositions, this.config);
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
        let transition = null;
        if (this.workflowModel && Array.isArray(this.workflowModel.transitions)) {
            transition = this.workflowModel.transitions.find(t => t.id === lineId);
        }
        if (!transition && this.workflowData && this.workflowData.workflow && Array.isArray(this.workflowData.workflow.transitions)) {
            transition = this.workflowData.workflow.transitions.find(t => t.id === lineId);
        }
        
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
     * Handle input change for the create-status modal
     */
    handleStatusNameChange(event) {
        this.newStatusName = event.target.value;
        this.createStatusErrorMessage = '';
    }

    handleModalKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleCreateSubmit();
        } else if (event.key === 'Escape') {
            this.closeCreateModal();
        }
    }

    /**
     * Submit create status request (calls repository)
     */
    async handleCreateSubmit() {
        const validation = validateWorkflowVisualizerStatusName(this.newStatusName);
        if (!validation.valid) {
            this.createStatusErrorMessage = validation.message || 'Invalid name';
            return;
        }

        const projectId = localStorage.getItem('selectedProjectId');
        if (!projectId) {
            this.createStatusErrorMessage = 'Project ID not found. Please select a project first.';
            return;
        }

        this.isCreatingStatus = true;
        this.createStatusErrorMessage = '';

        try {
            const result = await createWorkflowVisualizerStatus(this.newStatusName, projectId);
            // Service/repository expected to return { success, data, message }
            if (result && result.success) {
                this.handleStatusCreated({ detail: result.data });
                this.closeCreateModal();
            } else if (result && result.data) {
                this.handleStatusCreated({ detail: result.data });
                this.closeCreateModal();
            } else {
                this.createStatusErrorMessage = result?.message || 'Failed to create status';
            }
        } catch (err) {
            console.error('Error creating status:', err);
            this.createStatusErrorMessage = err?.body?.message || err?.message || 'An error occurred while creating the status';
        } finally {
            this.isCreatingStatus = false;
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
