---
name: design
description: Use after /brief to transform a brief into a formal design document. Performs first-principles analysis, classifies constraints, grounds all recommendations in live library docs via Context7 and web search, then iterates until alignment. Writes .pipeline/design.md.
---

# DESIGN — First-Principles Design

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a software architect. Your output is a formal design document so rigorous that the adversarial review in /review has specific claims to verify and refute.

## Hard Rules

1. **Never recommend a library or pattern without grounding it first.** Call Context7 to get the live docs. Do not rely on training data alone. If Context7 is unavailable (tool not present in this session), document the library version and source URL manually in the Library Decisions table and flag the row as "Docs not verified — Context7 unavailable."
2. **Classify every constraint.** Hard constraints are non-negotiable. Soft constraints get flagged explicitly.
3. **Reconstruct from validated truths only.** Do not carry forward assumptions from the brief without validating them.
4. **Iterate until aligned.** Do not write the design doc until the user confirms alignment.

## Process

### Step 1: Read the brief and ground in codebase

Read `.pipeline/brief.md` in full. Extract:
- Primary language and LSP availability
- All hard and soft constraints
- Success criteria
- Non-goals

If the project already contains code (non-empty source directories), run `Glob("**/*")` with depth ≤ 3 and read the primary language config file (`package.json`, `go.mod`, `pyproject.toml`, or `*.csproj` — whichever exists at root) to get a file-tree overview. Use this to:
- Confirm the tech stack and existing architectural patterns
- Identify existing interfaces and conventions the design must follow
- Inform the constraints analysis in Step 2 with what already exists

### Step 2: Ground constraints and assumptions

For each constraint or assumption in the brief:
1. Is it actually a hard constraint or is it a soft preference stated as a constraint?
2. Does it conflict with any other constraint?

Flag soft constraints treated as hard: "This constraint is stated as hard, but [reason] suggests it may be flexible. Treating it as soft for this design."

### Step 3: Ground library and pattern choices in live docs

Before recommending any library, framework, or architectural pattern:
1. Call Context7 to resolve the library: `resolve_library_id` then `get_library_docs`
2. Verify the recommended API still exists in the current version
3. Note any gotchas or breaking changes in the docs

If Context7 is unavailable (tool not present in this session), skip steps 1-3 above and instead document the library version and source URL manually in the Library Decisions table, flagging the row as "Docs not verified — Context7 unavailable."

Use web search for:
- Known pitfalls not in official docs
- Community consensus on the approach
- Security advisories for the recommended stack

### Step 4: Check LSP if available

If the project language LSP is available in this session:
- Query existing symbol names and types relevant to the feature
- Identify existing interfaces the design must be compatible with
- Flag any naming conflicts with existing symbols

### Step 5: Reconstruct the optimal approach

Starting from validated truths only, reconstruct:
- What is the minimal implementation that satisfies all hard constraints?
- What is the recommended approach given the soft constraints?
- What are the key trade-offs between approaches?

### Step 6: Iterate with user

Present the design approach and ask: "Does this direction align with your intent?"

If no: ask what's wrong, adjust, repeat.
If yes: proceed to write the document.

### Step 7: Write the design document

Write `.pipeline/design.md` with this structure:

```markdown
# Design: [Feature Name]

**Date:** [YYYY-MM-DD]
**Brief:** `.pipeline/brief.md`

## Approach

[2-3 paragraphs: what we're building, why this approach, key decisions]

## Constraints Analysis

### Hard Constraints
| Constraint | Source | Impact |
|-----------|--------|--------|
| [constraint] | [brief/discovery] | [how it shapes the design] |

### Soft Constraints (flagged)
| Constraint | Why Flagged | Recommendation |
|-----------|-------------|----------------|
| [constraint] | [why it's soft] | [how to handle it] |

## Architecture

[Diagrams as ASCII or description. Component breakdown. Data flow.]

## Components

### [Component Name]
- **Responsibility:** [what it does]
- **Interface:** [inputs and outputs]
- **Dependencies:** [what it needs]

## Data Model

[Key data structures, schemas, or types]

## Error Handling Strategy

[How errors are surfaced, logged, and handled]

## Testing Strategy

[Unit test targets, integration test targets, what to mock]

## Library Decisions

| Library | Version | Reason | Docs Verified |
|---------|---------|--------|---------------|
| [lib] | [version] | [why] | Context7 ✓ |

## Non-Goals (confirmed)

[From brief — what this design explicitly excludes]

## Open Questions for /review

[Specific claims in this design that are worth adversarial scrutiny]
```

## Output

Confirm: "Design written to `.pipeline/design.md`. Run `/review` to stress-test it."
