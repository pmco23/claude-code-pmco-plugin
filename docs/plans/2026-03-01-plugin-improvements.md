# Plugin Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Raise the litmus-test scores of four low-scoring components by making quality tiers visible, reducing context overhead, tightening deterministic checks, and adding a go/no-go verdict to /qa.

**Architecture:** Four independent SKILL.md changes. No new files. No structural plugin changes. Each task is a targeted edit to one or more skill files. Tasks can be executed in any order.

**Tech Stack:** Markdown (SKILL.md edits). Test suite: `hooks/test_gate.sh` (44 tests). Verification: grep + test gate.

---

## Task 1: LSP quality-tier announcement in /cleanup, /frontend-audit, /backend-audit

**Files:**
- Modify: `skills/cleanup/SKILL.md`
- Modify: `skills/frontend-audit/SKILL.md`
- Modify: `skills/backend-audit/SKILL.md`

**Problem:** These three skills silently fall back to heuristic mode when LSP is unavailable. Users receive findings of unknown quality with no indication of whether they are authoritative (LSP-grounded) or heuristic (grep-pattern). The litmus test scores 2.5/5 without LSP.

**Fix:** Add an explicit quality-tier announcement at the start of the LSP detection step in each skill. The announcement must appear in the skill's output before any findings are reported.

### /cleanup — Step 2 edit

Find in `skills/cleanup/SKILL.md`:
```
### Step 2: Find dead code

**If LSP is available** for the project language, use it:
```

Replace with:
```
### Step 2: Find dead code

**Announce quality tier before proceeding:**
- If LSP is available: output `🟢 LSP active — dead code findings are authoritative.`
- If LSP is not available: output `🟡 No LSP detected — findings are heuristic (grep-pattern). Install the language LSP for authoritative results (see README Language Support Matrix).`

**If LSP is available** for the project language, use it:
```

### /frontend-audit — Step 2 edit

Find in `skills/frontend-audit/SKILL.md`:
```
### Step 2: Audit with LSP if available

If `typescript_lsp` tool is available:
```

Replace with:
```
### Step 2: Audit with LSP if available

**Announce quality tier before proceeding:**
- If `typescript_lsp` is available: output `🟢 TypeScript LSP active — type errors and unused-variable diagnostics are authoritative.`
- If not available: output `🟡 No TypeScript LSP detected — findings are heuristic. Install typescript-lsp for authoritative results (see README Language Support Matrix).`

If `typescript_lsp` tool is available:
```

### /backend-audit — Step 2 edit

Find in `skills/backend-audit/SKILL.md`:
```
### Step 2: Language-specific LSP audit
```

Replace with:
```
### Step 2: Language-specific LSP audit

**Announce quality tier before proceeding.** Check which LSP tools are available for the detected language:
- Go + `go_lsp`: output `🟢 Go LSP active — unused import and diagnostic findings are authoritative.`
- Python + `python_lsp`: output `🟢 Python LSP active — unused import findings are authoritative.`
- TypeScript + `typescript_lsp`: output `🟢 TypeScript LSP active — type error findings are authoritative.`
- C# + `csharp_lsp`: output `🟢 C# LSP active — nullable and unused-using findings are authoritative.`
- No LSP for detected language: output `🟡 No LSP detected for [language] — findings are heuristic. Install the language LSP for authoritative results (see README Language Support Matrix).`

```

### Verification

```bash
grep -A4 "quality tier" skills/cleanup/SKILL.md
grep -A4 "quality tier" skills/frontend-audit/SKILL.md
grep -A4 "quality tier" skills/backend-audit/SKILL.md
bash hooks/test_gate.sh 2>&1 | tail -3
```

Expected: each grep shows the 🟢/🟡 announcement block. Test suite: `44 passed, 0 failed`.

### Commit

```bash
git add skills/cleanup/SKILL.md skills/frontend-audit/SKILL.md skills/backend-audit/SKILL.md
git commit -m "feat: add LSP quality-tier announcement to cleanup, frontend-audit, backend-audit"
```

---

## Task 2: Slim /init — remove embedded template content

**Files:**
- Modify: `skills/init/SKILL.md`

**Problem:** /init is 238 lines. The bulk is embedded template content (full README.md, CHANGELOG.md, CONTRIBUTING.md, PR template verbatim). This content is what any model generates naturally — the skill's real value is the context-extraction protocol, the Overwrite/Skip/Merge safety gate, and the explicit-placeholder discipline. Embedding templates in the skill adds permanent context overhead every time the skill is loaded, while providing zero additional ground truth. Litmus test: 2/5.

**Fix:** Replace embedded templates with generation instructions. Keep the protocol (context extraction, Overwrite/Skip/Merge, placeholder discipline, Keep a Changelog / Conventional Commits / Conventional Branch references). Remove the verbatim template blocks.

### Steps 3–6 rewrite

Find Step 3 through Step 6 (the template generation steps). Replace the entire content of Steps 3–6 with:

```markdown
### Step 3–6: Generate files

