---
name: ar
description: Use after /design to adversarially review the design document. Dispatches Opus and Codex in parallel — Opus for strategic critique grounded in Context7, Codex for code-grounded critique via OpenAI MCP. Lead deduplicates, runs cost/benefit analysis, loops until no findings warrant mitigation. Writes .pipeline/design.approved on loop exit.
---

# AR — Adversarial Review

## Role

You are Opus acting as a review team lead. You orchestrate two critics — yourself (strategic) and Codex (code-grounded) — then synthesize their findings. Your job is to make the design bulletproof before any code is written.

## Hard Rules

1. **Parallel dispatch.** Opus critique and Codex critique run simultaneously via the Task tool. Do not run them sequentially.
2. **Ground before critiquing.** Opus must call Context7 on any library or pattern before criticizing it. No opinions without current docs.
3. **Cost/benefit on every finding.** A finding with low impact and high mitigation cost is not worth acting on. Be ruthless about this.
4. **Fact-check against codebase.** Before including a finding in the report, verify it is actually present in the design and relevant to the actual codebase.
5. **Loop until resolved.** Do not write `design.approved` until no remaining findings warrant mitigation.

## Process

### Step 1: Read the design

Read `.pipeline/design.md` and `.pipeline/brief.md` in full.

### Step 2: Dispatch parallel critics

Use the Task tool to launch two agents simultaneously:

**Agent 1 — Opus Strategic Critic**

Dispatch a subagent via the Task tool with `model: opus` and this prompt:
```
You are reviewing a software design document for strategic flaws.

Read the design at .pipeline/design.md and the brief at .pipeline/brief.md.

Before forming any opinion about a library or pattern:
1. Call Context7 to get the live docs for that library (resolve_library_id, then get_library_docs)
2. Verify your critique is based on current docs, not assumptions

Critique the design on:
- Architectural correctness: does the approach actually solve the stated problem?
- Constraint violations: does the design violate any hard constraints from the brief?
- Soft constraints flagged as hard: are any soft constraints being over-constrained?
- Missing concerns: error handling, observability, scalability, security surface
- Assumption validity: which assumptions in the design are unverified?
- Non-goal drift: is the design building anything that was explicitly excluded?

For each finding:
- Describe the issue
- Assess impact (HIGH/MEDIUM/LOW)
- Estimate mitigation cost (HIGH/MEDIUM/LOW)
- Suggest a specific mitigation

Return a structured list of findings with: id, category, finding, impact, mitigation_cost, mitigation.
```

**Agent 2 — Codex Code-Grounded Critic**

Dispatch a subagent that uses the OpenAI MCP Codex tool with this prompt:
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

Once both agents return:

1. **Deduplicate:** Identify findings that both critics raised — merge them into one, noting both sources agree.
2. **Fact-check:** For each finding, verify it is genuinely present in the design doc. Discard findings not supported by the actual design text.
3. **Cost/benefit filter:**
   - HIGH impact + LOW cost → MUST FIX
   - HIGH impact + HIGH cost → SHOULD FIX (flag for human judgment)
   - MEDIUM impact + LOW cost → CONSIDER fixing
   - LOW impact + any cost → SKIP
   - MEDIUM/LOW impact + HIGH cost → SKIP

4. **Structure the report:**

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

### Step 4: Human review

Present the report. Ask: "Update the design to address these findings, or override any? (update design / override / approve)"

- **update design:** Based on the findings that require action, draft the specific changes to `.pipeline/design.md`. Present each proposed change as a diff (old text → new text). Wait for the user to confirm each change, then apply them to `.pipeline/design.md`. Return to Step 2 for the next review round.
- **override:** user explicitly accepts a finding without fixing — remove it from the must-fix list and re-evaluate
- **approve:** all MUST FIX resolved, no outstanding SHOULD FIX — proceed to Step 5

### Step 5: Write approval marker

```bash
mkdir -p .pipeline
touch .pipeline/design.approved
```

Confirm: "Design approved. Run `/plan` to create the execution plan."
