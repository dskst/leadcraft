---
# leadcraft プラグイン設定
# このファイルを .claude/leadcraft.md にコピーして編集する。
# チーム共有設定としてコミット推奨（ファイル名に .local を含まないため
# .gitignore の .claude/*.local.{md,json} パターンにマッチしない）。

baseline:
  small:
    points: 2
    reference_story: ""  # 例: "ログイン画面のバリデーションメッセージ追加"
    description: ""      # この基準点となる作業内容の概要
  large:
    points: 8
    reference_story: ""  # 例: "OAuth2.0 によるソーシャルログイン実装"
    description: ""      # この基準点となる作業内容の概要

# Definition of Done (DoD)
# すべての Story が満たすべき共通の完了条件をリストで定義する。
# setup-dod スキルで対話的に編集できる。空リストにすれば DoD 反映を無効化する。
dod:
  - "単体テストを追加し、CI（lint / test / build）がすべて green である"
  - "レビューを 1 名以上から取得し、指摘事項を解決またはチケット化している"
  - "関連ドキュメント（README / API 仕様 / 操作手順）を更新している"

fibonacci_max: 89    # 上限ポイント（89 を超える Story は分割対象）
split_threshold: 13  # このポイント以上の Story は分割推奨

output:
  root_dir: ""  # Knowledge Bundle のルート。compose-objective 初回実行時に対話で確定（保存後は固定）
  # 候補: docs/objectives（推奨）/ .objectives（隠し）/ 任意のパス
  # 構造: <root_dir>/<objective>/<initiative>/<epic>/README.md
  # この配下のツリー全体が OKF 0.1 準拠の Knowledge Bundle になる（references/okf-conformance.md）

# ───────────────────────────────────────────────────────────
# トラッカー設定（Story 層の保存先）
# 抽象契約は references/tracker-contract.md、各実装は references/backends/<provider>.md
# ───────────────────────────────────────────────────────────
tracker:
  provider: "local"  # local（既定・外部依存ゼロ） | github（opt-in）
  # local:  Story = <epic-dir>/<slug>.md（OKF concept）。これが source of truth
  # github: Story = GitHub Issue + Projects。local からの同期先（実装済み）
  # スキル実行時に --local / --github でオーバーライド可能

  github:  # provider == github のときのみ使用
    owner: ""        # org または user 名
    project_number: 0
    project_name: ""
    fields:          # gh project field-list で取得した ID
      objective: ""
      initiative: ""
      epic: ""
      points: ""
      risk_score: ""
      status: ""

# OKF（Open Knowledge Format）バンドル設定
okf:
  version: "0.1"      # build-bundle が root index.md に宣言する OKF バージョン
  emit_index: true    # index.md（ディレクトリ目次）を生成するか
  emit_log: true      # log.md（時系列履歴）を生成・追記するか
  link_style: "absolute"  # absolute（バンドル絶対 / 推奨） | relative

issue:
  default_labels: ["story"]  # Story 項目に付与する基本ラベル（hotfix は ["story", "hotfix"]）

story_template: ""  # カスタム Story テンプレートのパス（省略時は同梱テンプレート）

hotfix:
  # hotfix Story の階層 ID。base_id（suffix なし）で書く。
  objective_id: "operations"
  initiative_id: "maintenance"
  epic_id: "hotfix"

points_to_hours: null  # 例: 4（1pt = 4 時間）。convert-points-to-time 実行時に上書き可能
hours_per_day: 8       # 人日換算用
days_per_month: 20     # 人月換算用（営業日）

velocity:
  enabled: false
  history_file: ".objectives/.velocity.json"
---

# leadcraft 設定メモ

このファイルでプロジェクトごとの見積もり・出力・トラッカー設定を管理する。
**チーム共有設定としてコミットする**。

## 階層モデル（5 階層）

| 階層 | 管理場所 |
|------|----------|
| Objective | `<output.root_dir>/<objective>/README.md` |
| Initiative | `<output.root_dir>/<objective>/<initiative>/README.md` |
| Epic | `<output.root_dir>/<objective>/<initiative>/<epic>/README.md` |
| Story | `tracker.provider` による（local: `<epic-dir>/<slug>.md` / github: Issue + Projects） |
| Task | Story 本文のチェックリスト |

`<output.root_dir>` 配下のツリー全体が **OKF 0.1 準拠の Knowledge Bundle** になる。

## トラッカー（tracker）

Story 層の保存先を `tracker.provider` で切り替える。**既定は `local`**（外部依存ゼロで即動く）。
GitHub Issue + Projects 運用に乗せたい場合は `github` にし、`tracker.github.*` を設定する。

スキルはトラッカー操作を抽象契約（`references/tracker-contract.md`）経由で呼ぶため、
将来 GitLab / Jira 等を `references/backends/<provider>.md` 追加だけで対応できる。

## 基準点（baseline）/ DoD

`setup-baseline` / `setup-dod` スキルで初期登録・編集する。

## OKF バンドル

`build-bundle` スキルがツリーを走査し、`index.md` / `log.md` / `okf_version` を補完して
自己記述的な Knowledge Bundle を生成・検証する。設定は `okf.*` セクション。
