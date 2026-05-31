import { LightningElement, track } from 'lwc';
import loadTicketTypesByProject from '@salesforce/apex/ManageTicketTypeController.loadTicketTypesByProject';
import loadWorkflowsByProject   from '@salesforce/apex/ManageTicketTypeController.loadWorkflowsByProject';
import createTicketTypeApex     from '@salesforce/apex/ManageTicketTypeController.createTicketType';
import updateTicketTypeApex     from '@salesforce/apex/ManageTicketTypeController.updateTicketType';

const TOAST_VISIBLE_MS = 2600;

export default class TicketType extends LightningElement {

    // ─── STATE ────────────────────────────────────────────────────────────────
    @track _projectId         = null;
    @track _ticketTypes       = [];
    @track _workflowOptions   = [];
    @track _isLoading         = false;

    // create modal
    @track _showCreateModal     = false;
    @track _newName             = '';
    @track _newDescription      = '';
    @track _newIconUrl          = '';
    @track _newWorkflowId       = '';
    @track _isCreating          = false;
    @track _createErrorMessage  = '';

    // edit modal
    @track _editingTicketType   = null;
    @track _editName            = '';
    @track _editIconUrl         = '';
    @track _editWorkflowId      = '';
    @track _isUpdating          = false;
    @track _editErrorMessage    = '';

    // delete modal
    @track _deletingTicketType  = null;

    // toast
    @track _toast       = null;
    _toastTimer         = null;

    // ─── LIFECYCLE ────────────────────────────────────────────────────────────
    connectedCallback() {
        this._projectId = localStorage.getItem('projectId');
        if (this._projectId) {
            this._loadTicketTypes();
            this._loadWorkflows();
        }
    }

    // ─── PROJECT SELECTION (step 1) ───────────────────────────────────────────
    get hasProject() { return !!this._projectId; }

    handleProjectChosen(event) {
        this._projectId = event.detail?.projectId || localStorage.getItem('projectId');
        if (this._projectId) {
            this._loadTicketTypes();
            this._loadWorkflows();
        }
    }

