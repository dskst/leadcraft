# トラッカーアダプタ: github（opt-in / Phase 2）

`tracker.provider: github` のときに使うアダプタ。Story を **GitHub Issue + GitHub Projects (v2)** として扱う。

> **ステータス: Phase 2（未移植）**
> 本 OSS 版は `local` を既定とし、まず外部依存ゼロで動くことを優先している。
> github アダプタの完全な実装（Issue / Projects / フィールド / ラベルの具体手順）は次フェーズで移植する。
> 現時点で `tracker.provider: github` を選んだ場合、スキルはこのスタブを参照し、未実装の操作は
> 「Phase 2 で提供予定。当面は `local` を使い `sync-stories`（Phase 2）でアップロードする」と案内する。

抽象操作の定義は `references/tracker-contract.md` を参照。

## 前提

- `gh` CLI が認証済みで `project` スコープを持つ（`gh auth login` / `gh auth refresh -s project`）
- `.claude/leadcraft.md` の `tracker.github.*`（owner / project number / field IDs）が設定済み

## item_ref

GitHub Issue 番号（例: `123`）。`resource_uri` は Issue の HTML URL。

## 操作 → 具体コマンドの対応（移植時の指針）

| 抽象操作 | github 実装の骨子 |
|----------|-------------------|
| `create_item` | `gh issue create --title --body --label`。戻り値は Issue 番号 |
| `update_item` | `gh issue edit <n> --body`/`--title` |
| `get_item` | `gh issue view <n> --json` |
| `list_items` | `gh issue list --label "<label>"` / Projects ビュー |
| `add_comment` | `gh issue comment <n>` |
| `set_field` | Issue を Projects に追加（`gh project item-add`）後 `gh project item-edit` でフィールド設定。フィールド ID は設定から解決 |
| `add_label` / `remove_label` | `gh issue edit <n> --add-label` / `--remove-label` |
| `ensure_label` | `gh label list` で存在確認、無ければ `gh label create` |
| `resource_uri` | Issue の HTML URL |

## ガードレール（Phase 2 で移植する hook）

- Projects (v2) の Single Select フィールド option を CLI / GraphQL から書き換える操作
  （`updateProjectV2Field` / `createProjectV2Field` 等、`gh project field-create` / `field-delete`）は
  **内部 option ID 再発番事故を防ぐためハードブロックする**。option 追加は Web UI からの手動操作のみ許可する。
- 元プラグインの `hooks/guard-project-field-mutation.sh` を Phase 2 で移植し、`provider == github` のときのみ作動させる。

## OKF との関係

github アダプタはあくまで同期先。Story の真実は local md（OKF concept）側にあり、`resource` フィールドに
Issue URL を記録することで、OKF バンドルが「生きた Issue を指すカタログ」として機能する。
