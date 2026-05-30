import { LightningElement, track, wire } from 'lwc';
import { loadStyle }    from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadManageTicketTrackingPage from '@salesforce/apex/ManageTicketTrackingController.loadManageTicketTrackingPage';
import changeTicketState            from '@salesforce/apex/ManageTicketTrackingController.changeTicketState';
import loadTicketLinkTypes          from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkTypes';
import loadTicketLinkedTo           from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkedTo';
import loadTicketBySearchTerm       from '@salesforce/apex/ManageTicketTrackingController.loadTicketBySearchTerm';
import updateTicketSummary          from '@salesforce/apex/ManageTicketTrackingController.updateTicketSummary';
import updateTicketDescription      from '@salesforce/apex/ManageTicketTrackingController.updateTicketDescription';
import linkToTicket                 from '@salesforce/apex/ManageTicketTrackingController.linkToTicket';
import loadSubtasks                 from '@salesforce/apex/ManageTicketTrackingController.loadSubtasks';
import createSubtask                from '@salesforce/apex/ManageTicketTrackingController.createSubtask';
import aoThemeResource              from '@salesforce/resourceUrl/aoTheme';

import { validateChangeTicketState }                        from './manageTicketTrackingValidator';
import { buildColumns, buildSprintTickets, enrichTicketsWithStateChange, newTicketKey } from './ticketUtils';
import { getValidTargetStatusIds, findTransitionId } from './workflowUtils';
import { formatSprintDateRange }                            from './sprintUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// sprint  is the principale de-normalized state example of it : 
/*
{
  "Id": "a06d200000LDNCPAA5",
  "Name": "sprint1",
  "Duration__c": 2,
  "StartDate__c": "2026-05-06",
  "Goal__c": "dasdsad",
  "Project__c": "a00d200002j4o2wAAA",
  "RecordStatus__c": "in_progress",
  "TotalStoryPoint__c": 24,
  "TotalEndedStoryPoint__c": 26,
  "tickets": [
    {
      "Id": "a0Cd200001ChX6AEAV",
      "Name": "dasdsa",
      "Summary__c": "dsad",
      "CurrentState__c": "a02d200000YKyncAAD",
      "Priority__c": "Critical",
      "StoryPoint__c": 2,
      "Sprint__c": "a06d200000LDNCPAA5",
      "Ticket_Type__c": "a05d200000P51DBAAZ",
      "RecordStatus__c": "active",
      "ticketType": {
        "Id": "a05d200000P51DBAAZ",
        "Name": "Story",
        "Description__c": "Standard story ticket type",
        "IconUrl__c": "https://example.com/icons/story.png",
        "Project__c": "a00d200002j4o2wAAA",
        "RecordStatus__c": "Active",
        "Workflow__c": "a01d200001g7lT3AAI",
        "Workflow__r": {
          "Name": "Default Workflow",
          "Id": "a01d200001g7lT3AAI"
        },
        "workflowTransitions": [
          {
            "Id": "a03d200001mtP9hAAE",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YKynbAAD",
            "ToStatus__c": "a02d200000YL6mnAAD"
          },
          {
            "Id": "a03d200001mtPEXAA2",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YL6mnAAD",
            "ToStatus__c": "a02d200000YL6oPAAT"
          },
          {
            "Id": "a03d200001mtPJNAA2",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YL6oPAAT",
            "ToStatus__c": "a02d200000YKyncAAD"
          }
        ]
      },
      "ticketTypeName": "Story",
      "assigneeName": "",
      "isEndStatus": true
    },
    {
      "Id": "a0Cd200001CmpLpEAJ",
      "Name": "dsad",
      "Summary__c": "sadsa",
      "CurrentState__c": "a02d200000YKyncAAD",
      "Priority__c": "High",
      "StoryPoint__c": 2,
      "Sprint__c": "a06d200000LDNCPAA5",
      "Ticket_Type__c": "a05d200000P51DBAAZ",
      "RecordStatus__c": "active",
      "ticketType": {
        "Id": "a05d200000P51DBAAZ",
        "Name": "Story",
        "Description__c": "Standard story ticket type",
        "IconUrl__c": "https://example.com/icons/story.png",
        "Project__c": "a00d200002j4o2wAAA",
        "RecordStatus__c": "Active",
        "Workflow__c": "a01d200001g7lT3AAI",
        "Workflow__r": {
          "Name": "Default Workflow",
          "Id": "a01d200001g7lT3AAI"
        },
        "workflowTransitions": [
          {
            "Id": "a03d200001mtP9hAAE",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YKynbAAD",
            "ToStatus__c": "a02d200000YL6mnAAD"
          },
          {
            "Id": "a03d200001mtPEXAA2",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YL6mnAAD",
            "ToStatus__c": "a02d200000YL6oPAAT"
          },
          {
            "Id": "a03d200001mtPJNAA2",
            "Workflow__c": "a01d200001g7lT3AAI",
            "FromStatus__c": "a02d200000YL6oPAAT",
            "ToStatus__c": "a02d200000YKyncAAD"
          }
        ]
      },
      "ticketTypeName": "Story",
      "assigneeName": "",
      "isEndStatus": true
    }
  ]
}
*/

