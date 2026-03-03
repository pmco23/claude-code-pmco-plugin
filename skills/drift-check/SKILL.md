---
name: drift-check
description: Use to detect drift between a source-of-truth document and a target document or implementation. Dispatches Sonnet and Codex in parallel for independent claim extraction and verification. Requires .pipeline/plan.md. Used internally by /build and available standalone.
---

# PMATCH — Drift Detection

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a verification lead. Two independent agents extract claims from a source document and verify each against the target. You reconcile their findings and mitigate drift.

## Process

### Step 1: Identify source and target

If called from `/build`, receive source and target from the build context — skip the question.

If called standalone, use AskUserQuestion with:
  question: "What are the drift check inputs?"
  header: "Drift inputs"
  options:
    - label: "Default (plan vs. implementation)"
      description: "Source: .pipeline/plan.md — Target: current working directory"
    - label: "Custom"
      description: "Specify a different source document and/or target path"

If "Custom" is selected, ask the user to provide the source document path and/or target path.

### Step 2: Dispatch parallel verifiers

Issue both calls simultaneously in the same response turn — Agent 1 via the Task tool, Agent 2 via direct `mcp__codex__codex` call:

**Agent 1 — Sonnet Verifier**

Invoke the `drift-verifier` agent with this prompt:
```
Source of truth: [source document path]
Target: [target path or current working directory]
```

**Agent 2 — Codex Verifier (via Codex MCP)**

**If `mcp__codex__codex` is unavailable** (Codex MCP not connected), dispatch a second Task tool agent for Agent 2 with a structural focus: "List every file path and symbol name mentioned in [source document path]. For each, verify it physically exists in [target path] (use Glob and Grep). Report each as EXISTS or MISSING. Do not perform semantic analysis — structural presence only." This gives structural path/symbol verification as a complement to the drift-verifier's semantic claim analysis. Add `**Note:** Codex MCP unavailable — Agent 2 ran as Sonnet subagent (structural path verification).` immediately after the `**Date:**` line in the drift report.

Call `mcp__codex__codex` directly (do not dispatch a subagent) with:
- `prompt`: the following text, with `[source document path]` and `[target path or current working directory]` replaced by the values from Step 1:

```
You are verifying implementation drift.

Source of truth: [source document path]
Target: [target path or current working directory]

Step 1: Extract all verifiable claims from the source document.
A verifiable claim is a specific, checkable assertion: file paths that should exist, function names that should be implemented, test cases that should pass, acceptance criteria that should be met.

Step 2: For each claim, check whether the target satisfies it:
- EXISTS: the claim is satisfied
- MISSING: the claim is not satisfied — describe what's absent
- PARTIAL: partially satisfied — describe what's missing
- CONTRADICTED: the target actively contradicts the claim

Return a structured list: claim_id, claim, status (EXISTS/MISSING/PARTIAL/CONTRADICTED), evidence.
```
- `approval-policy`: `"never"`

Codex operates independently to surface any claims the Sonnet agent misses.

### Step 3: Reconcile findings

Once both agents return (the Task tool returns Agent 1's output as its result; `mcp__codex__codex` returns Agent 2's output inline as its tool result):

1. **Merge claim lists:** combine all claims both agents identified.
2. **Resolve conflicts:** where agents disagree on a claim's status, check the file/symbol directly to determine ground truth.
3. **Produce drift report:**

```markdown
# Drift Report

**Source:** [source path]
**Target:** [target]
**Date:** [YYYY-MM-DD]

## Summary
- Total claims: [N]
- Satisfied: [N]
- Missing: [N]
- Partial: [N]
- Contradicted: [N]

## Findings

| ID | Claim | Status | Evidence |
|----|-------|--------|---------|

## Recommended Actions
[Specific remediations for MISSING, PARTIAL, CONTRADICTED findings]
```

### Step 4: Mitigate if called from /build

If /drift-check is running as part of the /build post-build check:
- MISSING or CONTRADICTED findings → build does NOT complete; report to lead, lead unblocks or flags for re-build
- PARTIAL findings → lead judgment call: acceptable or must fix

If /drift-check is running standalone:
- Present report to user for judgment.
