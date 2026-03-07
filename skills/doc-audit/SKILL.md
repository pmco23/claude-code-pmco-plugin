---
name: doc-audit
description: Use after build is complete to audit CHANGELOG.md for format compliance, completeness, and feature coverage, and README.md for obvious stale placeholders or removed-feature drift. Requires .pipeline/build.complete.
---

# QD — Documentation Freshness

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a documentation auditor. Find gaps between what the code does and what the docs say it does. Do not rewrite docs — report stale sections for human review.

**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.docs.filePath`; if present, use Grep/Read on the docs snapshot for discovery. If docs variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files.

## Process

### Step 1: Find CHANGELOG

Look for `CHANGELOG.md` in the project root. If it does not exist: report `CHANGELOG [MISSING] — no CHANGELOG.md found. Run /init to generate one.` and stop.

### Step 2: Check CHANGELOG *(deterministic)*

Read `CHANGELOG.md`. Apply these checks in order:

**Check 2a — Format compliance:**
- `## [Unreleased]` section must exist. If missing: flag `CHANGELOG [MISSING] — no ## [Unreleased] section. Required by Keep a Changelog format.`
- Entries under `## [Unreleased]` must use Keep a Changelog subsections: `### Added`, `### Changed`, `### Fixed`, `### Removed`, `### Deprecated`, `### Security`. If free-form prose is used instead: flag `CHANGELOG [FORMAT] — entries must use Keep a Changelog subsections (Added/Changed/Fixed/Removed).`

**Check 2b — Feature coverage (if plan exists):**
Read `.pipeline/plan.md` if it exists to identify the feature name and scope of what was built.
- Does `## [Unreleased]` contain at least one entry that corresponds to the feature described in the plan?
- Match by: feature name, key file names, or type of change (e.g., if plan adds an endpoint, look for a `### Added` entry mentioning that endpoint).
- If no matching entry: flag `CHANGELOG [MISSING] — no entry for "[feature name]" build. Add entries under ## [Unreleased] following the Added/Changed/Fixed/Removed format.`
- If `.pipeline/plan.md` does not exist (standalone run): skip check 2b only. Check 2a still applies.

**Check 2c — Entry quality:**
For each entry under `## [Unreleased]`, verify it is a complete sentence describing a user-visible change, not a commit message or file path. If entries are commit-message style (e.g., "fix: null check"): flag `CHANGELOG [STYLE] — entries should be user-facing descriptions, not commit messages (e.g., "Fixed null pointer crash in UserCard" not "fix: null check").`

### Step 3: Report findings

Format:
```
[file] MISSING — [what's not present]
[file] FORMAT — [what structural rule was violated]
[file] STYLE — [what style convention was violated]
```

If no findings: "Documentation audit complete — no CHANGELOG or README freshness issues found."

### Step 4: README freshness (if README exists)

Read `README.md` if present. Check:
- Does the installation command match the detected language/package manager?
- Are there any `[PLACEHOLDER]` markers left unfilled?
- Are there obvious stale references (features explicitly removed per plan.md, old names)?

Flag each as:
```
README [STALE] — [description of what is outdated]
README [PLACEHOLDER] — [field name] has not been filled in
```

If no README: skip this step silently.

## Output

Report to user. No file written to `.pipeline/`. README findings (if present) appear after CHANGELOG findings.
