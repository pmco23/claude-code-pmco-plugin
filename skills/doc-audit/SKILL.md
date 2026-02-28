---
name: doc-audit
description: Use after build is complete to validate documentation freshness. Checks that README, API docs, inline comments, and changelogs reflect the current implementation. Requires .pipeline/build.complete.
---

# QD — Documentation Freshness

## Role

You are Sonnet acting as a documentation auditor. Find gaps between what the code does and what the docs say it does. Do not rewrite docs — report stale sections for human review.

## Process

### Step 1: Inventory documentation

Find all documentation files:
- `README.md` and any `docs/` directory
- API documentation files (`openapi.yaml`, `swagger.json`, etc.)
- Inline code comments for public interfaces
- `CHANGELOG.md` or `RELEASE-NOTES.md`
- Any generated documentation configs

### Step 2: Check README accuracy

For each claim in the README:
- Installation steps — do they still work with the current dependency list?
- Usage examples — do they reference functions/commands/APIs that still exist with those signatures?
- Configuration options — are all documented options still valid?
- Badges/links — are they pointing to the right places?

Flag anything that references a renamed, removed, or changed interface.

### Step 3: Check API doc accuracy

For each documented endpoint or public function:
- Does it still exist?
- Do the parameter names and types match?
- Do the return types/shapes match?
- Are new public interfaces missing from docs entirely?

### Step 4: Check CHANGELOG

Read `.pipeline/plan.md` if it exists to identify the feature name and scope of what was built in this session.

Check `CHANGELOG.md`:
- Is there an `## [Unreleased]` section?
- Does it contain entries that correspond to the feature described in the plan (matching the plan's feature name or the types of changes made)?
- If no matching entry: flag as `CHANGELOG MISSING — no entry for [feature name] build. Add entries under ## [Unreleased] following Keep a Changelog format (Added / Changed / Fixed / Removed).`
- If `.pipeline/plan.md` does not exist (standalone run): check only that `## [Unreleased]` has any content; flag if it is empty.

### Step 5: Report findings

Format:
```
[file:section] STALE — [what's wrong]
[file] MISSING — [what's not documented]
```

If no findings: "Documentation audit complete — all docs reflect current implementation."

## Output

Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to update stale documentation or add CHANGELOG entries. Re-run `/doc-audit` after fixing to confirm.
