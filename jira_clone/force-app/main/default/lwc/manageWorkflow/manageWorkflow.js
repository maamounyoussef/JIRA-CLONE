import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWorkflow              from '@salesforce/apex/ManageWorkflowPageController.getWorkflow';
import createStatus             from '@salesforce/apex/ManageWorkflowPageController.createStatus';
import addWorkflowTransition    from '@salesforce/apex/ManageWorkflowPageController.addWorkflowTransition';
import activateWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.activateWorkflowTransition';
import deleteWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.deleteWorkflowTransition';
import loadWorkflowsByProject   from '@salesforce/apex/ManageWorkflowPageController.loadWorkflowsByProject';
import createWorkflow           from '@salesforce/apex/ManageWorkflowPageController.createWorkflow';
import updateFullWorkflowTransition from '@salesforce/apex/ManageWorkflowPageController.updateFullWorkflowTransition';
import addValidateField          from '@salesforce/apex/ManageWorkflowPageController.addValidateField';
import loadValidateFields        from '@salesforce/apex/ManageWorkflowPageController.loadValidateFields';

import {
    validateStatusName,
    validateTransition,
    validateTransitionName,
    validateValidationType,
    validateTicketField,
    validateTransitionId
} from './workflowValidator';
import {
    VISUALIZATION_CONFIG,
    getResponsiveConfig,
    gatherSortedStatuses,
    calculatePositions,
    calculateTransitionLines,
    getSvgViewBox,
    getStatusesWithSVGData,
    getMarkerArrow,
    toggleClick,
    clearClicks
} from './workflowUtils';

// Option lists for the "Add validation rule" combo boxes. These mirror the
// ValidateField__c restricted picklists (FieldName__c / Type__c); label === value
// so the combo emits the exact picklist API value the Apex insert expects.
const VALIDATION_FIELD_OPTIONS = [
    'AssignedTo__c', 'CurrentState__c', 'Creator__c', 'Description__c',
    'EndDate__c', 'Epic__c', 'Priority__c', 'Score__c', 'Sprint__c',
    'StartDate__c', 'StoryPoint__c', 'Summary__c', 'Ticket_Type__c'
].map(v => ({ label: v, value: v }));

