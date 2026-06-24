# leadcraft

English | [日本語](README.ja.md)

A Claude Code plugin that helps tech leads write and refine structured deliverables (plans / estimates / architecture decisions / design docs).

Output is a **[OKF (Open Knowledge Format)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) v0.1 conformant Knowledge Bundle** (YAML frontmatter + markdown directory tree) — readable by humans and AI agents alike, version-controllable with git, and portable across organizations.

The Story-layer tracker (storage backend) is **abstracted**: by default it runs as **zero-dependency local markdown** (OKF concept). GitHub Issue + Projects integration is available as an opt-in adapter.

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
  (default, zero-dep)  (opt-in)
   Story = md          Story = Issue+Projects
        │
        ▼
  <root_dir>/ tree = OKF Knowledge Bundle
  (build-bundle maintains index.md / log.md / okf_version)
```

## Included Skills

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
| [compose-hotfix](skills/compose-hotfix/SKILL.md) | File emergency-response Stories (`hotfix` label) |
| [estimate-points](skills/estimate-points/SKILL.md) | PERT / simple point estimation (Fibonacci) |
| [identify-risks](skills/identify-risks/SKILL.md) | Risk identification and reflection into PERT pessimistic values |
| [convert-points-to-time](skills/convert-points-to-time/SKILL.md) | Convert points to time and compute duration (JUAS formula) |
| [review-stories](skills/review-stories/SKILL.md) | Draft quality gate (6 perspectives) and graduation |
| [sync-stories](skills/sync-stories/SKILL.md) | Upload local Stories → GitHub Issues (github adapter, opt-in) |
| [write-adr](skills/write-adr/SKILL.md) | Architecture Decision Record creation |
| [write-dd](skills/write-dd/SKILL.md) | Design Doc creation (living document) |
| [build-bundle](skills/build-bundle/SKILL.md) | Generate `index.md` / `log.md` and validate OKF conformance |

The plugin also ships an `estimate-validator` agent (auto-launched after `estimate-points`) and two hooks: `notify-draft-added.sh` (prompts the estimate / review transition on `draft`) and `guard-project-field-mutation.sh` (hard-blocks destructive Projects field option mutation; active only under the `github` provider).

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

The default `tracker.provider: local` requires no additional dependencies. Only when using GitHub integration (opt-in) is `gh` CLI authentication with the `project` scope required.

## Workflow (local default)

```
setup-baseline / setup-dod
   → compose-objective → compose-initiative → compose-epic
   → (brainstorm-stories) → compose-stories / quick-stories / compose-hotfix (generates local md)
   → estimate-points (→ estimate-validator) → identify-risks → review-stories
   → (convert-points-to-time / write-adr / write-dd as needed)
   → build-bundle (generates index.md / log.md / OKF conformance validation)
   → sync-stories (upload to GitHub Issues; opt-in)
```

The generated tree is itself an OKF Knowledge Bundle and can be committed to git for sharing and distribution.

## OKF Conformance

Artifacts under `<root_dir>/` are treated as an OKF v0.1 Knowledge Bundle. For details of the conformance rules, see [`references/okf-conformance.md`](references/okf-conformance.md). The `build-bundle` skill validates the conformance conditions (all non-reserved `.md` files have parseable frontmatter with a non-empty `type`, etc.).

## License

MIT. See [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Contributions of new tracker adapters (GitLab / Jira / Backlog, etc.) are welcome.
