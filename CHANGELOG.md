# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned (Phase 2)

- `estimate-points` skill — PERT / simple point estimation
- `identify-risks` skill — risk identification and reflection into PERT pessimistic values
- `review-stories` skill — draft quality gate
- `sync-stories` skill — upload local Stories to GitHub Issues
- `compose-hotfix` skill — filing emergency response items
- `convert-points-to-time` skill — point-to-time conversion
- `write-adr` skill — Architecture Decision Record creation
- `write-dd` skill — Design Doc creation
- Full `github` tracker adapter (`references/backends/github.md`) — GitHub Issue + Projects v2 integration
- Projects guardrail hook
- Estimation validation agent

## [1.0.0] - 2026-06-24

### Added

- Initial public release.
- **OKF v0.1 conformant knowledge bundle output** — all artifacts under `<root_dir>/` are generated as an OKF Knowledge Bundle (YAML frontmatter + markdown directory tree) with `type` / `title` / `description` / `tags` / `timestamp` / `resource` frontmatter fields.
- **Tracker abstraction** — Story operations are decoupled from any specific tracker via the abstract contract (`references/tracker-contract.md`). The `local` adapter (default, zero external dependencies) stores Stories as markdown files. The `github` adapter is planned for Phase 2.
- **`setup-baseline` skill** — register Fibonacci estimation reference points (2pt / 8pt).
- **`setup-dod` skill** — register and edit the shared Story Definition of Done.
- **`compose-objective` skill** — interactively compose one Objective with KPIs and milestones.
- **`compose-initiative` skill** — compose one Initiative aggregating the 10 Inception Deck questions.
- **`compose-epic` skill** — compose one Epic with DoD, value hypothesis, and user flow.
- **`brainstorm-stories` skill** — roughly list Story candidates into `stories-draft.md`.
- **`compose-stories` skill** — detail-design Stories and register them to the tracker (default: local).
- **`quick-stories` skill** — register Stories with minimum steps for rough drafts.
- **`build-bundle` skill** — generate `index.md` / `log.md` and validate OKF conformance.
- `references/okf-conformance.md` — OKF v0.1 conformance rules specific to this plugin.
- `references/tracker-contract.md` — abstract tracker operation contract.
- `references/backends/local.md` — default adapter: zero-dependency local markdown.

[Unreleased]: https://github.com/dskst/leadcraft/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dskst/leadcraft/releases/tag/v1.0.0
