# -*- coding: utf-8 -*-
"""Rebuild the body of Skills_Path_Architecture.docx so it matches the
markdown report docs/skills-path-report.md verbatim. Title page is left
untouched."""
import os
import docx
from docx.shared import Inches
from docx.oxml.ns import qn

DOCS = r"c:\softreatail\project\app\jira_clone_v011\jira_clone\docs"
SRC = os.path.join(DOCS, "Skills_Path_Architecture.docx")
ASSETS = os.path.join(DOCS, "assets")

doc = docx.Document(SRC)
body = doc.element.body

# Keep the trailing sectPr in place (add_table needs it to compute width); new
# content is created via the API (which appends at the end of the body) and then
# moved to sit just before sectPr so the section properties stay last.
sectPr = body.find(qn('w:sectPr'))

def _relocate(el):
    sectPr.addprevious(el)

# Remove every body child from the "Abstract" heading onward (keep title page + the
# blank spacer paragraph that precedes Abstract).
children = list(body)
start = None
for i, ch in enumerate(children):
    if ch.tag == qn('w:p'):
        txt = ''.join(t.text or '' for t in ch.iter(qn('w:t')))
        if txt.strip() == 'Abstract':
            start = i
            break
assert start is not None, "Abstract heading not found"
for ch in children[start:]:
    if ch is sectPr:
        continue
    body.remove(ch)

# ---- helpers -------------------------------------------------------------
def h1(text):
    p = doc.add_paragraph(text, style='Heading 1'); _relocate(p._p)

def h2(text):
    p = doc.add_paragraph(text, style='Heading 2'); _relocate(p._p)

def h3(text):
    p = doc.add_paragraph(text, style='Heading 3'); _relocate(p._p)

def body_p(text, style='Body Text'):
    p = doc.add_paragraph(text, style=style); _relocate(p._p)

def lead(boldlead, rest, style='Body Text'):
    p = doc.add_paragraph(style=style)
    r = p.add_run(boldlead)
    r.bold = True
    p.add_run(rest)
    _relocate(p._p)
    return p

def bullet(text):
    try:
        p = doc.add_paragraph(text, style='List Bullet')
    except Exception:
        p = doc.add_paragraph('- ' + text, style='Body Text')
    _relocate(p._p)
    return p

def numbered(text):
    try:
        p = doc.add_paragraph(text, style='List Number')
    except Exception:
        p = doc.add_paragraph(text, style='Body Text')
    _relocate(p._p)
    return p

def quote(text):
    """Render a markdown blockquote (the example call-outs)."""
    try:
        p = doc.add_paragraph(text, style='Quote')
    except Exception:
        p = doc.add_paragraph(text, style='Body Text')
    _relocate(p._p)
    return p

def code(lines):
    p = doc.add_paragraph(style='Source Code')
    for i, ln in enumerate(lines):
        if i > 0:
            p.add_run().add_break()
        p.add_run(ln)
    _relocate(p._p)
    return p

def table(headers, rows):
    t = doc.add_table(rows=1, cols=len(headers))
    try:
        t.style = 'Table'
    except Exception:
        pass
    for c, htext in zip(t.rows[0].cells, headers):
        c.text = ''
        run = c.paragraphs[0].add_run(htext)
        run.bold = True
    for row in rows:
        cells = t.add_row().cells
        for c, val in zip(cells, row):
            c.text = val
    _relocate(t._tbl)
    return t

def image(filename, caption):
    """Embed an asset image; fall back to an italic caption if it is missing."""
    path = os.path.join(ASSETS, filename)
    if os.path.exists(path):
        p = doc.add_paragraph()
        run = p.add_run()
        run.add_picture(path, width=Inches(5.5))
        _relocate(p._p)
    cap = doc.add_paragraph()
    r = cap.add_run(caption)
    r.italic = True
    _relocate(cap._p)

