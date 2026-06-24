# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (Phase 2 migration)

- **`estimate-points` skill** — PERT / simple point estimation (Fibonacci), updates frontmatter `points` / `estimation.*` and the "estimation details" body section via abstract tracker operations. Auto-launches the `estimate-validator` agent on completion.
- **`identify-risks` skill** — risk identification on the probability × impact axes, reflecting results into the PERT pessimistic (P) value; updates frontmatter `risks` / `risk_score` and the "risks and mitigations" body section.
- **`review-stories` skill** — draft quality gate across 6 perspectives; posts a human-readable summary comment, then removes the `draft` label.
- **`sync-stories` skill** — upload local Stories (OKF concepts / source of truth) to the `github` tracker; writes back `resource` / `tracker_ref` on success.
- **`compose-hotfix` skill** — file emergency-response Stories (`hotfix` label, `[Hotfix]` prefix).
- **`convert-points-to-time` skill** — convert estimated points to actual time (hours / days / person-months) and compute duration (months) from the JUAS software metrics formula.
- **`write-adr` skill** — Architecture Decision Record creation (Context / Decision / Consequences), output under a parent-hierarchy `adr/` directory or `<root>/adr/` for cross-objective decisions.
- **`write-dd` skill** — Design Doc creation (Google "Design Docs at Google" structure), maintained as a living document (overwrite in place, no supersedes).
- **`estimate-validator` agent** — multi-role review of Story estimates; auto-launched after `estimate-points`.
- **`hooks/notify-draft-added.sh`** — `PostToolUse` hook that prompts the transition to `estimate-points` / `review-stories` when a `draft` label is added (github provider; does not fire in local mode).
- **`hooks/guard-project-field-mutation.sh`** — `PreToolUse` hook that hard-blocks CLI / GraphQL mutation of Projects v2 Single Select field options (active only when `provider == github`).
- **`skills/compose-stories/templates/issue-story.md`** — GitHub Issue body template for the `github` provider.
- **Full `github` tracker adapter implementation** (`references/backends/github.md`) — GitHub Issue + Projects v2 integration, now complete. The skills above call it through abstract operations; the `local` provider remains the default source of truth.

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
