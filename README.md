# leadcraft

English | [日本語](README.ja.md)

A Claude Code plugin that helps tech leads write and refine structured deliverables (plans / estimates / architecture decisions / design docs).

Output is a **[OKF (Open Knowledge Format)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) v0.1 conformant Knowledge Bundle** (YAML frontmatter + markdown directory tree) — readable by humans and AI agents alike, version-controllable with git, and portable across organizations.

The Story-layer tracker (storage backend) is **abstracted**: by default it runs as **zero-dependency local markdown** (OKF concept). GitHub Issue + Projects integration is opt-in (Phase 2).

## Features

- **5-level planning model**: Objective / Initiative / Epic / Story / Task
- **OKF-conformant knowledge bundle**: frontmatter with `type` / `title` / `description` / `tags` / `timestamp` / `resource`, `index.md` (table of contents) / `log.md` (history), bundle-absolute links
- **Tracker-agnostic**: Story operations are called through an abstract contract (`references/tracker-contract.md`); adapters (`references/backends/<provider>.md`) provide the concrete implementations. Adding a new tracker requires only one adapter file
- **Zero-config startup**: the default `local` provider requires no `gh` CLI or external services

## Hierarchy Model

| Level | Overview | Storage location |
|-------|----------|-----------------|
| Objective | High-level business/product goal (What / Why) | `<root>/<objective>/README.md` |
| Initiative | Major effort to realize an Objective (How). Aggregates the 10 Inception Deck questions | `<root>/<objective>/<initiative>/README.md` |
| Epic | Product backlog item grouping multiple Stories | `<root>/<objective>/<initiative>/<epic>/README.md` |
| Story | Smallest unit delivering user value | Tracker (default local: `<epic-dir>/<slug>.md`) |
| Task | Work items within a Story | Checklist in the Story body |

`<root>` is the `output.root_dir` in `.claude/leadcraft.md` (confirmed interactively on the first `compose-objective` run). The entire tree under it becomes the OKF Knowledge Bundle.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Skills (compose-* / quick-stories / …)      │
│  Call tracker operations via "abstract ops"  │
│  (create_item / set_field / add_comment …)   │
└───────────────┬─────────────────────────────┘
                │ references/tracker-contract.md (abstract contract)
        ┌───────┴────────┐
        ▼                ▼
  backends/local.md   backends/github.md
  (default, zero-dep)  (opt-in / Phase 2)
   Story = md          Story = Issue+Projects
        │
        ▼
  <root_dir>/ tree = OKF Knowledge Bundle
  (build-bundle maintains index.md / log.md / okf_version)
```

## Included Skills (Phase 1)

| Skill | Role |
|-------|------|
| [setup-baseline](skills/setup-baseline/SKILL.md) | Register Fibonacci reference points (2pt / 8pt) |
| [setup-dod](skills/setup-dod/SKILL.md) | Register and edit the shared Story Definition of Done |
| [compose-objective](skills/compose-objective/SKILL.md) | Interactively refine one Objective (KPIs / milestones) |
| [compose-initiative](skills/compose-initiative/SKILL.md) | Refine one Initiative (10 Inception Deck questions) |
| [compose-epic](skills/compose-epic/SKILL.md) | Refine one Epic (DoD / value hypothesis / user flow) |
| [brainstorm-stories](skills/brainstorm-stories/SKILL.md) | Roughly list Story candidates (`stories-draft.md`) |
| [compose-stories](skills/compose-stories/SKILL.md) | Detail-design Stories and register them to the tracker (default local) |
| [quick-stories](skills/quick-stories/SKILL.md) | Register Stories with minimum steps (for rough drafts) |
| [build-bundle](skills/build-bundle/SKILL.md) | Generate `index.md` / `log.md` and validate OKF conformance |

### Roadmap (Phase 2 and beyond)

The following skills and features are planned for gradual migration from the original plugin:

- `estimate-points` — PERT / simple estimation
- `identify-risks` — risk identification and reflection into PERT pessimistic values
- `review-stories` — draft quality gate
- `sync-stories` — upload local Stories → GitHub Issues
- `compose-hotfix` — filing emergency response items
- `convert-points-to-time` — point-to-time conversion
- `write-adr` / `write-dd` — ADR / Design Doc creation
- Full `github` tracker adapter implementation + Projects guardrail hook + estimation validation agent

## Installation

```bash
# Via marketplace (after public release)
/plugin marketplace add dskst/leadcraft
/plugin install leadcraft

# Or specify a local directory for development use
```

## Setup

```
/setup-baseline   # Register Fibonacci estimation reference points (2pt / 8pt)
/setup-dod        # Register the shared Story Definition of Done
```

Configuration is saved to `.claude/leadcraft.md` (**recommended to commit as a shared team config**). A template is at `skills/setup-baseline/templates/leadcraft.md`.

The default `tracker.provider: local` requires no additional dependencies. Only when using GitHub integration (Phase 2) is `gh` CLI authentication with the `project` scope required.

## Workflow (Phase 1 · local default)

```
setup-baseline / setup-dod
   → compose-objective → compose-initiative → compose-epic
   → (brainstorm-stories) → compose-stories / quick-stories (generates local md)
   → build-bundle (generates index.md / log.md / OKF conformance validation)
```

The generated tree is itself an OKF Knowledge Bundle and can be committed to git for sharing and distribution.

## OKF Conformance

Artifacts under `<root_dir>/` are treated as an OKF v0.1 Knowledge Bundle. For details of the conformance rules, see [`references/okf-conformance.md`](references/okf-conformance.md). The `build-bundle` skill validates the conformance conditions (all non-reserved `.md` files have parseable frontmatter with a non-empty `type`, etc.).

## License

MIT. See [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Contributions of new tracker adapters (GitLab / Jira / Backlog, etc.) are welcome.
