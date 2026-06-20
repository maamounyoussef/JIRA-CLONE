"""Build docs/Skills_Path_Architecture.docx by cloning the cover-page layout
from report/Soft_Retail_Ticket_Score_updated.docx and appending the
skills-path report content.

The cover is preserved verbatim except for:
  - subtitle: "Ticket Ordering with String Scores" -> new subtitle
  - date:     "2026-05-24" -> "2026-06-01"

The original body is stripped after the cover (the last cover paragraph is
the Date), and the new body is appended using the document's built-in
Heading1 / Heading2 / BodyText / BlockText styles.
"""

from __future__ import annotations

import copy
import shutil
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from docx.shared import Pt

ROOT = Path(r"c:\softreatail\project\app\jira_clone_v011\jira_clone")
SRC  = ROOT / "report" / "Soft_Retail_Ticket_Score_updated.docx"
OUT  = ROOT / "docs"   / "Skills_Path_Architecture.docx"

NEW_SUBTITLE = "Skills Path Architecture for Agile Development"
NEW_DATE     = "2026-06-01"

# -------- Step 1. Clone the source so we inherit styles + logo --------------
OUT.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(SRC, OUT)

doc = Document(str(OUT))

# -------- Step 2. Patch subtitle and date on the cover ---------------------
for p in doc.paragraphs:
    txt = p.text.strip()
    if txt == "Ticket Ordering with String Scores":
        # rewrite while preserving the first run's formatting (Georgia italic 36)
        first_run = p.runs[0]
        for r in p.runs[1:]:
            r.text = ""
        first_run.text = NEW_SUBTITLE
    elif txt == "2026-05-24":
        first_run = p.runs[0]
        for r in p.runs[1:]:
            r.text = ""
        first_run.text = NEW_DATE

# -------- Step 3. Find the cover boundary and strip the old body -----------
# The cover ends at the Date paragraph. Everything after it is the original
# Ticket-Score report — delete it.
body = doc.element.body
sectPr = body.find(qn("w:sectPr"))  # section properties (page setup) – keep!

# Find index of the Date paragraph in the body
date_para_idx = None
paragraphs = doc.paragraphs
for i, p in enumerate(paragraphs):
    if p.text.strip() == NEW_DATE:
        date_para_idx = i
        break

if date_para_idx is None:
    raise RuntimeError("Could not locate the date paragraph on the cover.")

# Delete every paragraph and table after the date paragraph, except sectPr.
date_p_elem = paragraphs[date_para_idx]._p
to_remove = []
seen_date = False
for child in list(body):
    if child is date_p_elem:
        seen_date = True
        continue
    if not seen_date:
        continue
    if child is sectPr:
        continue
    to_remove.append(child)

for el in to_remove:
    body.remove(el)

# -------- Step 4. Append the report body -----------------------------------

_STYLE_NAMES = {s.name for s in doc.styles}

def _set_style(p, style_name: str):
    if style_name in _STYLE_NAMES:
        p.style = doc.styles[style_name]

def add_para(text: str = "", style: str = "Body Text", bold: bool = False, italic: bool = False):
    p = doc.add_paragraph()
    _set_style(p, style)
    if text:
        run = p.add_run(text)
        run.bold = bold
        run.italic = italic
    return p

def add_heading(text: str, level: int):
    p = doc.add_paragraph()
    _set_style(p, f"Heading {level}")
    p.add_run(text)
    return p

def add_bullet(text: str):
    p = doc.add_paragraph()
    _set_style(p, "Body Text")
    p.add_run("• " + text)
    return p

def add_runs(paragraph, segments):
    """segments: list of (text, {bold,italic,mono})."""
    for text, fmt in segments:
        r = paragraph.add_run(text)
        r.bold = fmt.get("bold", False)
        r.italic = fmt.get("italic", False)
        if fmt.get("mono"):
            r.font.name = "Consolas"
            r.font.size = Pt(10)

def add_code_block(text: str):
    """Render a fenced block using Source Code style (or Block Text fallback)."""
    p = doc.add_paragraph()
    if "Source Code" in _STYLE_NAMES:
        _set_style(p, "Source Code")
    else:
        _set_style(p, "Block Text")
    r = p.add_run(text)
    r.font.name = "Consolas"
    r.font.size = Pt(9)
    return p