export default class ManageTicketTracking extends LightningElement {

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    _projectId      = null;
    @track _showChooseProject = false;
    isLoading       = false;
    errorMessage    = null;

    @track memberOptions   = [];
    @track statusOptions   = [];
    @track epics           = [];
    @track priorityOptions = [];

    _sprint   = null;
    _statuses = [];

    // ─── TICKET-VIEW STATE ────────────────────────────────────────────────────
    // R4: the Id of the ticket whose detail panel is open lives OUTSIDE the
    // de-normalized principal state, so we always know which child is shown.
    @track _activeTicketViewId    = null;
    // Separate wire input (R0/Step 8): the linked-to wire fires on expand, not
    // on ticket selection — so it is decoupled from _activeTicketViewId.
    @track _linkedToTargetTicketId = null;
    // ticketsearch results are NOT part of the principal state — their own
    // @wire-backed state, used only to feed the child's auto-complete options.
    @track _searchTerm           = null;
    @track _ticketSearchResults  = [];

    // Drag state
    _dragTicketId        = null;
    _dragFromStatusId    = null;
    _dragTicketType      = null;
    _dragToStatusId      = null;
    _validTargetStatusIds = [];

    // ─── WIRE ─────────────────────────────────────────────────────────────────


    @wire(loadTicketLinkTypes, { projectId: '$_projectId' })
    handleLinkedTypeTicketWire({ data }) {
        if (data && data.success) {
            this._ticketLinkTypes = (data.data && data.data.ticketLinkTypes) || [];
        }
    }

    // ticketlinkedtoexpand: wire fires when _linkedToTargetTicketId is set on
    // expand. R0 wired-FUNCTION form — read the response and patch the linkedTo
    // slice of the principal ticket manually (never bind to a property).
    @wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
    wiredTicketLinkedTo(result) {
        if (result.data && result.data.success && this._linkedToTargetTicketId) {
            const linkedTo = (result.data.data && result.data.data.ticketLinkTo) || [];
            this._patchTicket(this._linkedToTargetTicketId, { linkedTo });
        }
    }

    // ticketsearch: results are non-principal state. Plain @wire with its own
    // state (no refreshApex), gated on the search term coming from the child.
    @wire(loadTicketBySearchTerm, { projectId: '$_projectId', searchTerm: '$_searchTerm' })
    wiredTicketSearch(result) {
        if (result.data && result.data.success) {
            this._ticketSearchResults = result.data.data || [];
        }
    }

    // subtasksexpand: wire fires when _subtasksTargetTicketId is set on expand.
    // Read the response and patch the subtasks slice of the principal ticket.
    @track _subtasksTargetTicketId = null;
    @wire(loadSubtasks, { ticketId: '$_subtasksTargetTicketId' })
    wiredSubtasks(result) {
        if (result.data && result.data.success && this._subtasksTargetTicketId) {
            const subtasks = result.data.data || [];
            this._patchTicket(this._subtasksTargetTicketId, { subtasks });
        }
    }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get sprint()              { return this._sprint; }
    get projectId()           { return this._projectId; }
    get showLinkedToPopup()   { return this._showLinkedToPopup; }
    get linkedToTicketId()    { return this._linkedToTicketId; }
    get linkedToItems()       { return this._linkedToItems; }
    get linkedToListKey()     { return this._linkedToListKey; }
    get ticketLinkTypes()  { return this._ticketLinkTypes || []; }
    get tickets() { return (this._sprint && this._sprint.tickets) || []; }

    // R3: presentation state — drives whether the ticket-view panel renders.
    get isTicketViewOpen() { return this._activeTicketViewId !== null; }

    // R2: derived child prop — computed on read from the principal state, never
    // stored. The open ticket is looked up by its Id each render.
    get activeTicketViewModel() {
        if (!this._activeTicketViewId) return null;
        return this._findTicketById(this._activeTicketViewId);
    }

    // R2: derived child prop — search results mapped to combobox options.
    get ticketViewSearchOptions() {
        return this._ticketSearchResults.map(t => ({
            label: t.Summary__c ? `${t.Name} — ${t.Summary__c}` : t.Name,
            value: t.Id
        }));
    }

    // Columns are derived, never stored: statuses give the lanes, the sprint's
    // tickets fill them, and the active drag decides which lanes are valid drops.
    get columns() {
        return buildColumns(this._statuses, this.tickets, this._validTargetStatusIds);
    }

