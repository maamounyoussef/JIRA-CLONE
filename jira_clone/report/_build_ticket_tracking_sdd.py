# -*- coding: utf-8 -*-
"""
Build report/SDD_ManageTicketTracking.docx.

NOTE: we reuse SDD_ManageBacklog.docx as a template and wipe its body, but
python-docx leaves the template's now-unreferenced screenshots in word/media/.
prune_orphan_media() drops every image part no longer referenced by the body so
the output only carries the cover logo + the Ticket-Tracking screenshots.

Monitors report/SDD_ManageBacklog.docx as the *style + structure template*:
same cover, Aptos Display headings, API-method tables (Kind C/I legend),
Consolas ASCII architecture / sequence diagrams, the ###-wrapped image marker
convention, and the Traceability table. Content is grounded in the actual
manageTicketTracking LWC + ManageTicketTrackingController code. The
Ticket-Tracking screenshots are inserted full-width (width only -> aspect ratio
preserved, never cropped).
"""
import os, zipfile
from docx import Document
from docx.shared import Pt, Emu, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ROOT      = os.path.dirname(os.path.abspath(__file__))
TEMPLATE  = os.path.join(ROOT, 'SDD_ManageBacklog.docx')
OUT       = os.path.join(ROOT, 'SDD_ManageTicketTracking.docx')
IMG_DIR   = os.path.normpath(os.path.join(ROOT, '..', 'force-app', 'Ticket-Tracking-images'))
TMP_LOGO  = os.path.join(ROOT, '_cover_logo.png')

# extract the cover logo (word/media/image1.png) from the template
with zipfile.ZipFile(TEMPLATE) as z:
    with open(TMP_LOGO, 'wb') as f:
        f.write(z.read('word/media/image1.png'))

doc = Document(TEMPLATE)

# wipe the template body, keep the trailing sectPr (page setup)
body = doc.element.body
for child in list(body):
    if child.tag in (qn('w:p'), qn('w:tbl')):
        body.remove(child)

CONTENT_W     = Inches(6.3)            # fits inside 1" margins on Letter
HEADING_COLOR = RGBColor(0x0F, 0x47, 0x61)
CENTER        = WD_ALIGN_PARAGRAPH.CENTER
HASH          = '#' * 27

# ── helpers ───────────────────────────────────────────────────────────────────
def set_consolas(run, size):
    run.font.size = Pt(size)
    rPr = run._element.get_or_add_rPr()
    rFonts = rPr.find(qn('w:rFonts'))
    if rFonts is None:
        rFonts = OxmlElement('w:rFonts'); rPr.append(rFonts)
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rFonts.set(qn(a), 'Consolas')

def cover_line(text, size, italic=True, black=False, before=None, after=None):
    p = doc.add_paragraph(); p.alignment = CENTER
    if before is not None: p.paragraph_format.space_before = Emu(before)
    if after  is not None: p.paragraph_format.space_after  = Emu(after)
    r = p.add_run(text)
    r.italic = italic
    r.font.name = 'Aptos Display'
    r.font.size = Pt(size)
    if black:
        r.font.color.rgb = RGBColor(0, 0, 0)
    return p

def h(level, text):
    return doc.add_heading(text, level=level)

def normal(text, bold=False):
    p = doc.add_paragraph()
    r = p.add_run(text); r.bold = bold
    return p

def label(text):
    """Bold inline label (used for the 3.x sequence-flow headers)."""
    p = doc.add_paragraph()
    r = p.add_run(text); r.bold = True
    return p

def bullet(text):
    return doc.add_paragraph('•  ' + text)

def mono(text, size=9):
    """Consolas block paragraph; '\\n' becomes a real line break (w:br)."""
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(8)
    lines = text.split('\n')
    for i, ln in enumerate(lines):
        run = p.add_run(ln); set_consolas(run, size)
        if i != len(lines) - 1:
            br = p.add_run(); br.add_break(WD_BREAK.LINE)
    return p

def marker(filename):
    """One image marker block: ### / filename / ### (Consolas 8pt)."""
    for line in (HASH, filename, HASH):
        p = doc.add_paragraph()
        set_consolas(p.add_run(line), 8)

