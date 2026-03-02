---
name: cleanup
description: Use after build is complete to strip dead code, unused imports, unreachable branches, and commented-out code. Requires .pipeline/build.complete. Safe to run standalone or as part of /qa pipeline.
---

# DENOISE — Dead Code Removal

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are acting as a code cleaner. Remove confirmed dead code only. Do not refactor, rename, or restructure anything live.

## Repomix Context

If a Repomix outputId is provided in the context (injected by `/qa`), use Repomix tools for file discovery instead of native Glob/Read/Grep:

- `mcp__repomix__grep_repomix_output` — search for patterns across the packed codebase (provide the outputId and a search pattern)
- `mcp__repomix__read_repomix_output` — read specific sections by line range (provide the outputId, start line, and end line)

Fall back to native Glob/Read/Grep only if no outputId is available.

Note: Use Repomix tools for discovery and reading content only. File modifications (Step 4) must use native Edit/Write tools on the live files.

## Process

### Step 1: Identify project language

Attempt detection in order — stop as soon as a language is identified:

1. **Read `.pipeline/brief.md`** — if it exists, extract the primary language from it.
2. **Root-level config files** — if `brief.md` is absent, check the repo root:
   - `package.json` → TypeScript / JavaScript
   - `go.mod` → Go
   - `requirements.txt`, `pyproject.toml`, or `setup.py` → Python
   - `*.csproj` or `*.sln` → C#
   - `Cargo.toml` → Rust
3. **LSP tool availability** — if config files are inconclusive, check which LSP tools are available in this session as a hint.
4. **Unknown** — if none of the above yield a language, announce: "Language unknown — findings will be heuristic and will cover all file types."

Check which LSP tools are available as tools in this session (needed for Step 2 quality tier announcement regardless of detection path).

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