    get sprintDateRange() {
        return formatSprintDateRange(this._sprint);
    }

    get storyPointsPercent() {
        if (!this.sprint.TotalEndedStoryPoint__c) return 0;
        return Math.round((this.sprint.TotalEndedStoryPoint__c / this.sprint.TotalStoryPoint__c) * 100);
    }


    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    connectedCallback() {
        loadStyle(this, aoThemeResource);
        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this._showChooseProject = true;
            return;
        }
        this._projectId = projectId;
        this._loadData();
    }

    handleProjectChosen(event) {
        const { projectId } = event.detail || {};
        if (!projectId) return;
        this._projectId         = projectId;
        this._showChooseProject = false;
        this._loadData();
    }

    get showChooseProject() { return this._showChooseProject; }

    _loadData() {
        this.isLoading = true;
        loadManageTicketTrackingPage({ projectId: this._projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const response = res.data;
                this._statuses       = response.status         || [];
                this.epics           = response.epics          || [];
                this.priorityOptions = response.priorityOptions || [];
                this.statusOptions   = this._statuses.map(s => ({ label: s.Name, value: s.Id }));
                this.memberOptions   = (response.members || []).map(m => ({
                    label: (m.User__r && m.User__r.Name) || m.Name || '',
                    value: m.Id,
                }));

                const sprint = response.sprint;
                this._sprint = sprint
                    ? {
                        ...sprint,
                        tickets: buildSprintTickets(
                            response.sprint_tickets,
                            response.ticketTypes,
                            response.workflows,
                            this._statuses,
                            response.members
                        )
                      }
                    : null;
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error loading page'; })
            .finally(() => { this.isLoading = false; });
    }

    _callChangeTicketState(ticketId, fromStatusId, toStatusId) {
        changeTicketState({ ticketId, fromStatusId, toStatusId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const isEndStatus   = res.data && res.data.isEndStatus;
                const updatedSprint = res.data && res.data.updatedSprint;

                const newSprint = {
                    ...this._sprint,
                    tickets: enrichTicketsWithStateChange(this.tickets, ticketId, toStatusId, isEndStatus)
                };
                if (isEndStatus && updatedSprint) {
                    newSprint.TotalEndedStoryPoint__c = updatedSprint.TotalEndedStoryPoint__c;
                }
                this._sprint = newSprint;
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error changing ticket state'; })
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          TICKET SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleTicketDragStart(evt) {
        const { ticketId, fromStatusId } = evt.detail;
        const ticket = this.tickets.find(t => t.Id === ticketId);

        this._dragTicketId     = ticketId;
        this._dragFromStatusId = fromStatusId;
        this._dragTicketType   = ticket ? ticket.ticketType : null;

        const validTargets = getValidTargetStatusIds(this._dragTicketType, fromStatusId);
        this._validTargetStatusIds = [...validTargets];
    }

    handleTicketDrop(evt) {
        const { toStatusId }  = evt.detail;
        const ticketId        = this._dragTicketId;
        const fromStatusId    = this._dragFromStatusId;
        const ticketType      = this._dragTicketType;

        if (toStatusId === fromStatusId) return;
        this._dragToStatusId = toStatusId;

        const error = validateChangeTicketState(ticketId, toStatusId);
        if (error) { this.errorMessage = error; return; }

        const transitionId = findTransitionId(ticketType, fromStatusId, toStatusId);
        if (!transitionId) { this.errorMessage = 'This transition is not allowed by the workflow.'; return; }

        this._callChangeTicketState(ticketId, fromStatusId, toStatusId);
    }

    handleTicketDragEnd(evt) {
        const { ticketId }         = evt.detail;
        const newCurrentStatusId   = this._dragToStatusId;
        if (ticketId && newCurrentStatusId) {
            this._sprint = {
                ...this._sprint,
                tickets: this.tickets.map(t =>
                    t.Id === ticketId ? { ...t, key: newTicketKey(), CurrentState__c: newCurrentStatusId } : t
                )
            };
        }
        this._clearDragState();
    }

    // ─── PRIVATE HELPERS ──────────────────────────────────────────────────────
    _clearDragState() {
        this._dragTicketId        = null;
        this._dragFromStatusId    = null;
        this._dragTicketType      = null;
        this._dragToStatusId      = null;
        this._validTargetStatusIds = [];
    }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                       TICKET-VIEW SECTION                                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── EVENT HANDLERS (R1: one handler per child event) ─────────────────────

    // Opens the detail panel by recording which ticket is active (R4).
    handleOpenTicketView(evt) {
        this._activeTicketViewId = evt.detail.ticketId;
    }

    // ticketsummaryupdate → imperative updateTicketSummary, then patch the
    // principal ticket from the Apex response, never the optimistic draft (R0).
    handleTicketViewSummaryUpdate(evt) {
        const { ticketId, summary } = evt.detail;
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                if (!res.success) { this._showError(res.message); return; }
                const updated = res.data || {};
                this._patchTicket(ticketId, { Summary__c: updated.Summary__c });
            })
            .catch(err => this._showError(this._errMsg(err, 'Error updating ticket summary')));
    }

    // ticketstatuschange → reuse the existing workflow-aware state change call,
    // which already updates the principal state from the Apex response (R0).
    handleTicketViewStatusChange(evt) {
        const { ticketId, fromStatusId, toStatusId } = evt.detail;
        this._callChangeTicketState(ticketId, fromStatusId, toStatusId);
    }

    // ticketdescriptionupdate → imperative updateTicketDescription, patch from
    // the response (R0).
    handleTicketViewDescriptionUpdate(evt) {
        const { ticketId, description } = evt.detail;
        updateTicketDescription({ ticketId, description })
            .then(res => {
                if (!res.success) { this._showError(res.message); return; }
                const updated = res.data || {};
                this._patchTicket(ticketId, { Description__c: updated.Description__c });
            })
            .catch(err => this._showError(this._errMsg(err, 'Error updating ticket description')));
    }

    // ticketlinkedtoexpand → set the dedicated wire input so loadTicketLinkedTo
    // fires on expand (the wire handler does the R0-compliant state update).
    handleTicketLinkedToExpand(evt) {
        this._linkedToTargetTicketId = evt.detail.ticketId;
    }

    // ticketsearch → set the search term so the loadTicketBySearchTerm wire
    // refreshes its own (non-principal) results state.
    handleTicketSearch(evt) {
        this._searchTerm = evt.detail.searchTerm;
    }

    // ticketlinkcreate → imperative linkToTicket, then append the returned link
    // to the principal ticket's linkedTo list from the response (R0).
    handleTicketLinkCreate(evt) {
        const { fromTicketId, toTicketId, linkType } = evt.detail;
        linkToTicket({ fromTicketId, toTicketId, linkType })
            .then(res => {
                if (!res.success) { this._showError(res.message); return; }
                const link = res.data && res.data.ticketLink;
                if (!link) return;
                const ticket   = this._findTicketById(fromTicketId);
                const existing = (ticket && Array.isArray(ticket.linkedTo)) ? ticket.linkedTo : [];
                this._patchTicket(fromTicketId, { linkedTo: [...existing, link] });
            })
            .catch(err => this._showError(this._errMsg(err, 'Error linking ticket')));
    }



    // subtasksexpand → set the dedicated wire input so loadSubtasks fires on
    // expand (the wire handler does the R0-compliant subtasks patch).
    handleTicketSubtasksExpand(evt) {
        this._subtasksTargetTicketId = evt.detail.ticketId;
    }

    // subtaskcreate → imperative createSubtask, then append the returned subtask
    // to the principal ticket's subtasks list from the response (R0).
    handleTicketSubtaskCreate(evt) {
        const { ticketId, summary, description, assigneeId, currentStateId, startDate, storyPoint } = evt.detail;
        createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate })
            .then(res => {
                if (!res.success) { this._showError(res.message); return; }
                const created = res.data;
                if (!created) return;
                const ticket   = this._findTicketById(ticketId);
                const existing = (ticket && Array.isArray(ticket.subtasks)) ? ticket.subtasks : [];
                this._patchTicket(ticketId, { subtasks: [...existing, created] });
            })
            .catch(err => this._showError(this._errMsg(err, 'Error creating subtask')));
    }

    // closeticketview → presentation-only reset, no Apex. Clearing the active
    // Id collapses the derived getters and unmounts the panel (R3/R4).
    handleCloseTicketView() {
        this._activeTicketViewId     = null;
        this._linkedToTargetTicketId = null;
        this._subtasksTargetTicketId = null;
        this._searchTerm             = null;
        this._ticketSearchResults    = [];
    }

    // ─── MUTATORS (R5: find / update over the principal state) ────────────────
    _findTicketById(ticketId) {
        return this.tickets.find(t => t.Id === ticketId) || null;
    }

    _patchTicket(ticketId, patch) {
        if (!this._sprint) return;
        this._sprint = {
            ...this._sprint,
            tickets: this.tickets.map(t => t.Id === ticketId ? { ...t, ...patch } : t)
        };
    }

    // ─── PRIVATE HELPERS ──────────────────────────────────────────────────────
    // R6: surface failures through a toast.
    _showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title  : 'Error',
            message: message || 'Something went wrong',
            variant: 'error'
        }));
    }

    _errMsg(err, fallback) {
        return (err && err.body && err.body.message) || fallback;
    }

}