def figure(filename, width=CONTENT_W):
    """Marker convention: filename wrapped immediately before AND after the image."""
    marker(filename)
    p = doc.add_paragraph(); p.alignment = CENTER
    p.add_run().add_picture(os.path.join(IMG_DIR, filename), width=width)  # width only -> no crop
    marker(filename)

def _table_borders(table):
    tblPr = table._tbl.tblPr
    borders = OxmlElement('w:tblBorders')
    for edge in ('top', 'bottom', 'insideH'):
        el = OxmlElement('w:' + edge)
        el.set(qn('w:val'), 'single'); el.set(qn('w:sz'), '4')
        el.set(qn('w:space'), '0');    el.set(qn('w:color'), 'D0D7DE')
        borders.append(el)
    tblPr.append(borders)
    w = OxmlElement('w:tblW'); w.set(qn('w:w'), '9360'); w.set(qn('w:type'), 'dxa')
    tblPr.append(w)

def api_table(headers, rows, mono_cols=(0,), center_cols=()):
    """API-method table. col 0 of mono_cols renders Consolas 10pt, the rest 9pt."""
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.autofit = True
    for j, head in enumerate(headers):
        cell = table.rows[0].cells[j]; cell.text = head
        for r in cell.paragraphs[0].runs: r.bold = True
        if j in center_cols: cell.paragraphs[0].alignment = CENTER
    for i, row in enumerate(rows, start=1):
        for j, val in enumerate(row):
            cell = table.rows[i].cells[j]; cell.text = val
            para = cell.paragraphs[0]
            if j in mono_cols:
                for r in para.runs:
                    set_consolas(r, 10 if j == 0 else 9)
            if j in center_cols:
                para.alignment = CENTER
    _table_borders(table)
    return table

def trace_table(rows):
    table = doc.add_table(rows=len(rows), cols=2)
    for i, (a, b) in enumerate(rows):
        c0, c1 = table.rows[i].cells
        c0.text, c1.text = a, b
        c0.width = Emu(2971800); c1.width = Emu(2971800)
        if i == 0:
            for c in (c0, c1):
                for r in c.paragraphs[0].runs: r.bold = True
        else:
            for r in c1.paragraphs[0].runs: set_consolas(r, 9)
    _table_borders(table)
    return table

# ═════════════════════════════════════════════════════════════════════════════
# COVER
# ═════════════════════════════════════════════════════════════════════════════
img_p = doc.add_paragraph(); img_p.alignment = CENTER
img_p.paragraph_format.space_before = Emu(1524000)
img_p.add_run().add_picture(TMP_LOGO, width=Inches(3.12))

cover_line('Technical Document', 24, black=True, before=381000, after=76200)
cover_line('Manage Ticket Tracking — SDD', 18, black=True, after=254000)
cover_line('SOFTWARE DESIGN DOCUMENT', 11, after=38100)
cover_line('Manage Ticket Tracking · Sprint Board', 11)

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ═════════════════════════════════════════════════════════════════════════════
# BODY
# ═════════════════════════════════════════════════════════════════════════════
h(1, 'Software Design Document (SDD) — Manage Ticket Tracking')

# feature line (bold labels, plain paths) — mirrors SDD_ManageBacklog
fp = doc.add_paragraph()
def seg(t, bold=False):
    r = fp.add_run(t); r.bold = bold
seg('Feature:', True); seg(' Manage Ticket Tracking (Sprint board) ')
seg('Apex controller:', True)
seg(' force-app/main/default/classes/controller/manageTicketTracking/ManageTicketTrackingController.cls ')
seg('LWC:', True); seg(' force-app/main/default/lwc/manageTicketTracking/ ')
seg('Date:', True); seg(' 2026-06-21')

normal('Image references below follow the marker convention used across these design '
       'documents: the image file name is wrapped between ########################### lines, '
       'immediately before and after the embedded screenshot.')

# ── 1. Architecture Overview ──────────────────────────────────────────────────
h(2, '1. Architecture Overview')