# ---- Intro ---------------------------------------------------------------
body_p(
    "How force-app/skills/development/ is shaped to automate the Development "
    "phase of the Agile SDLC for the developer while adapting to this project's "
    "architecture and rules, and how that shape resolves three concrete "
    "challenges: reliability, consistency, maintainability.")

# ---- 1. The goal ---------------------------------------------------------
h1('1. The goal')
body_p("This skill set is not a grab-bag of recipes. It targets one "
       "intersection of the SDLC and one role, under one set of constraints.")
table(['Question', 'Answer'], [
    ['Which SDLC phase does this automate?', 'The Development phase of Agile.'],
    ['Who uses it?', 'The developer.'],
    ['For what?', 'To implement a task (the bug flow is reserved for later).'],
    ['Constrained by what?',
     "The project's architecture and rules — LWC architecture, Apex "
     "bulkification, soft-delete filter, required fields, controller -> Service "
     "-> APIResponse layering."],
])
body_p("Restated:")
body_p("Build a skill that automates the Development phase of the Agile SDLC "
       "for the developer, that adapts to this project's architecture, rules, "
       "and framework, and that delivers reliability, consistency, and "
       "maintainability without architectural overhead.")
body_p("The rest of this document is the architecture that meets that goal, "
       "organized by the three challenges it has to solve.")

# ---- 2. From a flat pool to an orchestrator -----------------------------
h1('2. From a flat pool to an orchestrator')
body_p("The current shape is the third design in a progression — each step "
       "fixes the problem the previous one left open.")

h2("Solution 1 — One flat pool of skills")
image("solution-1-flat-pool.png", "Figure: One flat pool of skills.")
bullet("Each circle is a single .md skill, all sitting at the same level.")
bullet("From the prompt the model picks one file — but two skills can overlap "
       "on a point.")
bullet("To avoid grabbing the wrong one, the developer must stay aware of every "
       "skill's description at once.")
lead("Doesn't scale. ", "Being aware of every skill is impossible once the "
     "system grows, and it costs more time on every prompt. The more skills you "
     "add, the noisier and less reliable selection gets.")

h2("Solution 2 — Group into skills & sub-skills")
image("solution-2-group-skills-subskills.png",
      "Figure: Group into skills and sub-skills.")
bullet("Circles are bundled: each big shape is one skill; the small circles "
       "become guides (sub-skills), each with its own activation point.")
bullet("A prompt activates a sub-skill inside the right skill instead of "
       "scanning a flat pile.")
lead("Better, but not enough. ", "Selection still happens by meaning — a "
     "semantic guess — so it can still pick the wrong file when two sub-skills "
     "are close.")

h2("Solution 3 — Wrap it in an orchestrator")
image("solution-3-orchestrator.png", "Figure: Wrap it in an orchestrator.")
bullet("The whole structure is enclosed in an orchestrator.")
bullet("It does not select \"by meaning\", so the overlap/ambiguity problem is "
       "eliminated.")
bullet("It determines the exact file to load from the specific user question.")
lead("Precise & scalable. ", "Routing points to one exact sub-skill, and it "
     "keeps working as the number of skills grows.")

# ---- 3. The three challenges --------------------------------------------
h1('3. The three challenges (with examples)')

h2("2.1 Reliability — the right skill must fire even when the user didn't name it")
lead("Problem. ", "A skill only fires if the model picks it. If the user's "
     "prompt doesn't name a downstream skill, it gets silently skipped.")
lead("Solution. ", "Make the call explicit inside the calling skill, so it "
     "cannot be missed regardless of wording.")
lead("Example. ", "The user says \"create a new parent LWC\" — nothing about "
     "CSS. The parent task-skill itself names the CSS handoff as a fixed step:")
quote("create-new-parent-lwc-component.md:207 — Step 4 — Optionally apply "
      "lwc-css-design")

h2("2.2 Consistency — same intent, same path, every time")
lead("Problem. ", "With N skills directly addressable, the user's wording "
     "decides which one fires. Same intent, different phrasings, different "
     "paths.")
