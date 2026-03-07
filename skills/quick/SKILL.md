---
name: quick
description: Use when implementing small features, bug fixes, typo corrections, config tweaks, or any well-understood change that does not require the full pipeline. Completely independent of the brief/design/review/plan/build/qa flow. Use --deep to escalate to Opus for trickier problems.
argument-hint: [--deep] [task]
---

# QUICK — Fast Implementation

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`) by default. Use `--deep` to escalate to Opus for trickier problems.

You are Sonnet (or Opus with `--deep`) acting as a focused implementer. No pipeline, no artifacts, no ceremony. Read the task, understand the context, implement it correctly, hand back.

## Model Routing

- Default: you are Sonnet
- If `--deep` appears in the invocation args: escalate to Opus before proceeding. Announce: "Using Opus for this task (`--deep`)."

## Process

### Step 1: Parse and announce

Strip `--deep` from the task description if present. If the hook surfaced a pipeline state warning, repeat it visibly:

```
⚠ Note: [pipeline warning from hook]
Proceeding with /quick anyway.
```

### Step 2: Clarify if needed (max one question)

If the task description is ambiguous about what to change or where, prefer AskUserQuestion with options you derive from the task description — 2-4 options covering the plausible interpretations, plus `"Other / let me describe it"` as the last option. If structured prompts are unavailable in this runtime, ask one concise plain-text clarifying question instead. If it is clear enough to start, skip this step entirely. Do not ask multiple questions.

### Step 3: Read relevant context only

Do not read the whole codebase. Read only:
- The file(s) directly involved in the change
- Any files those files import from, if the change touches an interface
- If LSP is available, query the affected symbols for type information and callers

### Step 4: Implement

Make the change. Follow the existing patterns in the files you are touching — naming, error handling, formatting, imports. Do not introduce new patterns or refactor surrounding code unless the task explicitly asks for it.

### Step 5: Self-review

Before handing back, review your own diff:
- Did you break any callers of modified functions?
- Did you introduce any obvious edge cases that aren't handled?
- Is there anything you assumed that might not be true?

If you catch an issue, fix it silently. If you are genuinely uncertain about something, flag it.

### Step 6: Report and offer audit

Report what was done:

```
Done. Changed [N] file(s):
- [file]: [one-line description of what changed]

Before committing: if follow-up work will involve a destructive git operation (force-push, reset --hard, branch -D, or rebasing published commits), run /git-workflow first. Routine branch creation, first push, and PR flow use the normal git commands.
```

Prefer AskUserQuestion with:
  question: "Run a quick audit on the touched files?"
  header: "Audit"
  options:
    - label: "Yes"
      description: "Run LSP diagnostics and security spot-check on modified files"
    - label: "No"
      description: "Skip audit — done"

If structured prompts are unavailable in this runtime, ask the same yes/no question in plain text.

### Step 7: Optional audit (if yes)

Read `references/quick-audit.md` from this skill's base directory. Follow the LSP diagnostics, security spot-check, and test file check procedures on touched files only.

## Hard Rules

- No `.pipeline/` artifacts written — ever
- No full QA skills invoked (`/frontend-audit`, `/backend-audit`, `/doc-audit`, `/security-review`)
- Touch only the files required for the task
- One clarifying question maximum. Prefer AskUserQuestion with options derived from the task description; if it is unavailable, ask one concise plain-text question. If still unclear after one answer, make a reasonable assumption and note it
- Self-review is not optional — always do Step 5
