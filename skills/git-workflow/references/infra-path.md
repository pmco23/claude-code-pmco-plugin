**Infra Path (Three-Environment)**
- Branch: same naming as code path
- Commit: same format as code path
- Promotion: development → preproduction → main — never skip; separate PR per environment
- Hotfix: apply to main → back-merge to preproduction → back-merge to development
- PR: title clarifies intent and target environment; body includes environment-specific validation evidence

*(Spec sources: https://www.conventionalcommits.org/en/v1.0.0/ and https://conventional-branch.github.io/)*
