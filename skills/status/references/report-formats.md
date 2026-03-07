# Status Report Formats

## Cold-Start Report (no pipeline active)

Output exactly:

```
No pipeline active.

Choose a workflow:

  Fast Track — small features, bug fixes, well-understood changes
    /quick [--deep]         implement directly, no artifacts

  Pipeline — new features, design-sensitive or complex changes
    /brief                  crystallize requirements  →  .pipeline/brief.md
      /design               first-principles design   →  .pipeline/design.md
        /review             adversarial review        →  .pipeline/design.approved
          /plan             atomic execution plan     →  .pipeline/plan.md
            /build          coordinated build         →  .pipeline/build.complete
              /qa           post-build audits

Always available (no pipeline required):
  /init          scaffold README, CHANGELOG, CONTRIBUTING, .gitignore
  /git-workflow  before destructive git operations
  /pack          Repomix snapshot — run before /qa or /quick --deep
  /reset         reset pipeline to a specific phase
  /status        this report
```

## Pipeline Report (artifacts exist)

```
Pipeline status: [phase name]

  brief.md         [✓ <age> | ✗ missing]
  design.md        [✓ <age> | ✗ missing]
  design.approved  [✓ <age> | ✗ missing]
  plan.md          [✓ <age> | ✗ missing]
  build.complete   [✓ <age> | ✗ missing]
  repomix-pack     [✓ <age> — code: <size>KB, docs: <size>KB, full: <size>KB | ⚠ <age> (stale) | ✗ missing]

Next: [next step]
```

### repomix-pack Row Rules

- Age < 1 hour: `✓ <age> — code: <size>KB, docs: <size>KB, full: <size>KB` (read sizes from `snapshots.<variant>.fileSize` in `repomix-pack.json`, convert to KB; omit any variant missing from the map)
- Age ≥ 1 hour: `⚠ <age> (stale — run /pack to refresh)`
- File absent (no `repomix-pack.json`): `✗ missing`
- If `packedAt` is absent or not a valid ISO timestamp: treat as stale and display `⚠ age unknown — run /pack to refresh`

## Next Step Prompt

After presenting the pipeline report, prefer AskUserQuestion with:
  question: "Run [next-step-skill] now?"
  header: "Next step"
  options:
    - label: "Yes, run [/skill-name]"
      description: "Invoke [/skill-name] immediately in this session"
    - label: "Not yet"
      description: "Dismiss — I'll run it when ready"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

Replace `[next-step-skill]` and `[/skill-name]` with the next step from the Phase → Next step lookup table in Step 3. If yes: invoke the skill by following its process.

## Manual Pipeline Reset

To reset the pipeline to a specific phase, remove artifacts manually:
- Full reset: `rm -rf .pipeline/`
- Re-open from design: `rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from review: `rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from plan: `rm .pipeline/plan.md .pipeline/build.complete`
- Re-open from build: `rm .pipeline/build.complete`