ARCH = (
"┌─ manageTicketTracking (parent LWC) ─────────────────────────────────────────┐\n"
"│ Principal state: _sprint = { ...sprint, tickets[] }   (de-normalized)        │\n"
"│   each ticket carries: ticketType{ workflowTransitions[] }, ticketTypeName,  │\n"
"│   assigneeName, isEndStatus, key  + _statuses[] (the board lanes)            │\n"
"│ UI-only state (outside principal): _activeTicketViewId, drag state,          │\n"
"│   _searchTerm/_ticketSearchResults, _linkedTo/_subtasks/_history/_comments   │\n"
"│   target ids                                                                 │\n"
"│ Derived getters: columns · activeTicketViewModel · sprintDateRange ·         │\n"
"│   storyPointsPercent · isTicketViewOpen · ticketViewSearchOptions            │\n"
"│                                                                              │\n"
"│ Children                                                                     │\n"
"│   c-ticket-board-column (one per status): header(name+count) · cards ·       │\n"
"│      'Drop here' when isValidTarget · card click -> ticketviewopen ·         │\n"
"│      dragstart/drop -> status change                                         │\n"
"│   c-ticket-view (centered modal): summary · status · description ·           │\n"
"│      linked work items · sub-tasks · history · comments                      │\n"
"└──────────────────────────────────────────────────────────────────────────────┘\n"
"        │  imperative writes  +  @wire(cacheable=true) reads\n"
"        ▼\n"
"  ManageTicketTrackingController\n"
"     → StatusService · WorkflowService · ProjectService · TicketService · SprintService\n"
"     → Status__c · WorkflowTransition__c · Ticket__c · Sprint__c · Subtask__c · …"
)
mono(ARCH, size=9)

normal('Response envelope. Every controller method returns APIResponse { success, message, data }. '
       'The LWC treats success === false (or a thrown Apex error) as failure and toasts it via '
       '_showError; successful writes patch the principal state from the returned data, never from an '
       'optimistic draft.')
normal('Data shape used by the page (from loadManageTicketTrackingPage): '
       '{ status, workflows, sprint_tickets, members, ticketTypes, sprint }. buildSprintTickets nests '
       'each ticket’s type and that type’s workflow transitions onto the ticket, and derives isEndStatus '
       'from the statuses whose isEnd__c is true — so the board needs no further round-trips to compute '
       'columns or valid drop targets.')

# ── 2. API Calls ──────────────────────────────────────────────────────────────
h(2, '2. API Calls (Apex @AuraEnabled methods)')
lg = doc.add_paragraph()
lg.add_run('Legend: ')
r = lg.add_run('C'); r.bold = True
lg.add_run(' = cacheable=true (wire-friendly), ')
r = lg.add_run('I'); r.bold = True
lg.add_run(' = imperative (DML). All methods return APIResponse{success,message,data}.')

h(3, '2.1 Page bootstrap & search')
api_table(
    ['Method', 'Kind', 'Params', 'Returns (`data`)', 'LWC usage'],
    [
        ['loadManageTicketTrackingPage', 'C', 'projectId',
         '{status, workflows, sprint_tickets, members, ticketTypes, sprint}',
         '_loadData() imperative call on mount'],
        ['loadTicketBySearchTerm', 'C', 'projectId, searchTerm',
         'Ticket__c[] (SOSL, special chars escaped)', '@wire — ticket-view link search'],
        ['loadTicketLinkTypes', 'C', 'projectId', '{ticketLinkTypes}',
         '@wire — link-type combobox options'],
    ],
    mono_cols=(0, 2, 3), center_cols=(1,))

h(3, '2.2 Ticket status change (board move + ticket-view combo)')
api_table(
    ['Method', 'Kind', 'Params', 'Effect'],
    [
        ['changeTicketState', 'I', 'ticketId, fromStatusId, toStatusId',
         'requireTransitionAllowed + requireValidateFieldsPass; on pass writes CurrentState__c; '
         'if the new status is an end status bumps the sprint ended SP; returns {isEndStatus, updatedSprint}'],
    ],
    mono_cols=(0, 2, 3), center_cols=(1,))