lead("Solution. ", "One entry point — the orchestrator — and an AskUserQuestion "
     "flow that turns the prompt into a fixed set of answers, so the user's "
     "intent is captured with 100% certainty.")
lead("Example. ", "Any dev request enters "
     "agile-development-orchastrator-skill.md and answers two AskUserQuestion "
     "calls: bug vs. task, then A/B/C + parent/child. Three different phrasings "
     "of \"build a feature on a parent LWC\" all land on the same row:")
quote("B — create new functionality / parent -> "
      "add-interactive-with-data-persistance-functionality-in-pather.md")

h2("2.3 Maintainability — a new task can't fan out edits across every other task")
lead("Problem. ", "When several task-skills need the same sub-step, in-lining "
     "it in each one means every change has to touch every copy.")
lead("Solution. ", "Extract the shared sub-step into one file under "
     "task-skill/guide/ and have each task-skill call it.")
lead("Example. ", "Both "
     "add-interactive-with-data-persistance-functionality-in-pather.md and "
     "lwc-parent-event-handler-generator.md need to resolve \"which Apex method "
     "backs this?\". Instead of asking that interview manually in each file, both "
     "call guide/apex-method-resolution-guide.md — the three-branch interview "
     "(existing-known / existing-find / create-new) lives in exactly one file.")

# ---- 4. Adaptation -------------------------------------------------------
h1('4. Adaptation to project architecture and rules')
body_p("The orchestrator does not invent rules — it routes work into skills "
       "that already encode the project's rules. The chain of constraints, as "
       "they fire during a typical \"create a new parent LWC\" iteration:")
numbered("Orchestrator — classifies as task / option A / parent.")
numbered("create-new-parent-lwc-component — Step 0 mandates lwc-architecture "
         "end-to-end (page vs. child, principal state shape, localStorage keys, "
         "Apex methods, event names, sidecar utils / validator, meta.xml "
         "exposure).")
numbered("Per-iteration sub-skill (A -> functionality, B -> event handler) runs "
         "its full disciplined interview, then hands off to the shared "
         "Apex-method-resolution protocol when controller methods need to be "
         "resolved.")
numbered("Final Verification — the project-wide MANDATORY skills declared in "
         "CLAUDE.md are checked: bulkified Apex (apex-bulk-soql), soft-delete "
         "filter (soql-exclude-deleted), required fields per "
         "OBJECT_VALIDATION_LWC_APEX.md (object-required-fields), thin "
         "controller -> Service -> APIResponse layering (lwc-architecture).")
numbered("Optional CSS handoff — Step 4 asks whether to apply lwc-css-design so "
         "the new parent drops in next to manageBacklog / manageWorkflow "
         "without visual tuning.")
body_p("Every project-specific rule has exactly one home, and the orchestrator "
       "guarantees the rules are reached — not left to the model to remember.")

# ---- 5. Current file layout ---------------------------------------------
h1('5. Current file layout (for reference)')
code([
    "force-app/skills/development/",
    "├── agile-development-orchastrator-skill.md     <- single entry",
    "├── architecture/",
    "│   ├── lwc-architecture.md",
    "│   └── lwc-css-design.md",
    "├── contract/",
    "│   ├── object-required-fields-skill.md",
    "│   └── soql-exclude-deleted-skill.md",
    "├── guard/",
    "│   └── apex-governor-limit-guard.md",
    "├── performance/",
    "│   ├── apex-bulk-soql.md",
    "│   └── apex-method-monitor.md",
    "└── task-skill/",
    "    ├── add-functionality-in-child-lwc-component.md",
    "    ├── add-interactive-with-data-persistance-functionality-in-pather.md",
    "    ├── create-new-child-lwc-component.md",
    "    ├── create-new-parent-lwc-component.md",
    "    ├── lwc-parent-event-handler-generator.md",
    "    └── guide/",
    "        ├── apex-method-resolution-guide.md",
    "        ├── lwc-request-loading-guide.md",
    "        └── lwc-error-handling-guide.md",
])

doc.save(SRC)
print("saved", SRC)