    // ─── LIST (step 2) ────────────────────────────────────────────────────────
    _loadTicketTypes() {
        this._isLoading = true;
        loadTicketTypesByProject({ projectId: this._projectId })
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to load ticket types');
                    return;
                }
                this._ticketTypes = res.data || [];
            })
            .catch(err => this._showToast('error', this._readErr(err)))
            .finally(() => { this._isLoading = false; });
    }

    _loadWorkflows() {
        loadWorkflowsByProject({ projectId: this._projectId })
            .then(res => {
                if (!res || !res.success) {
                    this._workflowOptions = [];
                    return;
                }
                this._workflowOptions = (res.data || []).map(w => ({
                    label: w.Name,
                    value: w.Id
                }));
            })
            .catch(() => { this._workflowOptions = []; });
    }

    get hasTicketTypes() { return this._ticketTypes.length > 0; }
    get ticketTypeCount() { return this._ticketTypes.length; }

    get ticketTypeRows() {
        return this._ticketTypes.map(t => ({
            Id: t.Id,
            name: t.Name || '',
            description: t.Description__c || '—',
            iconUrl: t.IconUrl__c || '',
            hasIcon: !!t.IconUrl__c,
            workflowName: (t.Workflow__r && t.Workflow__r.Name) || '—',
            workflowId: t.Workflow__c || ''
        }));
    }

    get workflowOptions() {
        return this._workflowOptions;
    }

    // ─── CREATE ───────────────────────────────────────────────────────────────
    handleOpenCreate() {
        this._newName            = '';
        this._newDescription     = '';
        this._newIconUrl         = '';
        this._newWorkflowId      = '';
        this._createErrorMessage = '';
        this._showCreateModal    = true;
    }

    handleCloseCreate() {
        this._showCreateModal    = false;
        this._newName            = '';
        this._newDescription     = '';
        this._newIconUrl         = '';
        this._newWorkflowId      = '';
        this._createErrorMessage = '';
        this._isCreating         = false;
    }

    handleNewNameChange(event)        { this._newName        = event.detail.value; this._createErrorMessage = ''; }
    handleNewDescriptionChange(event) { this._newDescription = event.detail.value; this._createErrorMessage = ''; }
    handleNewIconUrlChange(event)     { this._newIconUrl     = event.detail.value; this._createErrorMessage = ''; }
    handleNewWorkflowChange(event)    { this._newWorkflowId  = event.detail.value; this._createErrorMessage = ''; }

    handleSubmitCreate() {
        const name        = (this._newName || '').trim();
        const description = (this._newDescription || '').trim();
        const iconUrl     = (this._newIconUrl || '').trim();
        const workflowId  = this._newWorkflowId;

        if (!name)       { this._createErrorMessage = 'Name is required'; return; }
        if (!workflowId) { this._createErrorMessage = 'Workflow is required'; return; }
        if (!this._projectId) { this._createErrorMessage = 'Project not selected'; return; }

        this._isCreating = true;
        createTicketTypeApex({
            name,
            description,
            iconUrl,
            workflowId,
            projectId: this._projectId
        })
            .then(res => {
                if (!res || !res.success) {
                    this._createErrorMessage = (res && res.message) || 'Failed to create ticket type';
                    return;
                }
                this._ticketTypes = [...this._ticketTypes, res.data];
                this.handleCloseCreate();
                this._showToast('success', `Ticket type "${res.data.Name}" created`);
            })
            .catch(err => { this._createErrorMessage = this._readErr(err); })
            .finally(() => { this._isCreating = false; });
    }

    get showCreateModal() { return this._showCreateModal; }

    // ─── EDIT ─────────────────────────────────────────────────────────────────
    handleOpenEdit(event) {
        const id = event.currentTarget.dataset.id;
        const tt = this._ticketTypes.find(t => t.Id === id);
        if (!tt) return;
        this._editingTicketType  = tt;
        this._editName           = tt.Name || '';
        this._editIconUrl        = tt.IconUrl__c || '';
        this._editWorkflowId     = tt.Workflow__c || '';
        this._editErrorMessage   = '';
    }

    handleCloseEdit() {
        this._editingTicketType = null;
        this._editName          = '';
        this._editIconUrl       = '';
        this._editWorkflowId    = '';
        this._editErrorMessage  = '';
        this._isUpdating        = false;
    }

    handleEditNameChange(event)     { this._editName        = event.detail.value; this._editErrorMessage = ''; }
    handleEditIconUrlChange(event)  { this._editIconUrl     = event.detail.value; this._editErrorMessage = ''; }
    handleEditWorkflowChange(event) { this._editWorkflowId  = event.detail.value; this._editErrorMessage = ''; }

    handleSubmitEdit() {
        const tt = this._editingTicketType;
        if (!tt) return;

        const name       = (this._editName || '').trim();
        const iconUrl    = (this._editIconUrl || '').trim();
        const workflowId = this._editWorkflowId;

        if (!name)       { this._editErrorMessage = 'Name is required'; return; }
        if (!workflowId) { this._editErrorMessage = 'Workflow is required'; return; }

        this._isUpdating = true;
        updateTicketTypeApex({
            ticketTypeId: tt.Id,
            name,
            iconUrl,
            workflowId
        })
            .then(res => {
                if (!res || !res.success) {
                    this._editErrorMessage = (res && res.message) || 'Failed to update ticket type';
                    return;
                }
                this._ticketTypes = this._ticketTypes.map(x => x.Id === tt.Id ? res.data : x);
                this.handleCloseEdit();
                this._showToast('success', `Ticket type "${res.data.Name}" updated`);
            })
            .catch(err => { this._editErrorMessage = this._readErr(err); })
            .finally(() => { this._isUpdating = false; });
    }

    get showEditModal() { return this._editingTicketType !== null; }

    // ─── DELETE (modal + console.log only — not implemented yet) ──────────────
    handleOpenDelete(event) {
        const id = event.currentTarget.dataset.id;
        const tt = this._ticketTypes.find(t => t.Id === id);
        if (!tt) return;
        this._deletingTicketType = tt;
    }

    handleCloseDelete() {
        this._deletingTicketType = null;
    }

    handleConfirmDelete() {
        const tt = this._deletingTicketType;
        if (!tt) return;
        // eslint-disable-next-line no-console
        console.log('delete ticket type', { id: tt.Id, name: tt.Name, projectId: tt.Project__c });
        this._showToast('default', `Delete "${tt.Name}" — not implemented yet (logged to console)`);
        this._deletingTicketType = null;
    }

    get showDeleteModal() { return this._deletingTicketType !== null; }
    get deletingTicketTypeName() {
        return this._deletingTicketType ? (this._deletingTicketType.Name || '') : '';
    }

    // ─── TOAST ────────────────────────────────────────────────────────────────
    _showToast(variant, message) {
        this._toast = { variant, message };
        if (this._toastTimer) clearTimeout(this._toastTimer);
        this._toastTimer = setTimeout(() => {
            this._toast = null;
            this._toastTimer = null;
        }, TOAST_VISIBLE_MS);
    }

    get toastClass() {
        if (!this._toast) return 'toast';
        return `toast toast--${this._toast.variant}`;
    }

    // ─── HELPERS ──────────────────────────────────────────────────────────────
    _readErr(err) {
        if (!err) return 'Unexpected error';
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return String(err);
    }
}
