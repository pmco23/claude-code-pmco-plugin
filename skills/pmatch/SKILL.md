---
name: pmatch
description: Use to detect drift between a source-of-truth document and a target document or implementation. Dispatches Sonnet and Codex in parallel for independent claim extraction and verification. Requires .pipeline/plan.md. Used internally by /build and available standalone.
---

# PMATCH — Drift Detection

## Role

You are Opus acting as a verification lead. Two independent agents extract claims from a source document and verify each against the target. You reconcile their findings and mitigate drift.

## Process

### Step 1: Identify source and target

Ask the user (or receive from /build context):
- **Source of truth:** what document contains the claims? (default: `.pipeline/plan.md`)
- **Target:** what is being verified against? (default: current implementation in the working directory)

### Step 2: Dispatch parallel verifiers

Use the Task tool to launch two agents simultaneously:

**Agent 1 — Sonnet Verifier**

Dispatch a subagent with this prompt:
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

**Agent 2 — Codex Verifier (via OpenAI MCP)**

Dispatch a subagent using the OpenAI MCP Codex tool with the same prompt as Agent 1. Codex operates independently to surface any claims the Sonnet agent misses.

### Step 3: Reconcile findings

Once both agents return:

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

If /pmatch is running as part of the /build post-build check:
- MISSING or CONTRADICTED findings → build does NOT complete; report to lead, lead unblocks or flags for re-build
- PARTIAL findings → lead judgment call: acceptable or must fix

If /pmatch is running standalone:
- Present report to user for judgment.
