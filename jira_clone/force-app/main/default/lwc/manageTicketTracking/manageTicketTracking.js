import { LightningElement, track, wire } from 'lwc';
import { loadStyle }    from 'lightning/platformResourceLoader';
import loadManageTicketTrackingPage from '@salesforce/apex/ManageTicketTrackingController.loadManageTicketTrackingPage';
import changeTicketState            from '@salesforce/apex/ManageTicketTrackingController.changeTicketState';
import loadTicketLinkTypes          from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkTypes';
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
    isLoading       = false;
    errorMessage    = null;

    @track memberOptions   = [];
    @track statusOptions   = [];
    @track epics           = [];
    @track priorityOptions = [];

    _sprint   = null;
    _statuses = [];

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

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get sprint()              { return this._sprint; }
    get projectId()           { return this._projectId; }
    get showLinkedToPopup()   { return this._showLinkedToPopup; }
    get linkedToTicketId()    { return this._linkedToTicketId; }
    get linkedToItems()       { return this._linkedToItems; }
    get linkedToListKey()     { return this._linkedToListKey; }
    get ticketLinkTypes()  { return this._ticketLinkTypes || []; }
    get tickets() { return (this._sprint && this._sprint.tickets) || []; }

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
            this.errorMessage = 'No project selected. Please select a project first.';
            return;
        }
        this._projectId = projectId;
        this._loadData();
    }

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

}
