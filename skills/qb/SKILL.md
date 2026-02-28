---
name: qb
description: Use after build is complete to audit backend code against the project style guide. Supports Go, Python, TypeScript, and C# backends. Checks naming, error handling patterns, package structure, and API conventions. Requires .pipeline/build.complete.
---

# QB — Backend Style Audit

## Role

You are Sonnet acting as a backend code reviewer. For TypeScript projects, audit backend TypeScript only (Node.js, APIs, CLI tools) — frontend TypeScript components are covered by `/qf`. Audit against the project's own style guide and language idioms — not generic linting rules. Match what the codebase already does.

## Process

### Step 1: Identify backend language and style guide

Read `.pipeline/brief.md` for the primary language. Check which LSP tools are available.

Look for style guidance:
1. `STYLE.md`, `BACKEND.md`, `docs/style-guide.md`
2. Language-specific config: `.golangci.yml`, `pyproject.toml`/`setup.cfg`, `.editorconfig`
3. `CLAUDE.md`
4. Infer from existing code patterns

Present the rules you will audit against before starting.

### Step 2: Language-specific LSP audit

**Go (if go_lsp available):**
- Unused variables and imports
- Error return values ignored (check for `_ = err`)
- Function signature conventions

**Python (if python_lsp available):**
- Unused imports and variables
- Type annotation consistency (if project uses mypy/pyright)
- Missing `__init__.py` where expected

**TypeScript backend (if typescript_lsp available):**
- Type errors and `any` usage
- Unused imports

**C# (if csharp_lsp available):**
- Unused usings
- Nullable reference warnings
- Naming violations (PascalCase methods, camelCase locals)

### Step 3: General backend audit

Check regardless of language:
- Error handling — are errors surfaced or swallowed?
- Logging — are log statements using the project's logger (not raw print/console)?
- Constants vs. magic numbers — flag unexplained literals
- Package/module naming — match project convention
- Public API surface — is anything public that should be internal?
- Dead endpoints — routes registered but never called from tests or documented

### Step 4: Report findings

Format:
```
[file:line] [RULE] [description]
```

Group by severity: Errors, Warnings, Style.

## Output

Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to address individual items. Re-run `/qb` after fixing to confirm they are resolved.