def _apply_cell_borders(cell):
    from docx.oxml import OxmlElement
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement("w:tcBorders")
    for edge in ("top", "left", "bottom", "right"):
        b = OxmlElement(f"w:{edge}")
        b.set(qn("w:val"), "single")
        b.set(qn("w:sz"), "4")
        b.set(qn("w:color"), "808080")
        tcBorders.append(b)
    tcPr.append(tcBorders)

def add_table(header, rows):
    n_cols = len(header)
    table = doc.add_table(rows=1 + len(rows), cols=n_cols)
    # Use the template's "Table" style if present, else leave default.
    if "Table" in _STYLE_NAMES:
        try:
            table.style = doc.styles["Table"]
        except Exception:
            pass
    for j, h in enumerate(header):
        cell = table.rows[0].cells[j]
        cell.text = ""
        run = cell.paragraphs[0].add_run(h)
        run.bold = True
        _apply_cell_borders(cell)
    for i, row in enumerate(rows, start=1):
        for j, val in enumerate(row):
            cell = table.rows[i].cells[j]
            cell.text = ""
            cell.paragraphs[0].add_run(val)
            _apply_cell_borders(cell)
    return table

# Force the body to start on a fresh page
from docx.enum.text import WD_BREAK
pb = doc.add_paragraph()
pb_run = pb.add_run()
pb_run.add_break(WD_BREAK.PAGE)

# ====================== REPORT CONTENT ======================

add_heading("Abstract", 1)
add_para(
    "This report describes how the development skills directory in this "
    "Salesforce/LWC project is shaped to automate the Development phase of "
    "the Agile SDLC for the developer, while adapting to the project's "
    "architecture and rules. It is organized around the three concrete "
    "challenges the architecture has to solve — reliability, consistency, "
    "and maintainability — each illustrated with a project-specific "
    "example. The orchestrator owns classification only; each downstream "
    "task-skill owns its disciplined interview and code emission, and "
    "shared sub-steps are factored into task-skill/guide/ to avoid a "
    "cross-skill dependency mesh.",
    style="Abstract",  # display name matches style_id here
)

# ----- 1 -----
add_heading("1. The goal", 1)
add_para(
    "This skill set is not a grab-bag of recipes. It targets one "
    "intersection of the SDLC and one role, under one set of constraints."
)
add_table(
    header=["Question", "Answer"],
    rows=[
        ["Which SDLC phase does this automate?", "The Development phase of Agile."],
        ["Who uses it?", "The developer."],
        ["For what?", "To implement a task (the bug flow is reserved for later)."],
        ["Constrained by what?", "The project's architecture and rules — LWC architecture, Apex bulkification, soft-delete filter, required fields, controller → Service → APIResponse layering."],
    ],
)
add_para("Restated:")
add_para(
    "Build a skill that automates the Development phase of the Agile SDLC "
    "for the developer, that adapts to this project's architecture, rules, "
    "and framework, and that delivers reliability, consistency, and "
    "maintainability without architectural overhead.",
    italic=True,
)
add_para(
    "The rest of this document is the architecture that meets that goal, "
    "organized by the three challenges it has to solve."
)

# ----- 2 -----
add_heading("2. The three challenges (with examples)", 1)

# ----- 2.1 Reliability -----
add_heading("2.1 Reliability — the right skill must fire even when the user didn't name it", 2)
add_para("Problem. A skill only fires if the model picks it. If the user's prompt doesn't name a downstream skill, it gets silently skipped.")
add_para("Solution. Make the call explicit inside the calling skill, so it cannot be missed regardless of wording.")
add_para("Example. The user says \"create a new parent LWC\" — nothing about CSS. The parent task-skill itself names the CSS handoff as a fixed step:")
add_code_block(
    "create-new-parent-lwc-component.md (line 207)\n"
    "Step 4 — Optionally apply lwc-css-design"
)

