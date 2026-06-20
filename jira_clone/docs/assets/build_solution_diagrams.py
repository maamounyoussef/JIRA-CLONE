# -*- coding: utf-8 -*-
"""Generate the three 'solution' diagrams referenced by docs/skills-path-report.md
(and embedded into Skills_Path_Architecture.docx):

  solution-1-flat-pool.png            - one flat pool of skills
  solution-2-group-skills-subskills.png - grouped into skills & sub-skills
  solution-3-orchestrator.png         - wrapped in an orchestrator

Pure matplotlib so it stays consistent with build_midpoint_chart.py and needs no
external assets."""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyBboxPatch, FancyArrowPatch

ASSETS = Path(r"c:/softreatail/project/app/jira_clone_v011/jira_clone/docs/assets")

BLUE = "#0b5394"
LIGHT = "#cfe2f3"
GREY = "#999999"
GREEN = "#38761d"
RED = "#cc0000"
ORANGE = "#e69138"


def _new_ax(title):
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis("off")
    ax.set_title(title, fontsize=13, color=BLUE, pad=10)
    return fig, ax


def _skill(ax, x, y, r=0.42, color=LIGHT, edge=BLUE, label=None):
    ax.add_patch(Circle((x, y), r, facecolor=color, edgecolor=edge, linewidth=1.4, zorder=3))
    if label:
        ax.text(x, y, label, ha="center", va="center", fontsize=8, color=BLUE, zorder=4)


# ---------------------------------------------------------------------------
# Solution 1 - one flat pool of skills
# ---------------------------------------------------------------------------
def solution_1():
    fig, ax = _new_ax("Solution 1 - one flat pool of skills")
    coords = [
        (1.3, 4.4), (2.9, 4.9), (4.5, 4.3), (6.1, 4.8), (7.7, 4.4), (9.0, 4.7),
        (1.6, 2.7), (3.2, 3.1), (4.8, 2.6), (6.4, 3.0), (8.0, 2.7), (9.1, 3.0),
        (2.2, 1.1), (3.9, 1.4), (5.6, 1.0), (7.3, 1.3), (8.6, 1.1),
    ]
    for (x, y) in coords:
        _skill(ax, x, y)
    # two overlapping skills the model can confuse
    _skill(ax, 4.5, 4.3, color="#f9cb9c", edge=ORANGE)
    _skill(ax, 4.8, 2.6, color="#f9cb9c", edge=ORANGE)
    ax.text(5.0, 0.2,
            "All skills sit at one level - the model must weigh every "
            "description at once; close ones (orange) collide.",
            ha="center", va="center", fontsize=9, color=GREY)
    fig.tight_layout()
    out = ASSETS / "solution-1-flat-pool.png"
    fig.savefig(out, dpi=160)
    plt.close(fig)
    print(f"wrote {out}")


# ---------------------------------------------------------------------------
# Solution 2 - grouped into skills & sub-skills
# ---------------------------------------------------------------------------
def solution_2():
    fig, ax = _new_ax("Solution 2 - group into skills & sub-skills")
    groups = [
        (1.7, 3.4, "skill A"),
        (5.0, 3.4, "skill B"),
        (8.3, 3.4, "skill C"),
    ]
    sub_offsets = [(-0.55, 0.55), (0.55, 0.55), (-0.55, -0.55), (0.55, -0.55)]
    for (gx, gy, name) in groups:
        ax.add_patch(FancyBboxPatch(
            (gx - 1.15, gy - 1.15), 2.3, 2.3,
            boxstyle="round,pad=0.02,rounding_size=0.18",
            facecolor="#eaf2fb", edgecolor=BLUE, linewidth=1.6, zorder=1))
        ax.text(gx, gy + 1.35, name, ha="center", va="center",
                fontsize=10, color=BLUE, weight="bold")
        for (dx, dy) in sub_offsets:
            _skill(ax, gx + dx, gy + dy, r=0.34)
    ax.text(5.0, 0.6,
            "Guides (sub-skills) are bundled under a skill, but selection is "
            "still 'by meaning' - close sub-skills can still mismatch.",
            ha="center", va="center", fontsize=9, color=GREY)
    fig.tight_layout()
    out = ASSETS / "solution-2-group-skills-subskills.png"
    fig.savefig(out, dpi=160)
    plt.close(fig)
    print(f"wrote {out}")


# ---------------------------------------------------------------------------
# Solution 3 - wrapped in an orchestrator
# ---------------------------------------------------------------------------
def solution_3():
    fig, ax = _new_ax("Solution 3 - wrap it in an orchestrator")
    # outer orchestrator frame
    ax.add_patch(FancyBboxPatch(
        (0.5, 0.7), 9.0, 4.4,
        boxstyle="round,pad=0.02,rounding_size=0.2",
        facecolor="#fff2e6", edgecolor=ORANGE, linewidth=2.2, zorder=0))
    ax.text(5.0, 4.75, "ORCHESTRATOR  (routes to the exact file - not 'by meaning')",
            ha="center", va="center", fontsize=10, color=ORANGE, weight="bold")

    groups = [
        (2.0, 2.4, "skill A"),
        (5.0, 2.4, "skill B"),
        (8.0, 2.4, "skill C"),
    ]
    sub_offsets = [(-0.5, 0.5), (0.5, 0.5), (-0.5, -0.5), (0.5, -0.5)]
    target = None
    for gi, (gx, gy, name) in enumerate(groups):
        ax.add_patch(FancyBboxPatch(
            (gx - 1.05, gy - 1.05), 2.1, 2.1,
            boxstyle="round,pad=0.02,rounding_size=0.16",
            facecolor="#eaf2fb", edgecolor=BLUE, linewidth=1.4, zorder=1))
        ax.text(gx, gy + 1.25, name, ha="center", va="center",
                fontsize=9, color=BLUE, weight="bold")
        for si, (dx, dy) in enumerate(sub_offsets):
            chosen = (gi == 1 and si == 1)
            _skill(ax, gx + dx, gy + dy, r=0.3,
                   color="#b6d7a8" if chosen else LIGHT,
                   edge=GREEN if chosen else BLUE)
            if chosen:
                target = (gx + dx, gy + dy)
    # routing arrow from the orchestrator label to the exact chosen sub-skill
    ax.add_patch(FancyArrowPatch(
        (5.0, 4.45), target, connectionstyle="arc3,rad=-0.2",
        arrowstyle="-|>", mutation_scale=16, color=GREEN, linewidth=1.8, zorder=5))
    ax.text(5.0, 0.95,
            "One entry point determines the exact sub-skill from the user's "
            "question - precise and scalable.",
            ha="center", va="center", fontsize=9, color=GREY)
    fig.tight_layout()
    out = ASSETS / "solution-3-orchestrator.png"
    fig.savefig(out, dpi=160)
    plt.close(fig)
    print(f"wrote {out}")


if __name__ == "__main__":
    solution_1()
    solution_2()
    solution_3()
