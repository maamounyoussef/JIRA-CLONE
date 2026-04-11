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
import addWorkflowTransitionApex from '@salesforce/apex/WorkflowTransitionController.addWorkflowTransition';
import { normalizeWorkflowData } from './data/WorkflowVisualizerRepository.js';
import { mapWorkflowVisualizer } from './logic/WorkflowVisualizerMapper.js';
import { validateWorkflowVisualizerStatusName, createWorkflowVisualizerStatus, validateWorkflowVisualizerTransition, processWorkflowVisualizerData, fetchTransitionDetail, activateWorkflowTransition, deleteWorkflowTransition } from './logic/WorkflowVisualizerService.js';

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
    @track transitionData = null;
    @track transitionIsLoading = false;
    @track transitionErrorMessage = '';
    @track transitionSuccessMessage = '';
    @track transitionIsActivating = false;
    @track transitionIsDeleting = false;
    @track clickedStatusIds = [];
    @track workflowModel = null;
    @track newStatusName = '';
    @track isCreatingStatus = false;
    @track createStatusErrorMessage = '';
    @track newTransitionName = '';
    @track isCreatingTransition = false;
    @track createTransitionErrorMessage = '';
    
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

    get createStatusButtonLabel() {
        return this.isCreatingStatus ? 'Creating...' : 'Create Status';
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

        // Normalize data in repository
        const normalized = normalizeWorkflowData(this.workflowData);

        // Process (map, gather statuses, ensure completeness) in service logic
        const { workflowModel, sortedStatuses, allTransitions } = processWorkflowVisualizerData(normalized);

        // Store for use in component
        this.workflowModel = workflowModel;
        this.sortedStatuses = sortedStatuses;
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

        // Set state to show transition detail and load details
        this.selectedTransitionId = lineId;
        this.showTransitionDetail = true;
        this.loadTransitionDetail();
    }

    /**
     * Load transition details via service/repository
     */
    async loadTransitionDetail() {
        if (!this.selectedTransitionId) return;
        this.transitionIsLoading = true;
        this.transitionErrorMessage = '';

        try {
            const res = await fetchTransitionDetail(this.selectedTransitionId);
            if (res && res.success && res.data) {
                this.transitionData = res.data;
            } else if (res && res.data) {
                this.transitionData = res.data;
            } else {
                this.transitionErrorMessage = res.message || 'Failed to load transition';
            }
        } catch (err) {
            this.transitionErrorMessage = 'Error loading transition: ' + (err?.body?.message || err?.message);
            console.error('Error loading transition:', err);
        } finally {
            this.transitionIsLoading = false;
        }
    }

    /**
     * Activate workflow transition
     */
    async handleActivateTransition() {
        if (!this.transitionData || !this.transitionData.id) {
            this.transitionErrorMessage = 'Cannot activate: Transition data not loaded';
            return;
        }

        this.transitionIsActivating = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        try {
            const result = await activateWorkflowTransition(this.transitionData);
            if (result && result.success) {
                this.transitionSuccessMessage = 'Transition activated successfully!';
                // Update local state to show active status
                this.transitionData = { ...this.transitionData, recordStatus: 'active' };

                // Also update the main workflow data transitions list if present
                if (this.workflowData && this.workflowData.workflow && Array.isArray(this.workflowData.workflow.transitions)) {
                    this.workflowData = {
                        ...this.workflowData,
                        workflow: {
                            ...this.workflowData.workflow,
                            transitions: this.workflowData.workflow.transitions.map(t => t.id === this.transitionData.id ? { ...t, recordStatus: 'active' } : t)
                        }
                    };
                    this.processWorkflowData();
                }

                setTimeout(() => {
                    this.transitionSuccessMessage = '';
                }, 3000);
            } else {
                this.transitionErrorMessage = result?.message || 'Failed to activate transition';
            }
        } catch (err) {
            this.transitionErrorMessage = 'Error activating transition: ' + (err?.body?.message || err?.message);
            console.error('Error activating transition:', err);
        } finally {
            this.transitionIsActivating = false;
        }
    }

    /**
     * Delete workflow transition
     */
    async handleDeleteTransition() {
        if (!this.transitionData || !this.transitionData.id) {
            this.transitionErrorMessage = 'Cannot delete: Transition data not loaded';
            return;
        }

        if (!confirm(`Are you sure you want to delete the transition "${this.transitionData.name || this.transitionData.Name || ''}"?`)) {
            return;
        }

        this.transitionIsDeleting = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        try {
            const result = await deleteWorkflowTransition(this.transitionData.id);
            if (result && result.success) {
                this.transitionSuccessMessage = 'Transition deleted successfully!';
                // Remove transition from workflow data
                if (this.workflowData && this.workflowData.workflow && Array.isArray(this.workflowData.workflow.transitions)) {
                    this.workflowData = {
                        ...this.workflowData,
                        workflow: {
                            ...this.workflowData.workflow,
                            transitions: this.workflowData.workflow.transitions.filter(transition => transition.id !== this.transitionData.id)
                        }
                    };
                    this.processWorkflowData();
                }

                // Close panel after successful deletion
                setTimeout(() => {
                    this.handleCloseTransitionDetail();
                }, 1500);
            } else {
                this.transitionErrorMessage = result.message || 'Failed to delete transition';
            }
        } catch (err) {
            this.transitionErrorMessage = 'Error deleting transition: ' + (err?.body?.message || err?.message);
            console.error('Error deleting transition:', err);
        } finally {
            this.transitionIsDeleting = false;
        }
    }

    get transitionCanActivate() {
        return this.transitionData && this.transitionData.recordStatus === 'pending';
    }

    get formattedTransitionCreatedDate() {
        if (!this.transitionData || !this.transitionData.createdDate) return '';
        const date = new Date(this.transitionData.createdDate);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    get fromTransitionStatusName() {
        if (!this.transitionData) return '';
        return this.transitionData.fromStatusName || this.transitionData.fromStatus || '';
    }

    get toTransitionStatusName() {
        if (!this.transitionData) return '';
        return this.transitionData.toStatusName || this.transitionData.toStatus || '';
    }

    get transitionRecordStatus() {
        if (!this.transitionData) return '';
        return this.transitionData.recordStatus || '';
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
        this.createTransitionErrorMessage = '';
    }

    /**
     * Handle transition name input change
     */
    handleTransitionNameChange(event) {
        this.newTransitionName = event.target.value;
        this.createTransitionErrorMessage = '';
    }

    /**
     * Submit create transition request
     */
    async handleCreateTransitionSubmit() {
        const validation = validateWorkflowVisualizerTransition({
            fromStatus: this.selectedFromStatus?.id,
            toStatus: this.selectedToStatus?.id
        });
        if (!validation.valid) {
            this.createTransitionErrorMessage = validation.message || 'Invalid transition';
            return;
        }

        if (!this.newTransitionName.trim()) {
            this.createTransitionErrorMessage = 'Transition name is required';
            return;
        }

        const workflowId = this.workflowData.workflow?.id;
        if (!workflowId) {
            this.createTransitionErrorMessage = 'Workflow ID not found';
            return;
        }

        this.isCreatingTransition = true;
        this.createTransitionErrorMessage = '';

        try {
            const result = await addWorkflowTransitionApex({
                workflowId,
                name: this.newTransitionName,
                fromStatusId: this.selectedFromStatus.id,
                toStatusId: this.selectedToStatus.id
            });

            if (result && result.success) {
                // Dispatch event with the created transition
                const transitionData = {
                    id: result.data.Id,
                    name: this.newTransitionName,
                    fromStatus: this.selectedFromStatus.id,
                    toStatus: this.selectedToStatus.id
                };
                this.handleTransitionCreated({ detail: transitionData });
                this.closeCreateTransitionModal();
            } else {
                this.createTransitionErrorMessage = result?.message || 'Failed to create transition';
            }
        } catch (err) {
            console.error('Error creating transition:', err);
            this.createTransitionErrorMessage = err?.body?.message || err?.message || 'An error occurred';
        } finally {
            this.isCreatingTransition = false;
        }
    }

    /**
     * Close create transition modal
     */
    closeCreateTransitionModal() {
        this.showCreateTransitionModal = false;
        this.newTransitionName = '';
        this.createTransitionErrorMessage = '';
        this.isCreatingTransition = false;
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
        this.transitionData = null;
        this.transitionIsLoading = false;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';
        this.transitionIsActivating = false;
        this.transitionIsDeleting = false;
    }
}