# ----- 2.2 Consistency -----
add_heading("2.2 Consistency — same intent, same path, every time", 2)
add_para("Problem. With N skills directly addressable, the user's wording decides which one fires. Same intent, different phrasings, different paths.")
add_para("Solution. One entry point — the orchestrator — and an AskUserQuestion flow that turns the prompt into a fixed set of answers, so the user's intent is captured with 100% certainty.")
add_para("Example. Any dev request enters agile-development-orchastrator-skill.md and answers two AskUserQuestion calls: bug vs. task, then A/B/C + parent/child. Three different phrasings of \"build a feature on a parent LWC\" all land on the same row:")
add_code_block("B — create new functionality / parent →\nadd-interactive-with-data-persistance-functionality-in-pather.md")

# ----- 2.3 Maintainability -----
add_heading("2.3 Maintainability — a new task can't fan out edits across every other task", 2)
add_para("Problem. When several task-skills need the same sub-step, in-lining it in each one means every change has to touch every copy.")
add_para("Solution. Extract the shared sub-step into one file under task-skill/guide/ and have each task-skill call it.")
add_para("Example. Both add-interactive-with-data-persistance-functionality-in-pather.md and lwc-parent-event-handler-generator.md need to resolve \"which Apex method backs this?\". Instead of asking that interview manually in each file, both call shared/apex-method-resolution.md — the three-branch interview (existing-known / existing-find / create-new) lives in exactly one file.")

# ----- 3 -----
add_heading("3. Adaptation to project architecture and rules", 1)
add_para(
    "The orchestrator does not invent rules — it routes work into skills "
    "that already encode the project's rules. The chain of constraints, as "
    "they fire during a typical \"create a new parent LWC\" iteration:"
)
add_bullet("Orchestrator — classifies as task / option A / parent.")
add_bullet("create-new-parent-lwc-component — Step 0 mandates lwc-architecture end-to-end (page vs. child, principal state shape, localStorage keys, Apex methods, event names, sidecar utils / validator, meta.xml exposure).")
add_bullet("Per-iteration sub-skill (A → functionality, B → event handler) runs its full disciplined interview, then hands off to the shared Apex-method-resolution protocol when controller methods need to be resolved.")
add_bullet("Final Verification — the project-wide MANDATORY skills declared in CLAUDE.md are checked: bulkified Apex (apex-bulk-soql), soft-delete filter (soql-exclude-deleted), required fields per OBJECT_VALIDATION_LWC_APEX.md (object-required-fields), thin controller → Service → APIResponse layering (lwc-architecture).")
add_bullet("Optional CSS handoff — Step 4 asks whether to apply lwc-css-design so the new parent drops in next to manageBacklog / manageWorkflow without visual tuning.")
add_para("Every project-specific rule has exactly one home, and the orchestrator guarantees the rules are REACHED — not left to the model to remember.")

# ----- 4 -----
add_heading("4. Current file layout (for reference)", 1)
add_code_block(
    "force-app/skills/development/\n"
    "├── agile-development-orchastrator-skill.md     ← single entry\n"
    "├── architecture/\n"
    "│   ├── lwc-architecture.md\n"
    "│   └── lwc-css-design.md\n"
    "├── contract/\n"
    "│   ├── object-required-fields-skill.md\n"
    "│   └── soql-exclude-deleted-skill.md\n"
    "├── guard/\n"
    "│   ├── apex-governor-limit-guard.md\n"
    "│   
    "│   
    "├── performance/\n"
    "│   ├── apex-bulk-soql.md\n"
    "│   └── apex-method-monitor.md\n"
    "└── task-skill/\n"
    "    ├── add-functionality-in-child-lwc-component.md\n"
    "    ├── add-interactive-with-data-persistance-functionality-in-pather.md\n"
    "    ├── create-new-child-lwc-component.md\n"
    "    ├── create-new-parent-lwc-component.md\n"
    "    ├── lwc-parent-event-handler-generator.md\n"
    "    └── shared/\n"
    "        └── apex-method-resolution.md"
    "        ├── lwc-request-loading-guide.md\n"
    "        └── lwc-error-handling-guide.md\n
)

# ----- Save -----
doc.save(str(OUT))
print(f"OK -> {OUT}")
