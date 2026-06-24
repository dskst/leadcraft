# Contributing to leadcraft

> **日本語概要**: このドキュメントは leadcraft への貢献方法を説明します。バグ報告・機能提案・新トラッカーアダプタの追加・スキル改善など、あらゆる形の貢献を歓迎します。

Thank you for your interest in contributing! This document explains how to develop, extend, and submit changes to leadcraft.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Repository Structure](#repository-structure)
3. [Skill Structure (SKILL.md frontmatter)](#skill-structure-skillmd-frontmatter)
4. [Adding a New Tracker Adapter](#adding-a-new-tracker-adapter)
5. [OKF Conformance Rules](#okf-conformance-rules)
6. [Submitting a Pull Request](#submitting-a-pull-request)
7. [Commit Convention](#commit-convention)

---

## Getting Started

leadcraft is a Claude Code plugin — no build step or runtime dependency is required to develop it.

**Prerequisites**

- [Claude Code](https://docs.anthropic.com/claude-code) installed
- Git

**Clone and install locally**

```bash
git clone https://github.com/dskst/leadcraft.git
cd leadcraft
# Point Claude Code to the local plugin directory
/plugin install /path/to/leadcraft
```

**Verify setup**

```
/setup-baseline
/setup-dod
```

Both commands should run without errors using the default `local` tracker provider.

---

## Repository Structure

```
leadcraft/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (name, version, license)
├── references/
│   ├── tracker-contract.md  # Abstract tracker operation contract
│   ├── okf-conformance.md   # OKF v0.1 conformance rules for this plugin
│   └── backends/
│       ├── local.md         # Default adapter: zero-dependency local markdown
│       └── github.md        # Phase 2 adapter: GitHub Issue + Projects
├── skills/
│   ├── setup-baseline/
│   │   ├── SKILL.md         # Skill definition
│   │   └── templates/
│   │       └── leadcraft.md # Config template
│   ├── setup-dod/
│   ├── compose-objective/
│   ├── compose-initiative/
│   ├── compose-epic/
│   ├── brainstorm-stories/
│   ├── compose-stories/
│   ├── quick-stories/
│   └── build-bundle/
├── README.md
├── README.ja.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
└── LICENSE
```

---

## Skill Structure (SKILL.md frontmatter)

Each skill lives in `skills/<skill-name>/SKILL.md`. The frontmatter declares metadata that Claude Code uses to register and invoke the skill.

**Minimal example**

```yaml
---
name: my-skill
description: One-sentence description shown in /help
triggers:
  - /my-skill
---
```

**Key frontmatter fields**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Slug used in skill invocation |
| `description` | Yes | Short description shown to users |
| `triggers` | Yes | Slash command(s) that invoke the skill |
| `args` | No | Named arguments accepted by the skill |
| `provider` | No | Declare if the skill is tracker-provider-specific |

**Implementation rules**

- Do not hardcode `gh …` or other provider-specific commands in the skill body. Use abstract operation names (`create_item`, `set_field`, etc.) as defined in `references/tracker-contract.md`.
- When provider-specific behavior is needed, write: _"see `<operation>` in `references/backends/<provider>.md`"_.
- Every artifact written to `<root_dir>/` must satisfy OKF conformance (see below).

---

## Adding a New Tracker Adapter

Tracker adapters live in `references/backends/<provider>.md`. Adding support for a new tracker (e.g., GitLab, Jira, Backlog) requires **one file**.

### Step 1 — Read the abstract contract

Read `references/tracker-contract.md` in full. Your adapter must implement every operation listed in **Section 2 (Tracker Operations)**:

| Operation | Signature |
|-----------|-----------|
| `create_item` | `(title, body, item_type, labels[]) → item_ref` |
| `update_item` | `(item_ref, {title?, body?}) → —` |
| `get_item` | `(item_ref) → {title, body, fields, labels}` |
| `list_items` | `({label?, status?, epic?}) → item_ref[]` |
| `add_comment` | `(item_ref, body) → —` |
| `set_field` | `(item_ref, field_name, value) → —` |
| `add_label` | `(item_ref, label) → —` |
| `remove_label` | `(item_ref, label) → —` |
| `ensure_label` | `(label, color?) → —` |
| `resource_uri` | `(item_ref) → URI or null` |

### Step 2 — Create `references/backends/<provider>.md`

Use the following template:

```markdown
# <Provider> Adapter

## Prerequisites

<!-- List any CLI tools, tokens, or environment variables required -->

## item_ref format

<!-- Describe the opaque identifier format for this provider -->
<!-- Example: GitHub uses Issue numbers (e.g. `123`) -->

## Operation implementations

### create_item

<!-- Concrete commands / API calls to create an item -->

### update_item

<!-- ... -->

### get_item

<!-- ... -->

### list_items

<!-- ... -->

### add_comment

<!-- ... -->

### set_field

<!-- field_name canonical vocabulary → provider-specific mapping -->

### add_label / remove_label / ensure_label

<!-- ... -->

### resource_uri

<!-- Return a URL the user can open, or null if not applicable -->

## Field name mapping

| Canonical name | <Provider> field |
|----------------|-----------------|
| `objective`    | ...             |
| `initiative`   | ...             |
| `epic`         | ...             |
| `points`       | ...             |
| `risk_score`   | ...             |
| `status`       | ...             |

## Label / status mapping

| Canonical concept | <Provider> representation |
|-------------------|--------------------------|
| `story`           | ...                      |
| `draft`           | ...                      |
| `quick`           | ...                      |
| `hotfix`          | ...                      |
| `ready`           | ...                      |
| `epic:<epic-id>`  | ...                      |

## Graceful degradation

<!-- Describe which operations may be skipped when config is incomplete,
     and what warning message is shown to the user -->
```

### Step 3 — Register the provider in `references/tracker-contract.md`

Add a row to the provider table in Section 1:

```markdown
| `<provider>` | opt-in | `references/backends/<provider>.md` |
```

### Step 4 — Update `.claude/leadcraft.md` template (if needed)

If the provider requires new config keys, add them to `skills/setup-baseline/templates/leadcraft.md` with comments.

### Step 5 — Open a Pull Request

Follow the PR guidelines below. Mention the new provider in the PR title, e.g. `feat: add GitLab tracker adapter`.

---

## OKF Conformance Rules

All artifacts written to `<root_dir>/` must conform to OKF v0.1. Full rules are in `references/okf-conformance.md`. Key requirements:

1. Every non-reserved `.md` file must have parseable YAML frontmatter.
2. Every frontmatter must contain a non-empty `type` field.
3. Reserved files (`index.md`, `log.md`) must follow the structure defined in the conformance doc.

The `build-bundle` skill validates these conditions. Run it after adding or modifying any artifact generation logic.

---

## Submitting a Pull Request

1. Fork the repository and create a branch from `main`.
2. Make your changes; keep diffs focused and minimal.
3. Run `build-bundle` against a sample bundle to verify OKF conformance is not broken.
4. Open a PR using the provided template (`.github/PULL_REQUEST_TEMPLATE.md`).
5. Ensure the PR description answers: what changed, why, and what OKF/tracker-contract impact (if any) there is.

---

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

**Types**

| Type | When to use |
|------|-------------|
| `feat` | New skill, new adapter, new capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance (deps, CI, tooling) |

**Scope** (optional): skill name or `adapter/<provider>`.

**Examples**

```
feat(adapter/gitlab): add GitLab tracker adapter
fix(compose-stories): handle missing epic frontmatter gracefully
docs: clarify OKF conformance conditions in CONTRIBUTING
```
