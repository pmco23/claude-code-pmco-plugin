---
name: cleanup
description: Use after build is complete to strip dead code, unused imports, unreachable branches, and commented-out code. Requires .pipeline/build.complete. Safe to run standalone or as part of /qa pipeline.
---

# DENOISE — Dead Code Removal

## Role

You are Sonnet acting as a code cleaner. Remove confirmed dead code only. Do not refactor, rename, or restructure anything live.

## Repomix Context

If a Repomix outputId is provided in the context (injected by `/qa`), use Repomix tools for file discovery instead of native Glob/Read/Grep:

- `mcp__repomix__grep_repomix_output(outputId, pattern)` — search for patterns across the packed codebase
- `mcp__repomix__read_repomix_output(outputId, startLine, endLine)` — read specific sections by line range

Fall back to native Glob/Read/Grep only if no outputId is available.

## Process

### Step 1: Identify project language

Read `.pipeline/brief.md` to find the primary language. Check which LSP tools are available as tools in this session.

### Step 2: Find dead code

**Announce quality tier before proceeding:**
- If LSP is available: output `🟢 LSP active — dead code findings are authoritative.`
- If LSP is not available: output `🟡 No LSP detected — findings are heuristic (grep-pattern). Install the language LSP for authoritative results (see README Language Support Matrix).`

**If LSP is available** for the project language, use it:
- Request all unused symbol diagnostics
- Request all unreachable code diagnostics
- List unused imports via LSP

**If LSP is not available**, use static analysis:
- Search for symbols defined but never referenced (grep patterns)
- Look for commented-out code blocks (// TODO: remove, /* dead */, etc.)
- Find imports with no usages in the file
- Identify functions/methods with no callers (search for their name across codebase)

**Note:** If running as part of `/qa --parallel`, `/backend-audit` also checks unused imports for Go and TypeScript. Overlapping findings on that category are expected — both reports are correct.

### Step 3: Confirm before removing

Present the dead code list to the user before making any changes:

```
Dead code found:
- [file:line] — [symbol/description] — [reason: unused/unreachable/no callers]
```

Ask: "Remove all of these? (yes / review each / skip)"

### Step 4: Remove confirmed dead code

For each confirmed item:
- Remove the dead symbol or block
- Remove any imports that become unused as a result
- Do not touch surrounding code

### Step 5: Verify

After removal, confirm no tests are broken:
- Check if there are test files (look for test/, tests/, *_test.go, *.test.ts, etc.)
- If tests exist, remind the user to run them: "Run your test suite to confirm no regressions."

## Output

Report: "Removed [N] dead code items across [M] files."

If items were skipped (user chose "review each"), use `/quick` to address them individually. Re-run `/cleanup` to confirm.