h(3, '2.3 Ticket inline edits & links')
api_table(
    ['Method', 'Kind', 'Params', 'Effect'],
    [
        ['updateTicketSummary', 'I', 'ticketId, summary', 'inline summary edit; returns Ticket__c'],
        ['updateTicketDescription', 'I', 'ticketId, description', 'rich-text description edit; returns Ticket__c'],
        ['loadTicketLinkedTo', 'C', 'ticketId', '{ticketLinkTo} — the ticket’s links'],
        ['linkToTicket', 'I', 'fromTicketId, toTicketId, linkType', 'create link; returns {ticketLink} DTO'],
        ['createTicketLink', 'I', 'fromTicketId, toTicketId, linkType', 'create link (no DTO returned)'],
    ],
    mono_cols=(0, 2, 3), center_cols=(1,))

h(3, '2.4 Sub-tasks')
api_table(
    ['Method', 'Kind', 'Params', 'Effect'],
    [
        ['loadSubtasks', 'C', 'ticketId', 'Subtask__c[] for the ticket'],
        ['createSubtask', 'I', 'summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate',
         'create sub-task (summary required; rest optional); returns Subtask__c'],
    ],
    mono_cols=(0, 2, 3), center_cols=(1,))

h(3, '2.5 History & comments')
api_table(
    ['Method', 'Kind', 'Params', 'Effect'],
    [
        ['loadTicketHistory', 'C', 'ticketId', 'TicketHistoryDto[] (activity feed)'],
        ['loadTicketComments', 'C', 'ticketId', 'TicketCommentDto[] (newest first)'],
        ['createTicketComment', 'I', 'ticketId, message', 'add comment; returns TicketCommentDto'],
    ],
    mono_cols=(0, 2, 3), center_cols=(1,))

h(3, '2.6 Wires actually bound in manageTicketTracking.js')
bullet('@wire(loadTicketLinkTypes, { projectId: \'$_projectId\' }) → _ticketLinkTypes')
bullet('@wire(loadTicketLinkedTo, { ticketId: \'$_linkedToTargetTicketId\' }) → patches the linkedTo slice')
bullet('@wire(loadTicketBySearchTerm, { projectId: \'$_projectId\', searchTerm: \'$_searchTerm\' }) → _ticketSearchResults')
bullet('@wire(loadSubtasks, { ticketId: \'$_subtasksTargetTicketId\' }) → patches the subtasks slice')
bullet('@wire(loadTicketHistory, { ticketId: \'$_historyTargetTicketId\' }) → patches the history slice')
bullet('@wire(loadTicketComments, { ticketId: \'$_commentsTargetTicketId\' }) → patches the comments slice; '
       'the result is kept so re-expanding the same ticket re-fetches via refreshApex')
normal('All writes (changeTicketState, updateTicketSummary, updateTicketDescription, linkToTicket, '
       'createSubtask, createTicketComment) and the initial page load are imperative Apex calls inside '
       'handlers (then/catch/finally), toasting via _showSuccess / _showError.')

# ── 3. Sequence Flows ─────────────────────────────────────────────────────────
h(2, '3. Sequence Flows (key interactions)')

label('3.1 Page load')
mono(
"connectedCallback → loadStyle(aoTheme) → read localStorage.projectId\n"
" ├─ none    → render <c-choose-project>; on projectchosen → _projectId → _loadData()\n"
" └─ present → _loadData() → loadManageTicketTrackingPage(projectId)\n"
"      success  → set _statuses, statusOptions, memberOptions, epics, priorityOptions\n"
"               → _setSprintFromResponse → buildSprintTickets (nest type + transitions,\n"
"                 derive isEndStatus) → _sprint → columns getter renders the board\n"
"      no sprint→ _sprint = null → \"No active sprint\" banner (columns hidden)\n"
"      fail/throw→ errorMessage set → error toast, content hidden")

