import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    validateTicketSummary,
    validateTicketCurrentState,
    validateTicketLink,
    validateSubtaskSummary
} from './ticketViewValidator';

/**
 * c-ticket-view
 *
 * Self-contained ticket detail panel that hosts three inline sub-sections:
 *   1. Summary       — inline editable text (uses c-ao-input)
 *   2. Status        — combobox bound to statusOptions
 *   3. Description   — view/edit toggle with lightning-input-rich-text
 *   4. Linked items  — expanding list with add-link form
 *
 * All sub-sections live in this single LWC by design (see spec).
 *
 * STATE FLOW
 * ──────────
 * The component is fully controlled:
 *   - `ticket` is read-only input from the parent (never mutated locally).
 *   - Drafts (_draftSummary, _draftDescription) hold in-progress edits.
 *   - On Save → validate → dispatch event → parent updates `ticket`.
 *   - On Cancel → discard draft → exit edit mode.
 */
export default class TicketView extends LightningElement {

    // ─── @api INPUTS ──────────────────────────────────────────────────────────

    /**
     * The ticket being viewed — the raw ticket record:
     *   {
     *     Id, Name, Summary__c, Description__c, Priority__c,
     *     CurrentState__c, AssignedTo__c, Ticket_Type__c,
     *     assigneeName, ticketTypeName,
     *     linkedTo: [ {
     *       linkId, type, recordStatus, ticketFromId,
     *       linkedToTicket: { Id, Name, Summary__c, Priority__c,
     *                         CurrentState__c, AssignedTo__c, Ticket_Type__c }
     *     } ],
     *     subtasks : []
     *   }
     */
    _ticket = {};

    @api
    get ticket() { return this._ticket; }
    set ticket(value) {
        console.log("ticket view : " + JSON.stringify(value));
        this._ticket = value || {};
        this._draftSummary     = this._ticket.Summary__c     || '';
        this._draftDescription = this._ticket.Description__c || '';
    }

    /** [{ label, value }] — status options for the Current State combobox. */
    @api statusOptions = [];

    /** [{ label, value }] — link-type options (Blocks · Relates To · ...). */
    @api ticketLinkedToTypeOptions = [];

    /** [{ label, value }] — ticket options for the auto-complete combobox.
     *  Parent should populate in response to the `ticketsearch` event. */
    @api ticketOptions = [];

    /** [{ label, value }] — assignee options for the subtask add form. */
    @api assigneeOptions = [];


    // ─── LOCAL EDIT STATE ─────────────────────────────────────────────────────

    @track _isSummaryEditing     = false;
    @track _draftSummary         = '';
    @track _summaryError         = null;

    @track _isDescriptionEditing = false;
    @track _draftDescription     = '';

    @track _statusError          = null;

    @track _isLinkedToExpanded   = false;
    @track _showLinkedToAddForm  = false;
    @track _selectedLinkType     = '';
    @track _selectedLinkedTicket = '';
    @track _linkedToError        = null;

    @track _isSubtasksExpanded   = false;
    @track _showSubtaskAddForm   = false;
    @track _newSubtask           = this.blankSubtask();


    // ─── GETTERS ──────────────────────────────────────────────────────────────

    get isSummaryEditing()     { return this._isSummaryEditing; }
    get draftSummary()         { return this._draftSummary; }
    get summaryError()         { return this._summaryError; }

    get currentStatusId()      { return this._ticket.CurrentState__c || ''; }
    get statusError()          { return this._statusError; }

    get isDescriptionEditing() { return this._isDescriptionEditing; }
    get draftDescription()     { return this._draftDescription; }
    get hasDescription()       { return !!(this._ticket.Description__c && this._ticket.Description__c.trim()); }

