# Git Workflow Skill Design

**Date:** 2026-02-28
**Status:** Approved
**Source:** https://github.com/pmco23/opencode-agentic-orchestration-plugin/blob/main/skills/git-workflow/SKILL.md

---

## Purpose

Add a git-workflow skill to the plugin that enforces correct branching, commit message format, and safety checks before significant git operations. Available standalone and referenced (shallow) in /build and /quick.

---

## Approach

Approach B — adapted copy. Logic identical to the original; structure rewritten to match plugin style (Role section, numbered Process steps, Output section, Escalate If folded inline). Reference files copied verbatim.

---

## Files

- Create: `skills/git-workflow/SKILL.md` (adapted)
- Create: `skills/git-workflow/references/code-path.md` (verbatim)
- Create: `skills/git-workflow/references/infra-path.md` (verbatim)
- Modify: `skills/build/SKILL.md` — add git-workflow reference in agent prompt template
- Modify: `skills/quick/SKILL.md` — add git-workflow reference in Step 5

---

## Integration Points

**`/build` agent prompt template:** "Before committing your work, invoke git-workflow to verify branch naming, commit message format, and safety checks."

**`/quick` Step 5 (Self-review):** "Before committing, invoke git-workflow to verify branch naming, commit message format, and safety checks."

---

## Gate Behavior

No gate. `/git-workflow` is always available with no `.pipeline/` requirement.