label('3.2 Drag-and-drop status change')
mono(
"card dragstart (c-ticket-board-column) → ticketdragstart{ ticketId, fromStatusId, ticketTypeId }\n"
"  parent: set _dragTicketId / _dragFromStatusId / _dragTicketType\n"
"        → getValidTargetStatusIds(type, fromStatus)  → _validTargetStatusIds\n"
"        → columns getter flags isValidTarget → only those columns show \"Drop here\"\n"
"drop on a column (accepted only when isValidTarget) → ticketdrop{ toStatusId }\n"
"  parent handleTicketDrop:\n"
"    toStatus == fromStatus                 → ignored\n"
"    validateChangeTicketState(id, to)      → client required-field guard\n"
"    findTransitionId(type, from, to)==null → \"This transition is not allowed by the workflow.\"\n"
"    else → changeTicketState(ticketId, fromStatusId, toStatusId)\n"
"            success → _applyTicketStateChange: move card + re-key; if isEndStatus,\n"
"                      fold updatedSprint.TotalEndedStoryPoint__c onto _sprint (SP line)\n"
"dragend → _clearDragState")

label('3.3 Open ticket view & inline edits')
mono(
"card click → ticketviewopen → handleOpenTicketView sets _activeTicketViewId\n"
"  isTicketViewOpen → true ; activeTicketViewModel = _findTicketById(id)\n"
"  render centered modal <c-ticket-view ticket={activeTicketViewModel}>\n"
"   ├─ ticketsummaryupdate     → updateTicketSummary     → _setTicketSummary\n"
"   ├─ ticketstatuschange      → changeTicketState       → _applyTicketStateChange\n"
"   ├─ ticketdescriptionupdate → updateTicketDescription → _setTicketDescription\n"
"   └─ closeticketview / backdrop click → clear _activeTicketViewId (+ wire targets)")

label('3.4 Lazy-load detail sections (expand → cacheable wire → patch slice)')
mono(
"ticketlinkedtoexpand → _linkedToTargetTicketId → loadTicketLinkedTo → _setTicketLinkedTo\n"
"subtasksexpand       → _subtasksTargetTicketId → loadSubtasks       → _setTicketSubtasks\n"
"tickethistoryexpand  → _historyTargetTicketId  → loadTicketHistory  → _setTicketHistory\n"
"ticketcommentsexpand → _commentsTargetTicketId → loadTicketComments → _setTicketComments\n"
"  re-expand same comments id → refreshApex(_commentsWireResult)\n"
"ticketsearch     → _searchTerm → loadTicketBySearchTerm → _ticketSearchResults (combobox)\n"
"ticketlinkcreate → linkToTicket   → _addTicketLink (append)\n"
"subtaskcreate    → createSubtask  → _addTicketSubtask (append)\n"
"ticketcommentcreate → createTicketComment → _addTicketComment (prepend, newest first)")

# ── 4. UI / UX Specification ──────────────────────────────────────────────────
h(2, '4. UI / UX Specification')

h(3, '4.1 Page load — sprint header, story-point line, status columns')
normal('On load the page shows the active sprint header (name and start → end date range, where the end '
       'is derived from start + Duration__c, plus the goal) and the Story Points line '
       '(ended / total SP and percent with a progress bar). Beneath it the board renders one column per '
       'project status (in order); each column header shows the status name and its ticket count, and holds '
       '0..many ticket cards. If there is no in_progress sprint a “No active sprint” banner replaces the '
       'board.')
figure('manage-ticket-tracking-default.png')

h(3, '4.2 Ticket card (tracking-card) & the Done (green) border')
normal('Each card (c-ao-ticket-item, variant="tracking-card") shows the ticket name, ticket type, summary, '
       'story points, and the assigned member name. A card whose current status is an end status '
       '(isEndStatus, from statuses with isEnd__c = true) carries data-end-status="true", which the column '
       'CSS renders as a 3px green left border (#00875A) to signal the ticket has finished. Clicking a card '
       'dispatches ticketviewopen and opens the ticket-view pop-up.')

h(3, '4.3 Drag-and-drop — type-aware drop targets')
normal('On drag start the system highlights only the columns reachable from the card’s current status for '
       'that ticket type (getValidTargetStatusIds reads the type’s own workflowTransitions); valid columns '
       'gain the valid-target style and a “Drop here” hint, and only they accept a drop. Because each '
       'ticket type points at its own workflow, a Story and a Task expose different reachable columns from '
       'the same status.')