    get isLinkedToExpanded()   { return this._isLinkedToExpanded; }
    get chevronIcon()          { return this._isLinkedToExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
    get showLinkedToAddForm()  { return this._showLinkedToAddForm; }
    get linkedToError()        { return this._linkedToError; }

    get isLinkDisabled() {
        return !this._selectedLinkType || !this._selectedLinkedTicket;
    }

    get linkedItems() {
        return Array.isArray(this._ticket.linkedTo) ? this._ticket.linkedTo : [];
    }

    get hasLinkedItems() {
        return this.linkedItems.length > 0;
    }

    get isSubtasksExpanded()   { return this._isSubtasksExpanded; }
    get subtasksChevronIcon()  { return this._isSubtasksExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
    get showSubtaskAddForm()   { return this._showSubtaskAddForm; }

    get newSubtask()           { return this._newSubtask; }

    get subtasks() {
        return Array.isArray(this._ticket.subtasks) ? this._ticket.subtasks : [];
    }

    get hasSubtasks() {
        return this.subtasks.length > 0;
    }

    get isSubtaskCreateDisabled() {
        return !this._newSubtask.summary || !this._newSubtask.summary.trim();
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                       SUMMARY  SECTION                               ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleTicketSummaryEdit() {
        this._draftSummary    = this._ticket.Summary__c || '';
        this._summaryError    = null;
        this._isSummaryEditing = true;
    }

    handleTicketSummaryChange(event) {
        this._draftSummary = event.detail.value;
        if (this._summaryError) this._summaryError = null;
    }

    handleTicketSummarySave() {
        const error = validateTicketSummary(this._draftSummary);
        if (error) { this._summaryError = error; return; }

        const detail = { ticketId: this._ticket.Id, summary: this._draftSummary.trim() };
        console.log('[ticket-view] dispatch ticketsummaryupdate', detail);
        this.dispatchEvent(new CustomEvent('ticketsummaryupdate', {
            detail, bubbles: true, composed: true
        }));
        this._isSummaryEditing = false;
    }

    handleTicketSummaryCancel() {
        this._draftSummary    = this._ticket.Summary__c || '';
        this._summaryError    = null;
        this._isSummaryEditing = false;
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                        STATUS  SECTION                               ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleTicketStatusChange(event) {
        const newStatusId = event.detail.value;
        const error = validateTicketCurrentState(newStatusId);
        if (error) { this._statusError = error; return; }
        this._statusError = null;

        const detail = {
            ticketId:     this._ticket.Id,
            fromStatusId: this._ticket.CurrentState__c || null,
            toStatusId:   newStatusId
        };
        console.log('[ticket-view] dispatch ticketstatuschange', detail);
        this.dispatchEvent(new CustomEvent('ticketstatuschange', {
            detail, bubbles: true, composed: true
        }));
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                     DESCRIPTION  SECTION                             ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleTicketDescriptionEdit() {
        this._draftDescription     = this._ticket.Description__c || '';
        this._isDescriptionEditing = true;
    }

    handleTicketDescriptionChange(event) {
        this._draftDescription = event.target.value;
    }

    handleTicketDescriptionSave() {
        const detail = { ticketId: this._ticket.Id, description: this._draftDescription };
        console.log('[ticket-view] dispatch ticketdescriptionupdate', detail);
        this.dispatchEvent(new CustomEvent('ticketdescriptionupdate', {
            detail, bubbles: true, composed: true
        }));
        this._isDescriptionEditing = false;
    }

    handleTicketDescriptionCancel() {
        this._draftDescription     = this._ticket.Description__c || '';
        this._isDescriptionEditing = false;
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                   LINKED-TO LIST  SECTION                            ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleTicketLinkedToToggle() {
        this._isLinkedToExpanded = !this._isLinkedToExpanded;
        if (this._isLinkedToExpanded) {
            const detail = { ticketId: this._ticket.Id};
            console.log('[ticket-view] dispatch ticketlinkedtoexpand', detail);
            this.dispatchEvent(new CustomEvent('ticketlinkedtoexpand', {
                detail, bubbles: true, composed: true
            }));
        } else {
            this._showLinkedToAddForm = false;
            this._linkedToError       = null;
        }
    }

    handleTicketLinkedToAdd() {
        this._isLinkedToExpanded   = true;
        this._showLinkedToAddForm  = true;
        this._selectedLinkType     = '';
        this._selectedLinkedTicket = '';
        this._linkedToError        = null;
    }

    handleTicketLinkedToTypeChange(event) {
        this._selectedLinkType = event.detail.value;
        if (this._linkedToError) this._linkedToError = null;
    }

    handleTicketLinkedToTicketChange(event) {
        this._selectedLinkedTicket = event.detail.value;
        if (this._linkedToError) this._linkedToError = null;
    }

    handleTicketLinkedToTicketSearch(event) {
        const searchTerm = (event.detail.searchTerm || '').trim();
        if (searchTerm.length < 2) return;
        this.dispatchEvent(new CustomEvent('ticketsearch', {
            detail: { searchTerm },
            bubbles: true,
            composed: true
        }));
    }

    handleTicketLinkCreate() {
        const error = validateTicketLink({
            linkType:   this._selectedLinkType,
            toTicketId: this._selectedLinkedTicket
        });
        if (error) { this._linkedToError = error; return; }

        const data = {
            fromTicketId: this._ticket.Id,
            toTicketId:   this._selectedLinkedTicket,
            linkType:     this._selectedLinkType
        };

        this.dispatchEvent(new CustomEvent('ticketlinkcreate', {
            detail: data, bubbles: true, composed: true
        }));

        this._showLinkedToAddForm  = false;
        this._selectedLinkType     = '';
        this._selectedLinkedTicket = '';
    }

    handleTicketLinkedToCancel() {
        this._showLinkedToAddForm  = false;
        this._selectedLinkType     = '';
        this._selectedLinkedTicket = '';
        this._linkedToError        = null;
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                       SUBTASKS  SECTION                              ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleTicketSubtasksToggle() {
        this._isSubtasksExpanded = !this._isSubtasksExpanded;
        if (this._isSubtasksExpanded) {
            const detail = { ticketId: this._ticket.Id };
            console.log('[ticket-view] dispatch subtasksexpand', detail);
            this.dispatchEvent(new CustomEvent('subtasksexpand', {
                detail, bubbles: true, composed: true
            }));
        } else {
            this._showSubtaskAddForm = false;
        }
    }

    handleTicketSubtaskAdd() {
        this._isSubtasksExpanded = true;
        this._showSubtaskAddForm = true;
        this._newSubtask         = this.blankSubtask();
    }

    handleTicketSubtaskSummaryChange(event) {
        this._newSubtask = { ...this._newSubtask, summary: event.detail.value };
    }

    handleTicketSubtaskDescriptionChange(event) {
        this._newSubtask = { ...this._newSubtask, description: event.target.value };
    }

    handleTicketSubtaskAssigneeChange(event) {
        this._newSubtask = { ...this._newSubtask, assigneeId: event.detail.value };
    }

    handleTicketSubtaskStateChange(event) {
        this._newSubtask = { ...this._newSubtask, currentStateId: event.detail.value };
    }

    handleTicketSubtaskStartDateChange(event) {
        this._newSubtask = { ...this._newSubtask, startDate: event.target.value };
    }

    handleTicketSubtaskStoryPointChange(event) {
        this._newSubtask = { ...this._newSubtask, storyPoint: event.target.value };
    }

    handleTicketSubtaskCreate() {
        const error = validateSubtaskSummary(this._newSubtask.summary);
        if (error) {
            this.dispatchEvent(new ShowToastEvent({
                title:   'Validation Error',
                message: error,
                variant: 'error'
            }));
            return;
        }

        const data = {
            ticketId:       this._ticket.Id,
            summary:        this._newSubtask.summary.trim(),
            description:    this._newSubtask.description,
            assigneeId:     this._newSubtask.assigneeId     || null,
            currentStateId: this._newSubtask.currentStateId || null,
            startDate:      this._newSubtask.startDate      || null,
            storyPoint:     this._newSubtask.storyPoint     || null
        };
        console.log('[ticket-view] dispatch subtaskcreate', data);
        this.dispatchEvent(new CustomEvent('subtaskcreate', {
            detail: data, bubbles: true, composed: true
        }));

        this._showSubtaskAddForm = false;
    }

    handleTicketSubtaskCancel() {
        this._showSubtaskAddForm = false;
    }

    blankSubtask() {
        return {
            summary:        '',
            description:    '',
            assigneeId:     '',
            currentStateId: '',
            startDate:      '',
            storyPoint:     ''
        };
    }


    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║                          CLOSE                                       ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    handleClose() {
        this.dispatchEvent(new CustomEvent('closeticketview', {
            bubbles: true, composed: true
        }));
    }
}
