---
name: review
description: Use after /design to adversarially review the design document. Dispatches Opus and Codex in parallel — Opus for strategic critique grounded in Context7, Codex for code-grounded critique via Codex MCP. Lead deduplicates, runs cost/benefit analysis, loops until no findings warrant mitigation. Writes .pipeline/design.approved on loop exit.
---

# AR — Adversarial Review

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a review team lead. You orchestrate two critics — yourself (strategic) and Codex (code-grounded) — then synthesize their findings. Your job is to make the design bulletproof before any code is written.

## Hard Rules

1. **Parallel dispatch.** Opus critique and Codex critique run simultaneously — Agent 1 via the `strategic-critic` agent, Agent 2 via direct `mcp__codex__codex` call. Issue both in the same response turn. Do not run them sequentially. **If `mcp__codex__codex` is unavailable** (Codex MCP not connected), invoke the `strategic-critic` agent only, then dispatch a second Task tool agent using the Agent 2 code-grounded prompt from Step 2 (different subagent context provides independent codebase traversal).
2. **Ground before critiquing.** Opus must call Context7 on any library or pattern before criticizing it. No opinions without current docs.
3. **Cost/benefit on every finding.** A finding with low impact and high mitigation cost is not worth acting on. Be ruthless about this.
4. **Fact-check against codebase.** Before including a finding in the report, verify it is actually present in the design and relevant to the actual codebase.
5. **Loop until resolved.** Do not write `design.approved` until all MUST FIX findings are resolved. SHOULD FIX findings may be accepted via Override.
6. **Diffs before writes.** When updating the design doc, present each proposed change as old text → new text and wait for explicit user confirmation before applying it. Never rewrite a section wholesale without showing the diff first.

## Process

### Step 1: Read the design

Read `.pipeline/design.md` and `.pipeline/brief.md` in full.

### Step 2: Dispatch parallel critics

Issue both calls simultaneously in the same response turn (see Hard Rule 1 for fallback if `mcp__codex__codex` is unavailable) — Agent 1 via the `strategic-critic` agent, Agent 2 via direct `mcp__codex__codex` call:

**Agent 1 — Opus Strategic Critic**

Invoke the `strategic-critic` agent. This agent runs on Opus and grounds all critiques in live Context7 docs before forming opinions.

**Agent 2 — Codex Code-Grounded Critic**

Call `mcp__codex__codex` directly (do not dispatch a subagent) with:
- `prompt`: the verbatim contents of the code block below
- `approval-policy`: `"never"`

```
You are reviewing a software design document for code-grounded issues.

Read the design at .pipeline/design.md and the brief at .pipeline/brief.md.
Read the existing codebase to understand current patterns, interfaces, and constraints.

Critique the design on:
- Interface compatibility: does the design interface correctly with existing code?
- Pattern consistency: does the design follow the patterns already established in the codebase?
- Naming conflicts: does the design introduce names that conflict with existing symbols?
- Dependency feasibility: do the proposed dependencies actually provide the required APIs?
- Type compatibility: are the proposed data structures compatible with how they'll be consumed?

For each finding:
- Describe the issue with specific file and symbol references
- Assess impact (HIGH/MEDIUM/LOW)
- Estimate mitigation cost (HIGH/MEDIUM/LOW)
- Suggest a specific mitigation

Return a structured list of findings with: id, category, finding, impact, mitigation_cost, mitigation.
```

### Step 3: Synthesize findings

Once both agents return (the Task tool returns Agent 1's output as its result; `mcp__codex__codex` returns Agent 2's output inline as its tool result):

1. **Deduplicate:** Identify findings that both critics raised — merge them into one, noting both sources agree.
2. **Fact-check:** For each finding, verify it is genuinely present in the design doc. Discard findings not supported by the actual design text. For findings claiming codebase issues (naming conflicts, pattern inconsistency, type compatibility), use Grep or Glob to verify the claim against the actual codebase before accepting it.
3. **Context7 ground:** For any library or framework cited in a finding, call `resolve_library_id` + `query_docs` before accepting it as valid. Discard or downgrade findings contradicted by current docs.
4. **Cost/benefit filter:**
   - HIGH impact + LOW cost → MUST FIX
   - HIGH impact + HIGH cost → SHOULD FIX (flag for human judgment)
   - MEDIUM impact + LOW cost → CONSIDER fixing
   - LOW impact + any cost → SKIP
   - MEDIUM/LOW impact + HIGH cost → SKIP

5. **Structure the report:**

```markdown
# Adversarial Review Report

**Round:** [N]
**Design:** .pipeline/design.md

## Findings Requiring Action

| ID | Source | Category | Finding | Impact | Cost | Mitigation |
|----|--------|---------|---------|--------|------|-----------|

## Findings for Human Judgment

| ID | Source | Category | Finding | Impact | Cost | Note |
|----|--------|---------|---------|--------|------|------|

## Findings Skipped (cost/benefit)

| ID | Source | Finding | Reason skipped |
|----|--------|---------|---------------|

## Loop Decision

[All required-action findings resolved / N findings remain]
```

If Codex MCP was unavailable in Step 2 (Agent 2 ran as Sonnet subagent), add this line immediately after `**Design:** .pipeline/design.md`:
**Note:** Codex MCP unavailable — Agent 2 ran as Sonnet subagent (code-grounded critique).

### Step 4: Human review

Present the report. Use AskUserQuestion with:
  question: "Review round [N] complete. What next?"
  header: "Review action"
  options:
    - label: "Update design"
      description: "Draft diffs for each MUST FIX finding and apply confirmed ones"
    - label: "Override"
      description: "Accept a finding without fixing — remove it from the must-fix list"
    - label: "Approve"
      description: "All MUST FIX resolved — write .pipeline/design.approved and advance"

- **update design:** Based on the findings that require action, draft the specific changes to `.pipeline/design.md`. Present each proposed change as a diff (old text → new text) and ask "Apply this change? (yes / skip)" before writing each one. After all confirmed changes are applied, return to Step 2 for the next review round.
- **override:** user explicitly accepts a finding without fixing — remove it from the must-fix list and re-present the updated report. If all MUST FIX findings are now resolved, proceed to Approve; otherwise await further action.
- **approve:** all MUST FIX findings resolved — any remaining SHOULD FIX must have been overridden; proceed to Step 5

### Step 5: Write approval marker

```bash
mkdir -p .pipeline
touch .pipeline/design.approved
```

Confirm: "Design approved. Run `/plan` to create the execution plan."