figure('ticket-type-story-move.png')
figure('ticket-type-task-move.png')

h(3, '4.4 Ticket view pop-up (c-ticket-view)')
normal('Clicking a card opens the ticket view as a modal centered on the screen over a backdrop (clicking '
       'the backdrop or × closes it). It shows the TKT-id, summary, current status combo, description, and '
       'the Linked work items / Sub-tasks / History / Comments sections. Status changes here run the same '
       'workflow + validate-field gate as a board move.')
figure('ticket-view-pop-up.png')

h(3, '4.5 Edit description (rich text)')
normal('Clicking the description opens a rich-text editor with Save / Cancel; Save dispatches '
       'ticketdescriptionupdate → updateTicketDescription and patches the principal ticket from the response.')
figure('ticket-view-click-on-description.png')

h(3, '4.6 Linked work items')
normal('Expanding Linked work items fires loadTicketLinkedTo and lists the ticket’s links; an empty list '
       'shows “No linked items.” Clicking + reveals the add-link row: choose a Link type and search a target '
       'ticket (loadTicketBySearchTerm, min 2 characters), then Link (linkToTicket appends the returned link).')
figure('ticket-view-expand-ticket-view.png')
figure('ticket-ciew-click-plus.png')

h(3, '4.7 Sub-tasks')
normal('Expanding Sub-tasks fires loadSubtasks and lists them; empty shows “No subtasks.” Clicking + opens '
       'the create-sub-task form: Summary (required) plus optional Assignee, Current State, Start Date, '
       'Story Point, and a rich-text Description; Create calls createSubtask and appends the result.')
figure('ticket-view-expand-subtask.png')
figure('ticket-view-click-plus-subtask.png')

h(3, '4.8 History')
normal('Expanding History fires loadTicketHistory and shows the ticket’s activity feed (e.g. “Ticket '
       'created”), each entry with its author and timestamp.')
figure('ticket-view-expand-history.png')

h(3, '4.9 Comments')
normal('Expanding Comments fires loadTicketComments and shows the add-comment box and the existing comments '
       '(newest first), each with author and timestamp; posting calls createTicketComment and prepends it. '
       'Re-expanding the same ticket refreshes via refreshApex.')
figure('ticket-view-expand-comment.png')

# ── 5. State, Drag-and-Drop & Derived View Design ─────────────────────────────
h(2, '5. State, Drag-and-Drop & Derived View Design')
bullet('Principal state. One de-normalized _sprint = { ...sprint, tickets[] } (plus _statuses for the '
       'lanes). Every displayed value is a getter derived on read — columns, activeTicketViewModel, '
       'sprintDateRange, storyPointsPercent, isTicketViewOpen, ticketViewSearchOptions — never a parallel '
       'tracked field.')
bullet('De-normalized ticket shape. buildSprintTickets nests each ticket’s ticketType and that type’s '
       'workflowTransitions onto the ticket and precomputes ticketTypeName, assigneeName, and isEndStatus. '
       'The data is duplicated across tickets on purpose: the page only reads types/workflows, so there is '
       'no shared state to keep in sync.')
bullet('Derived columns. buildColumns(_statuses, tickets, _validTargetStatusIds) builds the lanes, fills '
       'each with the tickets whose CurrentState__c equals the status, and flags isValidTarget for the '
       'highlighted drop targets.')
bullet('Mutators only (R5). Writes go through named immutable mutators — _writeSprint / _patchTicket and '
       'the _set…/_add… family — with no inline spreads elsewhere; each ticket field update re-keys the '
       'card (newTicketKey) so LWC re-renders exactly that one card.')
bullet('Drag-and-drop. Valid targets are computed in the browser (getValidTargetStatusIds); the column '
       'only preventDefaults dragover / accepts drop when isValidTarget. handleTicketDrop ignores same-column '
       'drops, applies the client guards (validateChangeTicketState, findTransitionId), then calls '
       'changeTicketState; dragend always clears the drag state.')
bullet('No paging. Unlike the backlog, the board loads the single active sprint’s active tickets in one '
       'shot (ordered by Score__c) and distributes them across columns — there is no per-list paging.')

