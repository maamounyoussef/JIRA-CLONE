import { LightningElement, track } from 'lwc';
import getWorkflow              from '@salesforce/apex/ManageWorkflowPageController.getWorkflow';
import createStatus             from '@salesforce/apex/ManageWorkflowPageController.createStatus';
import addWorkflowTransition    from '@salesforce/apex/ManageWorkflowPageController.addWorkflowTransition';
import getWorkflowTransitionById from '@salesforce/apex/ManageWorkflowPageController.getWorkflowTransitionById';
import activateWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.activateWorkflowTransition';
import deleteWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.deleteWorkflowTransition';

const DEFAULT_WORKFLOW_ID = 'a01d200001g7lT3AAI';

import { validateStatusName, validateTransition, validateTransitionName } from './workflowValidator';
import {
    VISUALIZATION_CONFIG,
    getResponsiveConfig,
    normalizeWorkflowData,
    gatherSortedStatuses,
    transitionFromApex,
    calculatePositions,
    calculateTransitionLines,
    getSvgViewBox,
    getStatusesWithSVGData,
    getMarkerArrow,
    toggleClick,
    clearClicks
} from './workflowUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export default class ManageWorkflow extends LightningElement {

    // ─── PROPERTIES & STATE ────────────────────────────────────────────────
    @track _projectId    = null;
    _workflowId          = null;
    isLoading            = false;
    errorMessage         = '';

    /*
     * Principal de-normalized state. Shape (from getWorkflow / WorkflowConfigDTO):
     * {
     *   id,
     *   projectStatus: [ { id, name } ],
     *   workflow: { id, name, transitions: [ { id, name, fromStatus, toStatus, recordStatus } ] }
     * }
     */
    @track workflowData = null;

    // Computed presentation geometry (recomputed by processWorkflowData()).
    @track sortedStatuses         = [];
    @track statusPositions        = {};
    @track activeTransitionLines  = [];
    @track pendingTransitionLines = [];

    // Responsive SVG config.
    config = VISUALIZATION_CONFIG;
    _resizeObserver    = null;
    _lastMeasuredWidth = 0;

    // ─── LIFECYCLE ─────────────────────────────────────────────────────────
    connectedCallback() {
        // Entry: workflowId is the primary identifier (falls back to a static
        // default if not provided). projectId is still read from localStorage
        // for the createStatus flow. If no projectId is set the chooseProject
        // child is rendered instead of the workflow visualizer.
        this._workflowId = localStorage.getItem('workflowId') || DEFAULT_WORKFLOW_ID;
        this._projectId  = localStorage.getItem('projectId');

        if (!this._projectId) {
            return;
        }
        if (!this._workflowId) {
            this.errorMessage = 'No workflow selected. Please select one first.';
            return;
        }
        this._loadWorkflow();
    }

    // ─── PROJECT SELECTION ─────────────────────────────────────────────────
    get hasProject() { return !!this._projectId; }

    handleProjectChosen(event) {
        this._projectId = event.detail?.projectId || localStorage.getItem('projectId');
        if (this._projectId && this._workflowId) {
            this._loadWorkflow();
        }
    }

    renderedCallback() {
        if (!this._resizeObserver) {
            const container = this.template.querySelector('.workflow-visualizer-container');
            if (container) {
                this._resizeObserver = new ResizeObserver(entries => {
                    for (const entry of entries) {
                        const width = entry.contentRect.width;
                        // Only recalculate if width changed meaningfully (> 20px).
                        if (Math.abs(width - this._lastMeasuredWidth) > 20) {
                            this._lastMeasuredWidth = width;
                            this.config = getResponsiveConfig(width);
                            this.processWorkflowData();
                        }
                    }
                });
                this._resizeObserver.observe(container);
            }
        }
    }

    disconnectedCallback() {
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
    }

    // ─── APEX CALLS ────────────────────────────────────────────────────────
    _loadWorkflow() {
        this.isLoading = true;
        this.errorMessage = '';
        getWorkflow({ workflowId: this._workflowId })
            .then(res => {
                if (!res || !res.success || !res.data) {
                    throw new Error(res?.message || 'Failed to load workflow');
                }
                this.workflowData = res.data;
                this.processWorkflowData();
            })
            .catch(err => {
                this.errorMessage = 'Error loading workflow: ' + (err?.body?.message || err?.message || err);
            })
            .finally(() => { this.isLoading = false; });
    }

    // ─── DERIVED GEOMETRY ──────────────────────────────────────────────────
    /**
     * Recompute the SVG-renderable geometry from the principal state + config.
     * Called on load, after every workflowData mutation, and on resize.
     */
    processWorkflowData() {
        if (!this.workflowData || (!this.workflowData.projectStatus && !this.workflowData.workflow)) {
            this.sortedStatuses = [];
            this.statusPositions = {};
            this.activeTransitionLines = [];
            this.pendingTransitionLines = [];
            return;
        }

        const normalized = normalizeWorkflowData(this.workflowData);
        const allTransitions = normalized.workflow.transitions;

        this.sortedStatuses  = gatherSortedStatuses(normalized);
        this.statusPositions = calculatePositions(this.sortedStatuses, this.config);

        const active  = allTransitions.filter(t => t.recordStatus === 'active');
        const pending = allTransitions.filter(t => t.recordStatus === 'pending');

        this.activeTransitionLines  = calculateTransitionLines({ workflow: { transitions: active } }, this.statusPositions, this.config);
        this.pendingTransitionLines = calculateTransitionLines({ workflow: { transitions: pending } }, this.statusPositions, this.config);
    }

    // ─── GETTERS ───────────────────────────────────────────────────────────
    get hasStatuses()      { return this.sortedStatuses && this.sortedStatuses.length > 0; }
    get startPointRadius() { return this.config.startPointRadius || 5; }
    get endPointRadius()   { return this.config.endPointRadius || 5; }
    get rectRadius()       { return this.config.rectRadius || 10; }
    get svgViewBox()       { return getSvgViewBox(this.sortedStatuses, this.config); }
    get markerArrow()      { return getMarkerArrow(); }
    get statusesWithSVGData() {
        return getStatusesWithSVGData(this.sortedStatuses, this.statusPositions, this.config, this.clickedStatusIds);
    }

    // ─── PRINCIPAL-STATE MUTATORS ──────────────────────────────────────────
    _addStatusToWorkflow(status) {
        if (!this.workflowData) return;
        this.workflowData = {
            ...this.workflowData,
            projectStatus: this.workflowData.projectStatus
                ? [...this.workflowData.projectStatus, status]
                : [status]
        };
        this.processWorkflowData();
    }

    _addTransitionToWorkflow(transition) {
        const existing = this.workflowData?.workflow?.transitions || [];
        this.workflowData = {
            ...this.workflowData,
            workflow: {
                ...this.workflowData.workflow,
                transitions: [...existing, transition]
            }
        };
        this.processWorkflowData();
    }

    _updateTransitionRecordStatus(transitionId, recordStatus) {
        const transitions = this.workflowData?.workflow?.transitions;
        if (!Array.isArray(transitions)) return;
        this.workflowData = {
            ...this.workflowData,
            workflow: {
                ...this.workflowData.workflow,
                transitions: transitions.map(t =>
                    this._matchesId(t, transitionId) ? { ...t, recordStatus } : t
                )
            }
        };
        this.processWorkflowData();
    }

    _removeTransitionFromWorkflow(transitionId) {
        const transitions = this.workflowData?.workflow?.transitions;
        if (!Array.isArray(transitions)) return;
        this.workflowData = {
            ...this.workflowData,
            workflow: {
                ...this.workflowData.workflow,
                transitions: transitions.filter(t => !this._matchesId(t, transitionId))
            }
        };
        this.processWorkflowData();
    }

    _matchesId(t, id) {
        return !!(t && ((t.id && t.id === id) || (t.Id && t.Id === id)));
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          STATUS SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PRESENTATION STATE ────────────────────────────────────────────────
    @track clickedStatusIds   = [];
    @track selectedFromStatus = null;
    @track selectedToStatus   = null;

    @track showCreateModal          = false;
    @track newStatusName            = '';
    @track isCreatingStatus         = false;
    @track createStatusErrorMessage = '';

    get createStatusButtonLabel() {
        return this.isCreatingStatus ? 'Creating...' : 'Create Status';
    }

    // ─── EVENT HANDLERS ────────────────────────────────────────────────────
    handleStatusClick(event) {
        const statusId = event.currentTarget.dataset.statusId;
        const status = this.sortedStatuses.find(s => s.id === statusId);

        if (!this.selectedFromStatus) {
            this.selectedFromStatus = status;
        } else if (this.selectedFromStatus.id === statusId) {
            this.selectedFromStatus = null;
        } else {
            this.selectedToStatus = status;
            this.openCreateTransitionModal();
        }

        this.clickedStatusIds = toggleClick(this.clickedStatusIds, statusId);
    }

    openCreateStatusModal() {
        this.showCreateModal = true;
        this.newStatusName = '';
        this.createStatusErrorMessage = '';
    }

    closeCreateModal() {
        this.showCreateModal = false;
        this.selectedFromStatus = null;
        this.selectedToStatus = null;
    }

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

    handleCreateSubmit() {
        const error = validateStatusName(this.newStatusName);
        if (error) { this.createStatusErrorMessage = error; return; }

        if (!this._projectId) {
            this.createStatusErrorMessage = 'Project ID not found. Please select a project first.';
            return;
        }

        this.isCreatingStatus = true;
        this.createStatusErrorMessage = '';

        createStatus({ name: this.newStatusName, projectId: this._projectId })
            .then(res => {
                if (!res.success || !res.data) {
                    throw new Error(res.message || 'Failed to create status');
                }
                this._addStatusToWorkflow({ id: res.data.Id, name: res.data.Name });
                this.clickedStatusIds = clearClicks();
                this.showCreateModal = false;
            })
            .catch(err => {
                this.createStatusErrorMessage = err?.body?.message || err?.message || 'An error occurred while creating the status';
            })
            .finally(() => { this.isCreatingStatus = false; });
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                       TRANSITION SECTION                                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PRESENTATION STATE ────────────────────────────────────────────────
    @track showCreateTransitionModal    = false;
    @track newTransitionName             = '';
    @track isCreatingTransition          = false;
    @track createTransitionErrorMessage  = '';

    // ─── EVENT HANDLERS ────────────────────────────────────────────────────
    openCreateTransitionModal() {
        this.showCreateTransitionModal = true;
        this.newTransitionName = '';
        this.createTransitionErrorMessage = '';
    }

    handleTransitionNameChange(event) {
        this.newTransitionName = event.target.value;
        this.createTransitionErrorMessage = '';
    }

    handleCreateTransitionSubmit() {
        const transitionError = validateTransition({
            fromStatus: this.selectedFromStatus?.id,
            toStatus: this.selectedToStatus?.id
        });
        if (transitionError) { this.createTransitionErrorMessage = transitionError; return; }

        const nameError = validateTransitionName(this.newTransitionName);
        if (nameError) { this.createTransitionErrorMessage = nameError; return; }

        if (!this._workflowId) {
            this.createTransitionErrorMessage = 'Workflow ID not found';
            return;
        }

        this.isCreatingTransition = true;
        this.createTransitionErrorMessage = '';

        addWorkflowTransition({
            workflowId: this._workflowId,
            name: this.newTransitionName,
            fromStatusId: this.selectedFromStatus.id,
            toStatusId: this.selectedToStatus.id
        })
            .then(res => {
                if (!res.success || !res.data) {
                    throw new Error(res.message || 'Failed to create transition');
                }
                this._addTransitionToWorkflow({
                    id: res.data.Id,
                    name: this.newTransitionName,
                    fromStatus: this.selectedFromStatus.id,
                    toStatus: this.selectedToStatus.id,
                    recordStatus: 'pending'
                });
                this.clickedStatusIds = clearClicks();
                this.closeCreateTransitionModal();
            })
            .catch(err => {
                this.createTransitionErrorMessage = err?.body?.message || err?.message || 'An error occurred';
            })
            .finally(() => { this.isCreatingTransition = false; });
    }

    closeCreateTransitionModal() {
        this.showCreateTransitionModal = false;
        this.selectedFromStatus = null;
        this.newTransitionName = '';
        this.createTransitionErrorMessage = '';
        this.isCreatingTransition = false;
        this.clickedStatusIds = clearClicks();
    }

    stopPropagation(event) {
        event.stopPropagation();
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                    TRANSITION DETAIL SECTION                              ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PRESENTATION STATE ────────────────────────────────────────────────
    @track showTransitionDetail     = false;
    @track selectedTransitionId     = null;
    @track transitionData           = null;
    @track transitionIsLoading      = false;
    @track transitionErrorMessage   = '';
    @track transitionSuccessMessage = '';
    @track transitionIsActivating   = false;
    @track transitionIsDeleting     = false;

    // ─── GETTERS ───────────────────────────────────────────────────────────
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

    // ─── EVENT HANDLERS ────────────────────────────────────────────────────
    handleTransitionClick(event) {
        const lineId = event.currentTarget.dataset.lineId;
        this.selectedTransitionId = lineId;
        this.showTransitionDetail = true;
        this.loadTransitionDetail();
    }

    loadTransitionDetail() {
        if (!this.selectedTransitionId) return;
        this.transitionIsLoading = true;
        this.transitionErrorMessage = '';

        getWorkflowTransitionById({ transitionId: this.selectedTransitionId })
            .then(res => {
                if (res && res.success && res.data) {
                    this.transitionData = transitionFromApex(res.data);
                    // Prefer the locally-known recordStatus (e.g. just activated).
                    const local = this.workflowData?.workflow?.transitions?.find(t => this._matchesId(t, this.selectedTransitionId));
                    const localRecordStatus = local && (local.recordStatus || local.RecordStatus__c || local.RecordStatus);
                    if (localRecordStatus && localRecordStatus !== this.transitionData.recordStatus) {
                        this.transitionData = { ...this.transitionData, recordStatus: localRecordStatus };
                    }
                } else {
                    this.transitionErrorMessage = res?.message || 'Failed to load transition';
                }
            })
            .catch(err => {
                this.transitionErrorMessage = 'Error loading transition: ' + (err?.body?.message || err?.message);
            })
            .finally(() => { this.transitionIsLoading = false; });
    }

    handleActivateTransition() {
        if (!this.transitionData || !this.transitionData.id) {
            this.transitionErrorMessage = 'Cannot activate: Transition data not loaded';
            return;
        }

        this.transitionIsActivating = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        activateWorkflowTransition({ workflowTransitionId: this.transitionData.id })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to activate transition');
                }
                this.transitionSuccessMessage = 'Transition activated successfully!';
                this.transitionData = { ...this.transitionData, recordStatus: 'active' };
                this._updateTransitionRecordStatus(this.transitionData.id, 'active');
                this.handleCloseTransitionDetail();
            })
            .catch(err => {
                this.transitionErrorMessage = 'Error activating transition: ' + (err?.body?.message || err?.message);
            })
            .finally(() => { this.transitionIsActivating = false; });
    }

    handleDeleteTransition() {
        if (!this.transitionData || !this.transitionData.id) {
            this.transitionErrorMessage = 'Cannot delete: Transition data not loaded';
            return;
        }

        // eslint-disable-next-line no-alert
        if (!confirm(`Are you sure you want to delete the transition "${this.transitionData.name || ''}"?`)) {
            return;
        }

        this.transitionIsDeleting = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        deleteWorkflowTransition({ workflowTransitionId: this.transitionData.id })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to delete transition');
                }
                this.transitionSuccessMessage = 'Transition deleted successfully!';
                this._removeTransitionFromWorkflow(this.transitionData.id);
                this.handleCloseTransitionDetail();
            })
            .catch(err => {
                this.transitionErrorMessage = 'Error deleting transition: ' + (err?.body?.message || err?.message);
            })
            .finally(() => { this.transitionIsDeleting = false; });
    }

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
