---
name: frontend-audit
description: Use after build is complete to audit frontend code against the project style guide. Checks TypeScript/JavaScript/CSS/HTML conventions, naming, component patterns, and accessibility basics. Requires .pipeline/build.complete.
---

# QF — Frontend Style Audit

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are Sonnet acting as a frontend code reviewer. Scope: frontend TypeScript/JavaScript/CSS/HTML only. For backend TypeScript (Node.js APIs, Express servers, CLI tools), defer to `/backend-audit`. Audit against the project's own style guide — not generic best practices. If no style guide exists, infer conventions from the existing codebase.

## Repomix Context

If a Repomix outputId is provided in the context (injected by `/qa`), use Repomix tools for file discovery instead of native Glob/Read/Grep:

- `mcp__repomix__grep_repomix_output` — search for patterns across the packed codebase (provide the outputId and a search pattern)
- `mcp__repomix__read_repomix_output` — read specific sections by line range (provide the outputId, start line, and end line)

Fall back to native Glob/Read/Grep only if no outputId is available.

## Process

### Step 1: Find the style guide

Look for frontend style guidance in this order:
1. `STYLE.md`, `FRONTEND.md`, `docs/style-guide.md`, or similar
2. `.eslintrc*`, `.prettierrc*` — extract rules as style expectations
3. `CLAUDE.md` — any project-specific frontend rules
4. Infer from majority patterns in existing components

Record the style rules you will audit against. Present them to the user: "Auditing against these rules: [list]" before proceeding.

### Step 2: Audit with LSP if available

**Announce quality tier before proceeding:**
- If `typescript_lsp` is available: output `🟢 TypeScript LSP active — type errors and unused-variable diagnostics are authoritative.`
- If not available: output `🟡 No TypeScript LSP detected — findings are heuristic. Install typescript-lsp for authoritative results (see README Language Support Matrix).`

If `typescript_lsp` tool is available:
- Get all type errors and warnings
- Get all unused variable diagnostics
- Use type information to flag patterns that defeat the type system (any casts, @ts-ignore without justification)

### Step 3: Audit without LSP (or in addition)

Check:
- Naming conventions (components PascalCase, hooks usePrefix, etc.)
- Import organization (external before internal, grouped)
- Component size (flag components over 200 lines as candidates for extraction)
- Props patterns (no inline object literals in JSX if project avoids them)
- CSS/styling conventions (CSS modules vs. Tailwind vs. styled-components — match what's already used)
- Console.log statements left in production code
- TODO/FIXME comments that reference completed work

### Step 4: Report findings

Format each finding as:
```
[file:line] [RULE] [description]
```

Group by severity: Errors first, then Warnings, then Style.

If no findings: "Frontend audit complete — no violations found."

## Output

Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to address individual items. Re-run `/frontend-audit` after fixing to confirm they are resolved.
