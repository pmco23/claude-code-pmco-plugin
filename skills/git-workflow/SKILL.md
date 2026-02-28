---
name: git-workflow
description: Use before branch creation, first push to remote, opening or merging a PR, and any destructive git operation (force-push, reset --hard, branch -D). Not required for routine commits on an already-established branch.
---

# GIT-WORKFLOW

## Role

You are enforcing git discipline before a significant git operation. Detect the project type, load the right workflow reference, verify all safety checks pass, then proceed. If any check fails, block or escalate — never silently skip a gate.

## Process

### Step 1: Detect project type

Scan the repo root for the following signals:

**Infra signals** (any match → three-environment workflow):
- Files matching `*.tf`, `*.tfvars`
- Files named `Chart.yaml`, `kustomization.yaml`, `kustomization.yml`
- Directories named `helm`, `terraform`, `kustomize`, `manifests`

**Code signals** (any match → trunk-based workflow):
- Files matching `*.ts`, `*.tsx`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.cs`

**If ambiguous** (both signals present or neither found):
- Ask the user: "Is this a code project (trunk-based: main only) or an infrastructure project (three-environment: development → preproduction → main)?"
- Do not proceed until confirmed.

### Step 2: Load the workflow reference

- Code project → read `references/code-path.md`
- Infra project → read `references/infra-path.md`

Load only one reference per operation. Apply it as the rule source for naming, commit format, PR strategy, and promotion flow.

### Step 3: Safety gate

Verify all of the following before proceeding:

- [ ] **Branch name** matches the selected path convention
- [ ] **Commit message** matches the selected path convention
  - If not: rewrite the message to conform before proceeding. Do not commit with a non-conforming message.
- [ ] **Operation is not destructive** (force-push, reset --hard, branch -D, rebase on published commits)
  - If destructive: stop and ask the user for explicit confirmation before proceeding.
  - If the user requests force-push to a protected branch repeatedly: escalate — do not comply silently.
- [ ] **Target branch is not protected** (main, master, development, preproduction) for direct push
  - If protected: block and warn — use a PR instead.
  - If the promotion path is unclear in a three-environment project: escalate rather than guess.

### Step 4: Proceed

Once all gate checks pass, perform the git operation.

## Output

- Detected project type (code / infra / confirmed by user)
- Workflow reference loaded (`references/code-path.md` or `references/infra-path.md`)
- Gate check results (pass / block / confirmed)
