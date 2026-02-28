# Skill Rename Design

**Date:** 2026-02-28
**Goal:** Replace cryptic abbreviation-based skill names with plain-English names that communicate intent at a glance.

## Approach

Mixed strategy (option C): rename only the cryptic/abbreviated skills; leave self-explanatory names unchanged.

A rename touches: the `name:` field in the SKILL.md frontmatter, the skill directory, any cross-references inside other SKILL.md files, the gate hook (`hooks/pipeline_gate.sh`), the gate test suite (`hooks/test_gate.sh`), and `README.md`.

## Rename Mapping

| Old name | New name | Directory rename |
|----------|----------|-----------------|
| `arm` | `brief` | `skills/arm/` → `skills/brief/` |
| `ar` | `review` | `skills/ar/` → `skills/review/` |
| `pmatch` | `drift-check` | `skills/pmatch/` → `skills/drift-check/` |
| `qf` | `frontend-audit` | `skills/qf/` → `skills/frontend-audit/` |
| `qb` | `backend-audit` | `skills/qb/` → `skills/backend-audit/` |
| `qd` | `doc-audit` | `skills/qd/` → `skills/doc-audit/` |
| `denoise` | `cleanup` | `skills/denoise/` → `skills/cleanup/` |

## Unchanged Skills

`design`, `plan`, `build`, `qa`, `quick`, `init`, `git-workflow`, `security-review`, `status`

## Pipeline Flow After Rename

```
/brief → /design → /review → /plan → /build → /qa
                                              ├─ /frontend-audit
                                              ├─ /backend-audit
                                              ├─ /doc-audit
                                              ├─ /cleanup
                                              └─ /security-review

Standalone: /drift-check  /quick  /git-workflow  /init  /status
```

## Affected Files Per Rename

### Cross-references to update

| File | Old references | New references |
|------|---------------|---------------|
| `skills/build/SKILL.md` | `pmatch` | `drift-check` |
| `skills/qa/SKILL.md` | `denoise`, `qf`, `qb`, `qd` | `cleanup`, `frontend-audit`, `backend-audit`, `doc-audit` |
| `skills/design/SKILL.md` | `/arm`, `/ar` | `/brief`, `/review` |
| `skills/brief/SKILL.md` | `/design` | `/design` (unchanged) |
| `skills/review/SKILL.md` | `/ar`, `/plan` | `/review`, `/plan` |
| `skills/plan/SKILL.md` | `/ar`, `/build` | `/review`, `/build` |
| `skills/frontend-audit/SKILL.md` | `/qb`, `/qf` | `/backend-audit`, `/frontend-audit` |
| `skills/backend-audit/SKILL.md` | `/qf`, `/qb` | `/frontend-audit`, `/backend-audit` |
| `skills/cleanup/SKILL.md` | `/qb`, `/denoise` | `/backend-audit`, `/cleanup` |
| `hooks/pipeline_gate.sh` | `arm`, `ar`, `pmatch`, `qf`, `qb`, `qd`, `denoise` | `brief`, `review`, `drift-check`, `frontend-audit`, `backend-audit`, `doc-audit`, `cleanup` |
| `hooks/test_gate.sh` | all old names | all new names |
| `README.md` | all old names | all new names |

## Constraints

- Directory rename is a `git mv` (preserves history)
- The `name:` field in each SKILL.md frontmatter must match the new directory name exactly
- Gate hook case labels must match skill names exactly (Claude Code matches on skill name)
- All test cases in `test_gate.sh` must reference new names
- README pipeline diagram and command reference sections must reflect new names
