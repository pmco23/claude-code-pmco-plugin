# /review — Adversarial Review

**Gate:** `.pipeline/design.md` must exist
**Writes:** `.pipeline/design.approved` (on loop exit)
**Models:** `strategic-critic` agent (Opus) + Codex via Codex MCP (code-grounded critique)
**Tools used:** Context7, filesystem

Dispatches Opus and Codex in parallel. Each critiques the design from a different angle. Lead Opus deduplicates findings, fact-checks each against the actual codebase, runs cost/benefit analysis, and outputs a structured report. Loop continues until no remaining findings warrant mitigation.

## Usage

```
/review
```
