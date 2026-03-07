# QA Task Prompts

Use the Task tool to launch all 5 isolated audit tasks. Substitute `<code-snapshot-path>` and `<docs-snapshot-path>` with the paths from the snapshot map in the preamble. If no snapshot was acquired for a variant, omit the Repomix instruction from that task's prompt.

---

## Task 1 — Dead Code Removal

```
Follow the cleanup skill process: find dead code (unused symbols, unused imports, unreachable branches, commented-out code). .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Task 2 — Frontend Audit

```
Follow the frontend-audit skill process: audit frontend TypeScript/JavaScript/CSS/HTML against the project's own style guide (infer from existing code if no explicit guide). .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Task 3 — Backend Audit

```
Follow the backend-audit skill process: audit backend code (Go/Python/TypeScript/C#) against the project's own style guide. Check error handling, logging, naming, public API surface. .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with file:line references.
```

## Task 4 — Documentation Freshness

```
Follow the doc-audit skill process: check CHANGELOG.md for Keep a Changelog format compliance, presence of an [Unreleased] section, and coverage of the feature built in this pipeline. .pipeline/build.complete exists. Repomix docs snapshot available at <docs-snapshot-path> — use Grep/Read on it for file discovery. Report all findings.
```

## Task 5 — Security Review

```
Follow the security-review skill process: scan for OWASP Top 10 vulnerabilities relevant to this application type. .pipeline/build.complete exists. Repomix code snapshot available at <code-snapshot-path> — use Grep/Read on it for file discovery. Report all findings with severity, location, and remediation.
```