# ── 6. Error Handling & Loading ───────────────────────────────────────────────
h(2, '6. Error Handling & Loading')
bullet('isLoading gates the board (a c-ao-spinner shows while _loadData runs); shouldShowContent hides the '
       'board while loading or when an error is set.')
bullet('Every imperative call checks res.success — on false it calls _showError(res.message) and aborts the '
       'patch; thrown Apex errors are caught and surfaced via _errMsg (err.body?.message || fallback).')
bullet('Page-level load failure sets errorMessage and toasts, so the board is not shown with partial data.')
bullet('Server guards mirror the client: each @AuraEnabled method blank-checks required params and returns '
       'APIResponse(false, "<field> is required"), then DomainCorrectness.require* verifies referenced '
       'records before any DML; loadTicketBySearchTerm escapes SOSL/SOQL special characters.')

# ── 7. Traceability (SRS → API) ───────────────────────────────────────────────
h(2, '7. Traceability (SRS → API)')
trace_table([
    ('SRS', 'API call(s) / mechanism'),
    ('FR-1..FR-3 load & active sprint', 'loadManageTicketTrackingPage (SprintService.loadActiveSprint)'),
    ('FR-4/FR-5 sprint header & SP line', 'loadManageTicketTrackingPage → sprintDateRange, storyPointsPercent'),
    ('FR-6..FR-8 columns & cards', 'buildColumns / buildSprintTickets (derived from the page load)'),
    ('FR-9 Done green border', 'isEndStatus (statuses.isEnd__c) → data-end-status CSS'),
    ('FR-10..FR-14 move', 'getValidTargetStatusIds, findTransitionId (client) → changeTicketState'),
    ('FR-15..FR-17 open/close/summary', 'ticketviewopen, closeticketview, updateTicketSummary'),
    ('FR-18 status from view', 'changeTicketState'),
    ('FR-19 description', 'updateTicketDescription'),
    ('FR-20/FR-21 links', 'loadTicketLinkedTo, loadTicketLinkTypes, loadTicketBySearchTerm, linkToTicket'),
    ('FR-22/FR-23 sub-tasks', 'loadSubtasks, createSubtask'),
    ('FR-24 history', 'loadTicketHistory'),
    ('FR-25/FR-26 comments', 'loadTicketComments, createTicketComment'),
])

# ── save ──────────────────────────────────────────────────────────────────────
doc.save(OUT)
if os.path.exists(TMP_LOGO):
    os.remove(TMP_LOGO)


def prune_orphan_media(path):
    """Remove image parts (and their relationships) the body no longer references."""
    import re, shutil
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        # rIds actually referenced anywhere in the document XML (embed/link/id)
        referenced = set()
        rid_re = re.compile(r'r:(?:embed|link|id)="(rId\d+)"')
        for n in names:
            if n.startswith('word/') and n.endswith('.xml') and '/_rels/' not in n:
                referenced.update(rid_re.findall(z.read(n).decode('utf-8', 'ignore')))
        rels_name = 'word/_rels/document.xml.rels'
        rels = z.read(rels_name).decode('utf-8')
        rel_re = re.compile(r'<Relationship\b[^>]*?/>')
        drop_media = set()
        new_rels = rels
        for tag in rel_re.findall(rels):
            rid = re.search(r'Id="([^"]+)"', tag).group(1)
            typ = re.search(r'Type="([^"]+)"', tag).group(1)
            tgt = re.search(r'Target="([^"]+)"', tag).group(1)
            if typ.endswith('/image') and rid not in referenced:
                drop_media.add('word/' + tgt.replace('../', '').lstrip('/'))
                new_rels = new_rels.replace(tag, '')
        if not drop_media:
            return 0
        payload = {n: z.read(n) for n in names if n not in drop_media}
        payload[rels_name] = new_rels.encode('utf-8')
    tmp = path + '.tmp'
    with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as zo:
        for n, data in payload.items():
            zo.writestr(n, data)
    shutil.move(tmp, path)
    return len(drop_media)


removed = prune_orphan_media(OUT)
print('WROTE', OUT, '| pruned', removed, 'orphan image(s)')