For each file not skipped, generate content appropriate for the detected project. Apply these non-negotiable constraints:

**README.md:**
- Sections: project name, description, installation (language-appropriate command), usage, contributing, license
- Installation command must match detected language (npm install / go get / pip install / dotnet restore / [INSTALL_COMMAND])
- Use `[PLACEHOLDER]` for any field that cannot be detected from project context — never invent values

**CHANGELOG.md:**
- Must follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format exactly
- Must follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- Include `## [Unreleased]` section and an initial `## [0.1.0] - [today]` entry with `### Added\n- Initial release`

**CONTRIBUTING.md:**
- Branching: [Conventional Branch](https://conventional-branch.github.io/) — `<type>/<short-description>`, types: feat/feature/fix/bugfix/hotfix/chore/release
- Commits: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) — `<type>[scope]: <description>`
- PR process: branch from main, PR against main, fill PR template, request review
- Development setup: adapt to detected language/stack, or use `[SETUP_STEPS]` placeholder

**.github/pull_request_template.md:**
- Sections: Description, Type of Change (checklist), Testing (checklist), Verification Evidence, Checklist (branch name, commit format, CHANGELOG, docs)
- Type of Change checkboxes: Bug fix, New feature, Breaking change, Documentation, Refactor, Chore
- Testing checkboxes: Tests added/updated, All tests pass, Manual testing

Generate content, write the file, confirm to the user: "[filename] written."
```

### Verification

```bash
wc -l skills/init/SKILL.md
bash hooks/test_gate.sh 2>&1 | tail -3
```

Expected: line count well below 238 (target ~100 lines). Test suite: `44 passed, 0 failed`.

Read the file and confirm:
- Overwrite/Skip/Merge protocol is still present (Steps 1–2)
- Keep a Changelog, Conventional Commits, Conventional Branch references are present in generation instructions
- Placeholder discipline (`[PLACEHOLDER]`) is still specified
- No verbatim template blocks

### Commit

```bash
git add skills/init/SKILL.md
git commit -m "refactor: slim /init — replace embedded templates with generation instructions"
```

---

## Task 3: /doc-audit — tighten CHANGELOG check, flag narrative steps

**Files:**
- Modify: `skills/doc-audit/SKILL.md`

**Problem:** /doc-audit has four steps, but only Step 4 (CHANGELOG) is mechanically verifiable. Steps 2–3 (README accuracy, API doc accuracy) are narrative interpretation — the model reads docs and guesses whether they match code. This is what any model does without a structured skill. Litmus test: 2.5/5. Fix: (a) tighten Step 4 to be more specific and actionable, (b) add explicit "model-judgment" labels to Steps 2–3 so users know the confidence level of each finding category.

**Fix Part A — tighten Step 4 (CHANGELOG check):**

Find in `skills/doc-audit/SKILL.md`:
```
### Step 4: Check CHANGELOG
```

Replace the entire Step 4 block with:

```markdown
### Step 4: Check CHANGELOG (deterministic)

Read `CHANGELOG.md`. Apply these checks in order:

**Check 4a — Format compliance:**
- `## [Unreleased]` section must exist. If missing: flag `CHANGELOG [MISSING] — no ## [Unreleased] section. Required by Keep a Changelog format.`
- Entries under `## [Unreleased]` must use Keep a Changelog subsections: `### Added`, `### Changed`, `### Fixed`, `### Removed`, `### Deprecated`, `### Security`. If free-form prose is used instead: flag `CHANGELOG [FORMAT] — entries must use Keep a Changelog subsections (Added/Changed/Fixed/Removed).`