const VALIDATION_TYPE_OPTIONS = [
    { label: "Isn't Empty", value: "Isn't Empty" }
];

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
    get workflowListHasError() { return !!this._workflowsErrorMessage; }
    get workflowListShouldShowContent() { return !this._workflowsLoading && !this.workflowListHasError; }

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
                const errorMsg = err?.body?.message || err?.message || 'Failed to load workflows';
                this._workflowsErrorMessage = errorMsg;
                this._workflows = [];
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: errorMsg, variant: 'error' }));
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
            const errorMsg = 'Workflow ID not found';
            this.errorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        updateFullWorkflowTransition({ workflowId: this._workflowId })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to update workflow');
                }
                this._toast('Success', res.message || 'Workflow updated successfully', 'success');
                this._activatePendingTransitions();
                this.handleBackToWorkflowList();
            })
            .catch(err => {
                const errorMsg = err?.body?.message || err?.message || 'Failed to update workflow';
                this.errorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
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
            const errorMsg = 'Workflow name is required';
            this.createWorkflowErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }
        if (!this._projectId) {
            const errorMsg = 'Project ID not found. Please select a project first.';
            this.createWorkflowErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }

        this.isCreatingWorkflow = true;
        this.createWorkflowErrorMessage = '';

        createWorkflow({ name, projectId: this._projectId })
            .then(res => {
                if (!res || !res.success || !res.data) {
                    throw new Error(res?.message || 'Failed to create workflow');
                }
                this._toast('Success', 'Workflow created successfully', 'success');
                const newId = res.data.Id;
                this.showCreateWorkflowModal = false;
                this.newWorkflowName = '';
                this._enterWorkflowEditor(newId);
            })
            .catch(err => {
                const errorMsg = err?.body?.message || err?.message || 'Failed to create workflow';
                this.createWorkflowErrorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
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
                const errorMsg = err?.body?.message || err?.message || 'Failed to load workflow';
                this.errorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
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
    // The validateFields owned by a transition live ON that transition inside the
    // denormalized state — set when its detail loads, appended when one is created.
    _setTransitionValidateFields(id, validateFields) {
        this._writeTransitions(this._transitions.map(t =>
            this._matchesId(t, id) ? { ...t, validateFields } : t
        ));
    }
    _addTransitionValidateField(id, validateField) {
        this._writeTransitions(this._transitions.map(t =>
            this._matchesId(t, id)
                ? { ...t, validateFields: [...(t.validateFields || []), validateField] }
                : t
        ));
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
        if (error) {
            this.createStatusErrorMessage = error;
            this._toast('Error', error, 'error');
            return;
        }

        if (!this._projectId) {
            const errorMsg = 'Project ID not found. Please select a project first.';
            this.createStatusErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }

        this.isCreatingStatus = true;
        this.createStatusErrorMessage = '';

        createStatus({ name: this.newStatusName, projectId: this._projectId })
            .then(res => {
                if (!res.success || !res.data) {
                    throw new Error(res.message || 'Failed to create status');
                }
                this._toast('Success', 'Status created successfully', 'success');
                this._addStatus({ id: res.data.Id, name: res.data.Name });
                this.clickedStatusIds = clearClicks();
                this.showCreateModal = false;
            })
            .catch(err => {
                const errorMsg = err?.body?.message || err?.message || 'Failed to create status';
                this.createStatusErrorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
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
        if (transitionError) {
            this.createTransitionErrorMessage = transitionError;
            this._toast('Error', transitionError, 'error');
            return;
        }

        const nameError = validateTransitionName(this.newTransitionName);
        if (nameError) {
            this.createTransitionErrorMessage = nameError;
            this._toast('Error', nameError, 'error');
            return;
        }

        if (!this._workflowId) {
            const errorMsg = 'Workflow ID not found';
            this.createTransitionErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
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
                this._toast('Success', 'Transition created successfully', 'success');
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
                const errorMsg = err?.body?.message || err?.message || 'Failed to create transition';
                this.createTransitionErrorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
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
    @track selectedTransitionId     = null;
    @track transitionIsLoading      = false;
    @track transitionErrorMessage   = '';
    @track transitionSuccessMessage = '';
    @track transitionIsActivating   = false;
    @track transitionIsDeleting     = false;

    // Add-validation-rule modal (create a ValidateField__c for the open transition)
    @track showValidationRuleModal   = false;
    @track validationFieldName        = '';
    @track validationType             = '';
    @track isCreatingValidationRule   = false;

    // Expand-to-show-validation-details state. `selectedTransitionId` is the
    // principal UI selection; this flag is the only presentation state the panel
    // needs — the rules themselves live on the transition in principal state.
    @track _isValidationDetailExpanded = false;

    // Wire gate: the validation-rule wire only provisions once a transition's
    // panel is expanded (lazy load). Set to the selected transition id on expand;
    // changing it re-runs the wire below.
    @track _wiredTransitionId = null;
    // The provisioned wire result, retained so refreshApex() can bust the
    // Lightning Data Service cache and re-pull server-truth after a rule is added.
    _wiredValidateFields;

    // ─── LOAD (cached @wire) ───────────────────────────────────────────────
    // Validation rules load through a cacheable @wire keyed by the expanded
    // transition. The Lightning Data Service caches the list per transition, so
    // re-expanding the same transition is instant. Freshness after an add is
    // handled by refreshApex() in handleCreateValidationRuleSubmit, which busts
    // that cache and re-provisions this wire. Results are folded INTO the owning
    // transition in the denormalized state — no parallel copy.
    @wire(loadValidateFields, { transitionId: '$_wiredTransitionId' })
    wiredValidateFields(result) {
        // Retain the provisioned value so refreshApex() can target it after an add.
        this._wiredValidateFields = result;
        // Ignore the initial provision before any panel is expanded (null param
        // would otherwise surface the controller's "transitionId is required").
        if (!this._wiredTransitionId) return;

        const { data, error } = result;
        if (data) {
            if (data.success) {
                const fields = (data.data || []).map(vf => this._mapValidateField(vf));
                this._setTransitionValidateFields(this._wiredTransitionId, fields);
            } else {
                this._toast('Error', data.message || 'Failed to load validation details', 'error');
            }
        } else if (error) {
            this._toast('Error', 'Failed to load validation details', 'error');
        }
    }

    _mapValidateField(vf) {
        return {
            id: vf.Id,
            fieldName: vf.FieldName__c,
            type: vf.Type__c,
            errorMessage: vf.ErrorMessage__c,
            _key: vf.Id
        };
    }

    // ─── GETTERS ───────────────────────────────────────────────────────────
    get validationFieldOptions() { return VALIDATION_FIELD_OPTIONS; }
    get validationTypeOptions()  { return VALIDATION_TYPE_OPTIONS; }

    get isValidationDetailExpanded() { return this._isValidationDetailExpanded; }
    get validationFields()           { return this.activeTransition?.validateFields || []; }
    get hasValidationFields()        { return (this.activeTransition?.validateFields?.length || 0) > 0; }
    get expandValidationLabel() {
        return this._isValidationDetailExpanded ? 'Hide Validation Details' : 'Show Validation Details';
    }
    get validationToggleIcon() {
        return this._isValidationDetailExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    // The detail panel is shown whenever a transition is selected — derived from
    // the principal state, never tracked in parallel: null id → hidden, else shown.
    get showTransitionDetail() {
        return this.selectedTransitionId != null;
    }

    // The viewed transition is derived from principal state, not stored twice:
    // `selectedTransitionId` is the only state, and the row is FOUND in
    // `_transitions` — which already carries every attribute loaded by getWorkflow
    // (plus its validateFields). No separate per-transition fetch.
    get activeTransition() {
        if (!this.selectedTransitionId) return null;
        return this._transitions.find(t => this._matchesId(t, this.selectedTransitionId)) || null;
    }

    get transitionCanActivate() {
        return this.activeTransition?.recordStatus === 'pending';
    }

    get formattedTransitionCreatedDate() {
        const createdDate = this.activeTransition?.createdDate;
        if (!createdDate) return '';
        const date = new Date(createdDate);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    get fromTransitionStatusName() {
        const t = this.activeTransition;
        return t ? (t.fromStatusName || t.fromStatus || '') : '';
    }

    get toTransitionStatusName() {
        const t = this.activeTransition;
        return t ? (t.toStatusName || t.toStatus || '') : '';
    }

    get transitionRecordStatus() {
        return this.activeTransition?.recordStatus || '';
    }

    // ─── EVENT HANDLERS ────────────────────────────────────────────────────
    handleTransitionClick(event) {
        const lineId = event.currentTarget.dataset.lineId;
        this.selectedTransitionId = lineId;
        // The detail is already in the denormalized state — `activeTransition`
        // finds it by id. Just collapse any panel left open on the previously
        // viewed transition so its rules aren't shown; expanding reloads them.
        this._collapseValidationDetail();
    }

    // ─── VALIDATION DETAIL (expand to load) ────────────────────────────────
    handleToggleValidationDetail() {
        // Collapsing needs no load.
        if (this._isValidationDetailExpanded) {
            this._collapseValidationDetail();
            return;
        }
        // Expanding: gate the load behind the transition-id validation. No pass,
        // no load.
        const error = validateTransitionId(this.selectedTransitionId);
        if (error) { this._toast('Validation', error, 'error'); return; }

        this._expandValidationDetail();
    }

    // Reveal the validation detail for the selected transition: flip the
    // presentation flag and point the wire at this transition. Provisioning the
    // wire loads the rules into principal state (served from the LDS cache on a
    // repeat expand). Called on manual expand and after a rule is added.
    _expandValidationDetail() {
        this._isValidationDetailExpanded = true;
        this._wiredTransitionId = this.selectedTransitionId;
    }

    _collapseValidationDetail() {
        this._isValidationDetailExpanded = false;
        // Leave _wiredTransitionId pointing at this transition so its wire result
        // stays provisioned for refreshApex(). The loaded validateFields remain on
        // the transition in principal state; a repeat expand re-shows them from
        // cache. (Display derives from principal state, so a collapsed panel that
        // is out of sync with _wiredTransitionId is never visible.)
    }

    handleActivateTransition() {
        const transition = this.activeTransition;
        if (!transition || !transition.id) {
            const errorMsg = 'Cannot activate: Transition data not loaded';
            this.transitionErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }

        this.transitionIsActivating = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        activateWorkflowTransition({ workflowTransitionId: transition.id })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to activate transition');
                }
                this._toast('Success', 'Transition activated successfully', 'success');
                this.transitionSuccessMessage = 'Transition activated successfully!';
                this._setTransitionRecordStatus(transition.id, 'active');
                this.handleCloseTransitionDetail();
            })
            .catch(err => {
                const errorMsg = err?.body?.message || err?.message || 'Failed to activate transition';
                this.transitionErrorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
            })
            .finally(() => { this.transitionIsActivating = false; });
    }

    handleDeleteTransition() {
        const transition = this.activeTransition;
        if (!transition || !transition.id) {
            const errorMsg = 'Cannot delete: Transition data not loaded';
            this.transitionErrorMessage = errorMsg;
            this._toast('Error', errorMsg, 'error');
            return;
        }

        // eslint-disable-next-line no-alert
        if (!confirm(`Are you sure you want to delete the transition "${transition.name || ''}"?`)) {
            return;
        }

        this.transitionIsDeleting = true;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';

        deleteWorkflowTransition({ workflowTransitionId: transition.id })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to delete transition');
                }
                this._toast('Success', 'Transition deleted successfully', 'success');
                this.transitionSuccessMessage = 'Transition deleted successfully!';
                this._removeTransition(transition.id);
                this.handleCloseTransitionDetail();
            })
            .catch(err => {
                const errorMsg = err?.body?.message || err?.message || 'Failed to delete transition';
                this.transitionErrorMessage = errorMsg;
                this._toast('Error', errorMsg, 'error');
            })
            .finally(() => { this.transitionIsDeleting = false; });
    }

    handleCloseTransitionDetail() {
        this.selectedTransitionId = null;
        this.transitionIsLoading = false;
        this.transitionErrorMessage = '';
        this.transitionSuccessMessage = '';
        this.transitionIsActivating = false;
        this.transitionIsDeleting = false;
        this._collapseValidationDetail();
        this.closeValidationRuleModal();
    }

    // ─── ADD VALIDATION RULE ───────────────────────────────────────────────
    openValidationRuleModal() {
        this.showValidationRuleModal = true;
        this.validationFieldName = '';
        this.validationType = '';
    }

    closeValidationRuleModal() {
        this.showValidationRuleModal = false;
        this.validationFieldName = '';
        this.validationType = '';
        this.isCreatingValidationRule = false;
    }

    handleValidationFieldChange(event) {
        this.validationFieldName = event.detail.value;
    }

    handleValidationTypeChange(event) {
        this.validationType = event.detail.value;
    }

    handleCreateValidationRuleSubmit() {
        const fieldError = validateTicketField(this.validationFieldName);
        if (fieldError) { this._toast('Validation', fieldError, 'error'); return; }

        const typeError = validateValidationType(this.validationType);
        if (typeError) { this._toast('Validation', typeError, 'error'); return; }

        this.isCreatingValidationRule = true;
        const transitionId = this.activeTransition?.id;

        addValidateField({workflowTransitionId: transitionId ,fieldName: this.validationFieldName, type: this.validationType })
            .then(res => {
                if (!res || !res.success) {
                    throw new Error(res?.message || 'Failed to create validation rule');
                }
                // Fold the created record (from the backend response) onto the
                // owning transition in the denormalized state for instant feedback.
                if (res.data) {
                    this._addTransitionValidateField(transitionId, this._mapValidateField(res.data));
                }
                // Reveal the detail so the show/hide panel derives the new rule
                // from principal state, then reconcile with server-truth: a prior
                // expand may have cached this transition's list (without the new
                // rule), so refreshApex busts that LDS cache and re-provisions the
                // wire, whose callback overwrites the list with the server's.
                this._expandValidationDetail();
                this._toast('Success', 'Validation rule created successfully', 'success');
                this.closeValidationRuleModal();
                if (this._wiredValidateFields) {
                    return refreshApex(this._wiredValidateFields);
                }
                return null;
            })
            .catch(err => {
                this._toast('Error', err?.body?.message || err?.message || 'An error occurred', 'error');
            })
            .finally(() => { this.isCreatingValidationRule = false; });
    }

    // ─── HELPERS ───────────────────────────────────────────────────────────
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
