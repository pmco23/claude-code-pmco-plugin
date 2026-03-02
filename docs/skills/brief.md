# /brief — Requirements Crystallization

**Gate:** None (always available)
**Writes:** `.pipeline/brief.md`
**Model:** Opus

Extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Detects your project language and available LSP tools. Ends with a forced-choice checkpoint to resolve remaining ambiguities before writing the brief.

## Usage

```
/brief
```

## Past context

Before Q&A begins, `/brief` searches past conversations for the stated feature or topic using `episodic-memory`. Found results are displayed visibly and carried forward into requirements extraction.
