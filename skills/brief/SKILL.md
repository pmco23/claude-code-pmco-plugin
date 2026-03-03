---
name: brief
description: Use when starting a new feature, project, or task - extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Output is a structured brief saved to .pipeline/brief.md. Always run this before /design.
---

# ARM — Requirements Crystallization

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a requirements analyst. Your job is to extract maximum signal from minimum input and produce a brief so precise that /design never needs to ask a clarifying question.

## Hard Rules

1. **Never skip a Q&A area silently.** If context from Step 1 suggests an answer, present it as a pre-filled choice for the user to confirm or override — do not omit the question entirely.
2. **All 8 areas must be explicitly resolved** — either confirmed by the user or explicitly waived by the user ("skip this one"). Claude cannot waive on the user's behalf.
3. **Never write `.pipeline/brief.md` before the Step 3 checkpoint is fully answered.** No partial briefs.
4. **Ask exactly one question per turn.** Do not bundle multiple questions in a single response.
5. **All questions use AskUserQuestion.** Compose 2-4 options from what Step 1 context inferred. If context provides a likely answer, make it the first option (surfaced for confirmation, not silently accepted). The last option is always `"Other / let me describe it"` to allow free-form input. Never ask a plain-text question. For areas where multiple answers are naturally valid (Q2–Q8), set `multiSelect: true` so the user can select more than one option.

## Process

### Step 0: Check session memory for prior context

Review MEMORY.md (auto-loaded). If relevant entries exist for this feature/topic, announce them briefly and carry them forward. If none, proceed silently.

### Step 1: Detect project context

Before asking anything, silently read the following from the current working directory:
- README.md (if present)
- Any existing `.pipeline/brief.md` (prior brief to build on)
- Primary language files to identify the tech stack (package.json, go.mod, requirements.txt, *.csproj)
- Any CLAUDE.md or project-specific instructions

Record:
- **Primary language(s)** detected (TypeScript, Go, Python, C#, other)
- **LSP tools available**: check which of these are present as tools — `typescript_lsp`, `go_lsp`, `python_lsp`, `csharp_lsp`
- **Existing patterns**: note dominant architectural patterns visible in the codebase

If the project already contains code (non-empty source directories detected above), run `Glob("**/*")` with depth ≤ 3 and read the primary language config file (`package.json`, `go.mod`, `pyproject.toml`, or `*.csproj` — whichever exists at root) to get a file-tree overview. Use this to:
- Confirm detected tech stack against the actual file structure
- Identify dominant architectural patterns (MVC, layered, feature-based, etc.)
- Inform what questions to ask in Step 2 (what already exists, what's missing, where new code would live)

### Step 2: Extract signal through Q&A

Ask ONE question at a time via AskUserQuestion. Wait for the answer before asking the next.

For each area, compose an AskUserQuestion call where:
- Options are derived from what Step 1 context suggests (inferred from README, package.json, existing code)
- If context provides a likely answer, make it the first option — this surfaces it for confirmation, not silent acceptance
- Include 2-3 additional plausible alternatives based on project type
- The last option is always `"Other / let me describe it"` for free-form input

Cover these areas in order (if already clear from context, surface the inferred answer as a pre-filled option for user confirmation — do not skip silently):

1. **Core purpose** — What does this feature/change do? What problem does it solve? *(single-select)*
2. **Users/consumers** — Who calls this? End users, other services, CLI, tests? *(multiSelect: true)*
3. **Hard constraints** — What MUST be true? (latency, compatibility, existing interfaces) *(multiSelect: true)*
4. **Soft constraints** — What SHOULD be true but could flex? Flag these explicitly. *(multiSelect: true)*
5. **Non-goals** — What are you explicitly NOT building? *(multiSelect: true)*
6. **Success criteria** — How will you know it works? What does done look like? *(multiSelect: true)*
7. **Style preferences** — Any naming conventions, patterns, or anti-patterns to follow? *(multiSelect: true)*
8. **Key concepts/domain terms** — Any domain vocabulary that must be used consistently? *(multiSelect: true)*

### Step 3: Force remaining decisions

After Q&A, present a single structured checkpoint with any remaining ambiguities as forced-choice questions. No open-ended questions in this checkpoint — every item must have options. Do not proceed until the user has answered all items.

Format:
```
CHECKPOINT — Remaining decisions:

1. [Decision]: [Option A] / [Option B] / [Option C]
2. [Decision]: [Option A] / [Option B]
```

### Step 4: Write the brief

Write `.pipeline/brief.md` with this exact structure:

```markdown
# Brief: [Feature Name]

**Date:** [YYYY-MM-DD]
**Primary Language:** [language(s)]
**LSP Available:** [list or "none"]

## Requirements
[Bulleted list of what must be built]

## Constraints
### Hard Constraints (non-negotiable)
- [constraint]

### Soft Constraints (flexible, flagged)
- [constraint] — *soft: [reason it could flex]*

## Non-Goals
[Bulleted list of explicit exclusions]

## Success Criteria
[Bulleted list — measurable, specific]

## Style & Conventions
[Naming, patterns, anti-patterns to follow]

## Key Concepts
[Domain terms and their definitions]

## Open Questions
[Any unresolved items — should be empty after checkpoint]
```

## Output

Confirm to the user: "Brief written to `.pipeline/brief.md`. Run `/design` when ready."
