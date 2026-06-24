## Summary

<!-- What does this PR change and why? (1–3 bullet points) -->

- 
- 

## Type of change

<!-- Check all that apply -->

- [ ] New skill
- [ ] New tracker adapter
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactor / cleanup
- [ ] Other:

## OKF and tracker-contract impact

<!-- Does this PR change how artifacts are written to <root_dir>/? -->
- [ ] No OKF impact
- [ ] Adds / modifies frontmatter fields — conformance validated with `build-bundle`
- [ ] Changes abstract operation signatures in `tracker-contract.md`
- [ ] Adds / modifies a tracker adapter in `references/backends/`

## Checklist

- [ ] Skill body uses abstract operation names only (no hardcoded `gh …` commands)
- [ ] All generated `.md` files have parseable YAML frontmatter with a non-empty `type`
- [ ] `build-bundle` runs without conformance errors on a sample bundle
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] PR title follows Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