**Check 4b — Feature coverage (if plan exists):**
Read `.pipeline/plan.md` if it exists to identify the feature name and scope of what was built.
- Does `## [Unreleased]` contain at least one entry that corresponds to the feature described in the plan?
- Match by: feature name, key file names, or type of change (e.g., if plan adds an endpoint, look for an `### Added` entry mentioning that endpoint).
- If no matching entry: flag `CHANGELOG [MISSING] — no entry for "[feature name]" build. Add entries under ## [Unreleased] following the Added/Changed/Fixed/Removed format.`
- If `.pipeline/plan.md` does not exist (standalone run): check only 4a.

**Check 4c — Entry quality:**
For each entry under `## [Unreleased]`, verify it is a complete sentence describing a user-visible change, not a commit message or file path. If entries are commit-message style (e.g., "fix: null check"): flag `CHANGELOG [STYLE] — entries should be user-facing descriptions, not commit messages (e.g., "Fixed null pointer crash in UserCard" not "fix: null check").`
```

**Fix Part B — label Steps 2–3 as model-judgment:**

Find `### Step 2: Check README accuracy` and prepend:
```
### Step 2: Check README accuracy *(model-judgment — findings are heuristic)*
```

Find `### Step 3: Check API doc accuracy` and prepend:
```
### Step 3: Check API doc accuracy *(model-judgment — findings are heuristic)*
```

### Verification

```bash
grep -n "deterministic\|model-judgment\|Check 4a\|Check 4b\|Check 4c" skills/doc-audit/SKILL.md
bash hooks/test_gate.sh 2>&1 | tail -3
```

Expected: lines showing "deterministic" in Step 4 header, "model-judgment" in Steps 2 and 3 headers, and the three Check 4a/4b/4c labels. Test suite: `44 passed, 0 failed`.

### Commit

```bash
git add skills/doc-audit/SKILL.md
git commit -m "feat: tighten /doc-audit CHANGELOG check, label heuristic steps"
```

---

## Task 4: /qa — add overall verdict

**Files:**
- Modify: `skills/qa/SKILL.md`

**Problem:** /qa outputs section-by-section audit reports but gives no go/no-go signal. A user reading five audit outputs must synthesize a verdict themselves. The skill fails the "ground truth / determinism" litmus test (2.5/5) partly because there is no machine-readable summary of pass/fail. Fix: add an Overall QA Verdict section after all audits complete, in both parallel and sequential modes.

**Fix — Parallel Mode: after the consolidated report block**

Find in the Parallel Mode section:
```
Wait for all five to complete, then present a consolidated report:
```

After the report template block (the closing ``` of the markdown block), add:

```markdown
After presenting the consolidated report, append:

```markdown
## Overall QA Verdict

| Audit | Result |
|-------|--------|
| /cleanup | [PASS — no dead code found / FAIL — N items found] |
| /frontend-audit | [PASS / FAIL — N violations] |
| /backend-audit | [PASS / FAIL — N violations] |
| /doc-audit | [PASS / FAIL — N stale sections] |
| /security-review | [PASS / FAIL — N findings (X CRITICAL, Y HIGH)] |

**Overall: PASS** *(all audits clean)*
— or —
**Overall: FAIL** *([N] audits have findings requiring action)*
```

PASS requires: zero findings in /cleanup, /frontend-audit, /backend-audit, /doc-audit, and zero CRITICAL or HIGH findings in /security-review (MEDIUM/LOW do not block).
```

**Fix — Sequential Mode: after Step 5**

Find in Sequential Mode after step 5 (`5. Invoke the security-review skill...`). Add:

```markdown
After /security-review completes, present the Overall QA Verdict table (same format as parallel mode above) summarizing results from all five audits.

PASS criteria: same as parallel mode — zero findings across cleanup/frontend/backend/doc, zero CRITICAL or HIGH from security-review.
```

### Verification

```bash
grep -n "Overall QA Verdict\|PASS criteria\|Overall: PASS\|Overall: FAIL" skills/qa/SKILL.md
bash hooks/test_gate.sh 2>&1 | tail -3
```

Expected: lines showing the verdict section in both parallel and sequential contexts. Test suite: `44 passed, 0 failed`.

### Commit

```bash
git add skills/qa/SKILL.md
git commit -m "feat: add Overall QA Verdict table to /qa parallel and sequential modes"
```
