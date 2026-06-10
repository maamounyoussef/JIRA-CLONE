import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWorkflow              from '@salesforce/apex/ManageWorkflowPageController.getWorkflow';
import createStatus             from '@salesforce/apex/ManageWorkflowPageController.createStatus';
import addWorkflowTransition    from '@salesforce/apex/ManageWorkflowPageController.addWorkflowTransition';
import getWorkflowTransitionById from '@salesforce/apex/ManageWorkflowPageController.getWorkflowTransitionById';
import activateWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.activateWorkflowTransition';
import deleteWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.deleteWorkflowTransition';
import loadWorkflowsByProject   from '@salesforce/apex/ManageWorkflowPageController.loadWorkflowsByProject';
import createWorkflow           from '@salesforce/apex/ManageWorkflowPageController.createWorkflow';
import updateFullWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.updateFullWorkflowTransition';
import addValidationRule          from '@salesforce/apex/ManageWorkflowPageController.addValidationRule';

import {
    validateStatusName,
    validateTransition,
    validateTransitionName,
    validateValidationType,
    validateTicketField
} from './workflowValidator';
import {
    VISUALIZATION_CONFIG,
    getResponsiveConfig,
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
    @track _workflowId   = null;
    isLoading            = false;
    errorMessage         = '';

    // Workflow list step (project chosen, no workflow chosen yet)
    @track _workflows               = [];
    @track _workflowsLoading        = false;
    @track _workflowsErrorMessage   = '';

    // Create-workflow modal state
    @track showCreateWorkflowModal       = false;
    @track newWorkflowName               = '';
    @track isCreatingWorkflow            = false;
    @track createWorkflowErrorMessage    = '';

    /*
     * Principal de-normalized state — single source of truth for the active
     * workflow editor. Inherent fields plus the related objects (statuses and
     * transitions) all live here. Anything reachable from this shape is exposed
     * as a derived getter; nothing about the editor is stored twice.
     *
     * Shape (from getWorkflow / WorkflowConfigDTO):
     * {
     *   id,
     *   projectStatus: [ { id, name } ],
     *   workflow: { id, name, transitions: [ { id, name, fromStatus, toStatus, recordStatus } ] }
     * }
     */
    @track workflowData = null;

    // Responsive SVG config — reassigned (immutable) by the ResizeObserver below.
    @track config       = VISUALIZATION_CONFIG;
    _resizeObserver     = null;
    _lastMeasuredWidth  = 0;

    // ─── LIFECYCLE ─────────────────────────────────────────────────────────
    connectedCallback() {
        // Three-step entry:
        //   1. No projectId  → chooseProject child is rendered.
        //   2. projectId set → workflow list for that project.
        //   3. workflowId selected (edit existing OR create new) → visualizer.
        this._projectId = localStorage.getItem('projectId');

        if (!this._projectId) {
            return;
        }
        this._loadWorkflowsForProject();
    }

    // ─── PROJECT SELECTION ─────────────────────────────────────────────────
    get hasProject()  { return !!this._projectId; }
    get hasWorkflow() { return !!this._workflowId; }
    get showWorkflowList() { return this.hasProject && !this.hasWorkflow; }
    get hasWorkflows() { return Array.isArray(this._workflows) && this._workflows.length > 0; }

    handleProjectChosen(event) {
        this._projectId = event.detail?.projectId || localStorage.getItem('projectId');
        if (this._projectId) {
            this._loadWorkflowsForProject();
        }
    }

    // ─── WORKFLOW LIST ─────────────────────────────────────────────────────
    _loadWorkflowsForProject() {
        if (!this._projectId) return;
        this._workflowsLoading = true;
        this._workflowsErrorMessage = '';
        loadWorkflowsByProject({ projectId: this._projectId })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to load workflows');
                }
                this._workflows = (res.data || []).map(w => ({
                    id: w.Id,
                    name: w.Name,
                    recordStatus: w.RecordStatus__c,
                    createdDate: w.CreatedDate,
                    lastModifiedDate: w.LastModifiedDate
                }));
            })
            .catch(err => {
                this._workflowsErrorMessage = 'Error loading workflows: ' + (err?.body?.message || err?.message || err);
                this._workflows = [];
            })
            .finally(() => { this._workflowsLoading = false; });
    }

    handleEditWorkflow(event) {
        const workflowId = event.currentTarget.dataset.workflowId;
        if (!workflowId) return;
        this._enterWorkflowEditor(workflowId);
    }

    _enterWorkflowEditor(workflowId) {
        this._workflowId = workflowId;
        localStorage.setItem('workflowId', workflowId);
        this._loadWorkflow();
    }

    handleBackToWorkflowList() {
        this._workflowId = null;
        localStorage.removeItem('workflowId');
        this.workflowData = null;
        this.errorMessage = '';
        this.handleCloseTransitionDetail();
        // The visualizer container is about to unmount. Drop the ResizeObserver
        // bound to the old DOM node and reset responsive state so the next entry
        // re-measures the freshly-mounted container instead of inheriting stale
        // dimensions (which caused the SVG viewBox to mis-match the new width).
        this._teardownResizeObserver();
        this._loadWorkflowsForProject();
    }

    _teardownResizeObserver() {
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        this._lastMeasuredWidth = 0;
        this.config = VISUALIZATION_CONFIG;
    }

    handleUpdateWorkflow() {
        // eslint-disable-next-line no-console
        console.log('Current workflow id:', this._workflowId);

        if (!this._workflowId) {
            this.errorMessage = 'Workflow ID not found';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        updateFullWorkflowTransition({ workflowId: this._workflowId })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to update workflow');
                }
                this._activatePendingTransitions();
                this.handleBackToWorkflowList();
            })
            .catch(err => {
                this.errorMessage = 'Error updating workflow: ' + (err?.body?.message || err?.message || err);
            })
            .finally(() => { this.isLoading = false; });
    }

    // ─── CREATE WORKFLOW MODAL ─────────────────────────────────────────────
    openCreateWorkflowModal() {
        this.showCreateWorkflowModal = true;
        this.newWorkflowName = '';
        this.createWorkflowErrorMessage = '';
    }

    closeCreateWorkflowModal() {
        this.showCreateWorkflowModal = false;
        this.newWorkflowName = '';
        this.createWorkflowErrorMessage = '';
        this.isCreatingWorkflow = false;
    }

    handleNewWorkflowNameChange(event) {
        this.newWorkflowName = event.detail.value;
        this.createWorkflowErrorMessage = '';
    }

    handleCreateWorkflowSubmit() {
        const name = (this.newWorkflowName || '').trim();
        if (!name) {
            this.createWorkflowErrorMessage = 'Workflow name is required';
            return;
        }
        if (!this._projectId) {
            this.createWorkflowErrorMessage = 'Project ID not found. Please select a project first.';
            return;
        }

        this.isCreatingWorkflow = true;
        this.createWorkflowErrorMessage = '';

        createWorkflow({ name, projectId: this._projectId })
            .then(res => {
                if (!res || !res.success || !res.data) {
                    throw new Error(res?.message || 'Failed to create workflow');
                }
                const newId = res.data.Id;
                this.showCreateWorkflowModal = false;
                this.newWorkflowName = '';
                this._enterWorkflowEditor(newId);
            })
            .catch(err => {
                this.createWorkflowErrorMessage = err?.body?.message || err?.message || 'An error occurred while creating the workflow';
            })
            .finally(() => { this.isCreatingWorkflow = false; });
    }

    renderedCallback() {
        if (!this._resizeObserver) {
            const container = this.template.querySelector('.workflow-visualizer-container');
            if (container) {
                this._resizeObserver = new ResizeObserver(entries => {
                    for (const entry of entries) {
                        const width = entry.contentRect.width;
                        // Only recalculate if width changed meaningfully (> 20px).
                        // Reassigning `this.config` re-runs the derived geometry getters.
                        if (Math.abs(width - this._lastMeasuredWidth) > 20) {
                            this._lastMeasuredWidth = width;
                            this.config = getResponsiveConfig(width);
                        }
                    }
                });
                this._resizeObserver.observe(container);
            }
        }
    }

    disconnectedCallback() {
        this._teardownResizeObserver();
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
            })
            .catch(err => {
                this.errorMessage = 'Error loading workflow: ' + (err?.body?.message || err?.message || err);
            })
            .finally(() => { this.isLoading = false; });
    }

    // ─── PRINCIPAL-STATE CRUD ──────────────────────────────────────────────
    // The workflow lives in `workflowData`. Everything else in the editor
    // reads it through these accessors / writes it through these mutators —
    // no inline `workflowData.workflow.transitions` access anywhere else.
    get _statuses()    { return this.workflowData?.projectStatus || []; }
    get _transitions() { return this.workflowData?.workflow?.transitions || []; }

    _addStatus(status) {
        if (!this.workflowData) return;
        this.workflowData = { ...this.workflowData, projectStatus: [...this._statuses, status] };
    }
    _addPendingTransition({ id, name, fromStatus, toStatus }) {
        this._writeTransitions([
            ...this._transitions,
            { id, name, fromStatus, toStatus, recordStatus: 'pending' }
        ]);
    }
    _setTransitionRecordStatus(id, recordStatus) {
        this._writeTransitions(this._transitions.map(t =>
            this._matchesId(t, id) ? { ...t, recordStatus } : t
        ));
    }
    _activatePendingTransitions() {
        this._writeTransitions(this._transitions.map(t =>
            t.recordStatus === 'pending' ? { ...t, recordStatus: 'active' } : t
        ));
    }
    _removeTransition(id) {
        this._writeTransitions(this._transitions.filter(t => !this._matchesId(t, id)));
    }
    _writeTransitions(transitions) {
        if (!this.workflowData) return;
        this.workflowData = {
            ...this.workflowData,
            workflow: { ...this.workflowData.workflow, transitions }
        };
    }

    // ─── DERIVED GEOMETRY ──────────────────────────────────────────────────
    // Pure projections of `workflowData` + `config`. No stored copies; the
    // template re-reads them on each render.
    get sortedStatuses() {
        return this.workflowData
            ? gatherSortedStatuses({ projectStatus: this._statuses, workflow: { transitions: this._transitions } })
            : [];
    }
    get statusPositions()        { return calculatePositions(this.sortedStatuses, this.config); }
    get activeTransitionLines()  { return this.findActiveTransitionLines(); }
    get pendingTransitionLines() { return this.findPendingTransitionLines(); }

    findActiveTransitionLines() {
        const transitions = this._transitions.filter(t => t.recordStatus === 'active');
        return calculateTransitionLines({ workflow: { transitions } }, this.statusPositions, this.config);
    }
    findPendingTransitionLines() {
        const transitions = this._transitions.filter(t => t.recordStatus === 'pending');
        return calculateTransitionLines({ workflow: { transitions } }, this.statusPositions, this.config);
    }

    // ─── GETTERS ───────────────────────────────────────────────────────────
    get hasStatuses()      { return this.sortedStatuses.length > 0; }
    get startPointRadius() { return this.config.startPointRadius || 5; }
    get endPointRadius()   { return this.config.endPointRadius || 5; }
    get rectRadius()       { return this.config.rectRadius || 10; }
    get svgViewBox()       { return getSvgViewBox(this.sortedStatuses, this.config); }
    get markerArrow()      { return getMarkerArrow(); }
    get statusesWithSVGData() {
        return getStatusesWithSVGData(this.sortedStatuses, this.statusPositions, this.config, this.clickedStatusIds);
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
        this.newStatusName = event.detail.value;
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
                this._addStatus({ id: res.data.Id, name: res.data.Name });
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
        this.newTransitionName = event.detail.value;
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
                this._addPendingTransition({
                    id: res.data.Id,
                    name: this.newTransitionName,
                    fromStatus: this.selectedFromStatus.id,
                    toStatus: this.selectedToStatus.id
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
                    const local = this._transitions.find(t => this._matchesId(t, this.selectedTransitionId));
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
                this._setTransitionRecordStatus(this.transitionData.id, 'active');
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
                this._removeTransition(this.transitionData.id);
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
        this.closeValidationRuleModal();
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                  VALIDATION RULE SECTION                                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PRESENTATION STATE ────────────────────────────────────────────────
    @track showValidationRuleModal   = false;
    @track newValidationType         = '';
    @track newValidationTicketField  = '';
    @track isCreatingValidationRule  = false;

    // ─── GETTERS ───────────────────────────────────────────────────────────
    // Type__c is a picklist on ValidationRule__c; its allowed values come from
    // the object schema (object_validation_lwc_apex.md → "Type__c picklist
    // values").
    get validationTypeOptions() {
        return [{ label: 'Not Equals', value: 'Not Equals' }];
    }

    // ─── EVENT HANDLERS ────────────────────────────────────────────────────
    openValidationRuleModal() {
        this.showValidationRuleModal = true;
        this.newValidationType = '';
        this.newValidationTicketField = '';
        this.isCreatingValidationRule = false;
    }

    handleValidationTypeChange(event) {
        this.newValidationType = event.detail.value;
    }

    handleValidationTicketFieldChange(event) {
        this.newValidationTicketField = event.detail.value;
    }

    handleCreateValidationRuleSubmit() {
        const typeError = validateValidationType(this.newValidationType);
        if (typeError) { this._toast('Error', typeError, 'error'); return; }

        const fieldError = validateTicketField(this.newValidationTicketField);
        if (fieldError) { this._toast('Error', fieldError, 'error'); return; }

        if (!this.transitionData || !this.transitionData.id) {
            this._toast('Error', 'Cannot add validation rule: transition not loaded', 'error');
            return;
        }

        this.isCreatingValidationRule = true;

        addValidationRule({
            workflowTransitionId: this.transitionData.id,
            ticketField: this.newValidationTicketField,
            validationType: this.newValidationType
        })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to create validation rule');
                }
                this._toast('Success', 'Validation rule created successfully', 'success');
                this.closeValidationRuleModal();
            })
            .catch(err => {
                // Failure: surface the error but keep the modal open so the user
                // can correct and retry without re-entering the fields.
                this._toast('Error', err?.body?.message || err?.message || 'An error occurred while creating the validation rule', 'error');
            })
            .finally(() => { this.isCreatingValidationRule = false; });
    }

    closeValidationRuleModal() {
        this.showValidationRuleModal = false;
        this.newValidationType = '';
        this.newValidationTicketField = '';
        this.isCreatingValidationRule = false;
    }

    // ─── HELPERS ───────────────────────────────────────────────────────────
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
