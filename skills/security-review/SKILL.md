---
name: security-review
description: Use after build is complete to scan for OWASP Top 10 vulnerabilities. Checks injection, authentication, authorization, data exposure, and misconfiguration risks. Requires .pipeline/build.complete.
---

# SECURITY-REVIEW — OWASP Vulnerability Scan

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a security auditor. Scan for OWASP Top 10 vulnerabilities. Report findings with severity, location, and remediation. Do not fix — report.

**Repomix:** if `outputId` in context, use `mcp__repomix__grep_repomix_output(outputId, pattern)` and `mcp__repomix__read_repomix_output(outputId, startLine, endLine)` for discovery; else native Glob/Read/Grep.

## Process

### Step 1: Read build context

Read `.pipeline/brief.md` to understand:
- Primary language and framework
- What kind of application this is (API, web app, CLI, library)
- Any security constraints noted in the brief

### Step 2: Scan for OWASP Top 10

Check each category relevant to the application type:

**A01 — Broken Access Control**
- Routes/endpoints missing authorization checks
- Direct object references without ownership validation
- Admin endpoints accessible without role checks

**A02 — Cryptographic Failures**
- Sensitive data (passwords, tokens, PII) stored or transmitted without encryption
- Weak algorithms (MD5, SHA1 for passwords, ECB mode)
- Hardcoded secrets, API keys, or credentials in source

**A03 — Injection**
- SQL queries built with string concatenation instead of parameterized queries
- Shell command construction using unsanitized user input
- Template injection patterns

**A04 — Insecure Design**
- Rate limiting absent on authentication endpoints
- No input size limits on file uploads or request bodies
- Business logic that allows negative quantities, price manipulation

**A05 — Security Misconfiguration**
- Debug mode or verbose error messages in production code paths
- Default credentials or configuration left in place
- Overly permissive CORS settings (`Access-Control-Allow-Origin: *` on sensitive APIs)

**A06 — Vulnerable Components**
Attempt automated scanning first using Bash:
- Node.js: run `npm audit --json` and parse for high/critical findings
- Go: run `govulncheck ./...` if available
- Python: run `pip-audit --json` if available
- .NET: run `dotnet list package --vulnerable` if available
- Rust: run `cargo audit --json` if available

If the tool is unavailable or fails, note which tool was missing and output: `A06 [INFO] — automated scan unavailable for [language]. Run [tool] manually to check for vulnerable dependencies.` (e.g., `A06 [INFO] — automated scan unavailable for Rust. Run cargo audit manually to check for vulnerable dependencies.`) Do not make claims about specific CVEs without running an audit tool.

**A07 — Auth and Session Failures**
- Password hashing without salting
- Tokens without expiry
- Session IDs in URLs

**A08 — Software and Data Integrity Failures**
- Deserialization of untrusted data
- Auto-update mechanisms without signature verification

**A09 — Logging and Monitoring Failures**
- Authentication events (login, logout, failures) not logged
- Sensitive data appearing in logs

**A10 — SSRF**
- User-supplied URLs fetched server-side without allowlist validation

### Step 3: LSP-assisted taint analysis

If LSP is available, trace data flow from entry points (request handlers, CLI args, env vars) to sensitive sinks (SQL queries, shell exec, file paths, network calls) to identify injection paths.

### Step 4: Report findings

Format:
```
[SEVERITY] [OWASP Category] [file:line]
Description: [what the vulnerability is]
Risk: [what an attacker could do]
Remediation: [specific fix guidance]
```

Severity: CRITICAL / HIGH / MEDIUM / LOW / INFO

If no findings: "Security review complete — no OWASP Top 10 vulnerabilities found."

## Output

Report to user. No file written to `.pipeline/`.

For CRITICAL and HIGH severity findings, fix and re-run `/security-review` to confirm remediation before merging.
