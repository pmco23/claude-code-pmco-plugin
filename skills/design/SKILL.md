---
name: design
description: Use after /brief to transform a brief into a formal design document. Performs first-principles analysis, classifies constraints, grounds all recommendations in live library docs via Context7 and web search, then iterates until alignment. Writes .pipeline/design.md.
disable-model-invocation: true
---

# DESIGN — First-Principles Design

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a software architect. Your output is a formal design document so rigorous that the adversarial review in /review has specific claims to verify and refute.

## Hard Rules

1. **Never recommend a library or pattern without grounding it first.** Call Context7 to get the live docs. Do not rely on training data alone. If Context7 is unavailable (tool not present in this session), document the library version and source URL manually in the Library Decisions table and flag the row as "Docs not verified — Context7 unavailable."
2. **Classify every constraint.** Hard constraints are non-negotiable. Soft constraints get flagged explicitly.
3. **Reconstruct from validated truths only.** Do not carry forward assumptions from the brief without validating them.
4. **Iterate until aligned.** Do not write the design doc until the user confirms alignment. Each iteration is one question — do not bundle multiple questions in a single response.
5. **Prefer structured prompts, but fail soft.** Provide 2-4 options covering the plausible answers; include `"Other / let me explain"` as the last option. If structured prompts are unavailable in this runtime, ask the same question in plain text with the options listed inline.

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

Present the design approach. Then prefer AskUserQuestion with:
  question: "Does this direction align with your intent?"
  header: "Design alignment"
  options:
    - label: "Yes, aligned"
      description: "Proceed to write the design document"
    - label: "Partially — one thing to adjust"
      description: "Name what needs to change; I'll adjust and re-present"
    - label: "No — fundamental issue"
      description: "Describe what's wrong; I'll rethink the approach"

If structured prompts are unavailable in this runtime, ask the same alignment question in plain text.

If "Partially" or "No": ask one follow-up question to identify the specific issue, preferring AskUserQuestion and falling back to a single plain-text question if needed. Then adjust and return to the top of this step.

### Step 7: Write the design document

Read `references/design-template.md` from this skill's base directory. Write `.pipeline/design.md` following that structure exactly.

## Output

Confirm: "Design written to `.pipeline/design.md`. Run `/review` to stress-test it."
