# Design: Documentation Cleanup

**Date:** 2026-03-02

## Problem

Three categories of issues across the plugin docs:

1. **Outdated content** — README pipeline diagram says `/git-workflow` is invoked by `/build` and `/quick`; that was removed. Three skill reference docs (`review.md`, `build.md`, `drift-check.md`) describe their models without naming the agents introduced in the last release.

2. **Redundant content** — `walkthrough.md` reset section is a 3-case subset of `workflows.md`'s 5-case version. Divergent subsets cause confusion about completeness.

3. **Historical noise** — `docs/plans/` has 37 completed plan files. Two cover a removed feature (`/grafana`). All are done. They describe a past state and add no user value.

## Approach

Fix all three categories. No restructuring. No content that has a unique home elsewhere is removed.

## Components

### 1. Delete `docs/plans/`

Remove the entire directory (37 files). Plans are done — the implemented state is recorded in CHANGELOG.md and in the actual skills/docs. The design docs in `agents-vs-skills.md` reference `docs/plans/2026-03-01-agents-vs-skills-design.md`; that reference will be removed from `agents-vs-skills.md` as part of this cleanup.

### 2. Fix `README.md` — pipeline diagram comment

**Current:**
```
 ├─ /git-workflow             # git discipline — always available, standalone or via /build and /quick
```

**Fixed:**
```
 ├─ /git-workflow             # git discipline — always available, standalone
```

Context: `/build` and `/quick` no longer invoke `/git-workflow`. Both were updated in a prior release to remove dead nested skill calls. The README diagram still reflects the old behavior.

### 3. Update `docs/skills/review.md` — name the agent

**Current Models line:**
```
**Models:** Opus (strategic critique) + Codex via Codex MCP (code-grounded critique)
```

**Updated:**
```
**Models:** `strategic-critic` agent (Opus) + Codex via Codex MCP (code-grounded critique)
```

### 4. Update `docs/skills/build.md` — name the agent

**Current Models line:**
```
**Models:** Opus (lead) + Sonnet (builders)
```

**Updated:**
```
**Models:** Opus (lead) + `task-builder` agent (Sonnet, per task group)
```

### 5. Update `docs/skills/drift-check.md` — name the agent

**Current Models line:**
```
**Models:** Sonnet (agent 1) + Codex via Codex MCP (agent 2) + Opus (lead)
```

**Updated:**
```
**Models:** `drift-verifier` agent (Sonnet) + Codex via Codex MCP + Opus (lead)
```

### 6. Update `docs/guides/walkthrough.md` — deduplicate reset section

Replace the 3-case reset block with a one-line reference to `workflows.md`, which has the complete 5-case version. The `.pipeline/` directory reference (artifact names, gitignore note) stays — that content does not exist in `workflows.md`.

**Remove:**
```bash
# Reset everything — start fresh from /brief
rm -rf .pipeline/

# Re-open from design phase (keep brief, redo design forward)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Re-open from review phase (keep design, redo /review forward)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete
```

**Replace with:**
```
See [Workflows → Resetting to a prior phase](workflows.md#resetting-to-a-prior-phase) for the complete reset reference.
```

### 7. Remove stale plan reference from `docs/guides/agents-vs-skills.md`

**Current last line:**
```
For the full design discussion that produced this document, see `docs/plans/2026-03-01-agents-vs-skills-design.md`.
```

**Remove** this line (the file it references will be deleted).

## Non-Goals

- Restructuring or merging any guide files
- Removing content that has no equivalent elsewhere (mode flags, language matrix in walkthrough)
- Updating the troubleshooting test gate count

## Success Criteria

- `docs/plans/` does not exist
- README pipeline diagram no longer mentions `/build` or `/quick` for `/git-workflow`
- `review.md`, `build.md`, `drift-check.md` name their respective agents
- `walkthrough.md` reset section links to `workflows.md` instead of duplicating a subset
- No broken links introduced
