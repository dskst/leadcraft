---
name: compose-stories
description: 指定した Epic 配下に Story を 1 件以上、対話を通じて詳細設計し、**トラッカーへ作業項目として登録する**（既定の `local` プロバイダでは Epic 配下のローカル md ファイル＝OKF concept を生成する。`github` プロバイダは opt-in / Phase 2）。受け入れ基準・タスク・依存関係まで設計したうえで、Story 項目の作成 → 階層フィールド（Objective / Initiative / Epic）・Points・Risk Score の設定 → DoD フォローコメントの付与までを抽象操作経由で一気通貫に実行する。出力先は `tracker.provider` 設定または `--local` / `--github` 引数で切り替える。「Story を作る」「Story を設計する」「Story に分解する」「Story を起票する」「ローカルに Story md を作る」「オフラインで Story を設計する」「受け入れ基準を書く」「ユーザー価値を Story に落とす」「Epic を Story に分割する」「タスクを切り出す」と言われたら起動する。Epic を整える場合は `compose-epic`、Objective は `compose-objective`。**「とりあえず叩き台として軽く登録したい」「打ち合わせ中にサクッと項目を立てたい」「タイトルと受け入れ基準だけでよい」場合は `quick-stories` を案内する**（本スキルは詳細設計込みで登録する重量級。quick-stories は軽量級）。
argument-hint: "（任意：親 Epic README のパス / 要件メモ md パス / URL / 既存 Story の item_ref（local: md パス / github: #番号）。モード指定は --local | --github）"
allowed-tools: Read, Edit, Write, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# compose-stories

5 階層（Objective > Initiative > Epic > Story > Task）における **Story** を 1 件以上、対話で詳細設計し、**トラッカーへ作業項目として登録する**単一スキル。
本スキルだけで「設計 → トラッカーへの項目作成 → 階層フィールド設定 → DoD フォローコメント付与」が完結する。

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `create_item` / `set_field` / `add_comment` / `add_label` / `ensure_label` 等の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド・ファイル書き込み等）は各アダプタ（`references/backends/<provider>.md`）に委譲する。

**出力先（provider）の解決**:

| provider | 出力先 | 状態 | 用途 |
|----------|--------|------|------|
| `local` | `<epic-dir>/<story-slug>.md`（OKF concept。Epic README と同階層） | **既定** | 外部依存ゼロ。これが source of truth |
| `github` | GitHub Issue + Projects カード + DoD フォローコメント | opt-in / **Phase 2** | local からの同期先 |

既定は `local`。local では Story = `<epic-dir>/<slug>.md`（OKF concept）を生成するのが主フローである。Epic 以上の階層は常に markdown ファイルで管理する（変更なし）。

> **Phase 2 の注記**: `github` プロバイダのアダプタは現時点でスタブ（`references/backends/github.md`）であり、Issue / Projects の具体手順は未移植である。`--github` 指定時、アダプタが未実装の操作については「Phase 2 で提供予定。当面は `local` で設計し、後日 `sync-stories`（Phase 2）でアップロードする」と案内する。また、見積もり・リスクへの遷移を担う `estimate-points` / `identify-risks`、品質ゲートの `review-stories`、hook 連携（`notify-draft-added.sh` 等）も **Phase 2 以降に提供予定**であり、本スキルからは存在しない前提で手順を書かない。

Epic 自体を整える `compose-epic`（モード A）、既存 Epic README から Story 候補を機械抽出する `compose-epic`（モード B）とは目的が異なる。本スキルは「Story 1 件 1 件をレビュー・実装可能な単位にまで具体化し、トラッカーへ登録する」ことに集中する。

## quick-stories との使い分け

| | compose-stories（本スキル） | quick-stories |
|---|---|---|
| 用途 | 詳細設計込みで登録 | 叩き台として最短手数で登録 |
| 対話量 | 多い（AC / タスク / 依存 / 見積もり / リスク） | 最小（タイトル + 概要 + AC のみ） |
| 本文セクション | 8 セクション | 3 セクション |
| ラベル | `story` + `epic:<id>` + **`draft`** | `story` + `epic:<id>` + **`quick`** |
| DoD コメント | 付与（`add_comment`） | 付与しない |
| 既存項目更新 | item_ref 引数で本文を肉付け（`quick` → `draft` への昇格も担う） | 行わない |

判断: 設計の手応えが必要なら本スキル。記録だけ残したいなら `quick-stories`。**quick で起票された項目を肉付けして昇格させたい場合は、本スキルに item_ref（local: md パス / github: `#<番号>`）を渡して更新フロー（ステップ 13）に入る**。

## 想定する利用シーン

- 親 Epic を `compose-epic` で整え終え、配下に Story を追加したい
- 要件メモから「ユーザー価値の塊」を取り出して具体化し、Story 化する
- 既存 Story の受け入れ基準・タスクが薄いので肉付けする（`get_item` → 対話で詰める → `update_item`）
- `compose-epic` モード B で抽出した骨だけの Story を詳細設計に進める
- 13pt 以上が予想される大きな Story を分割して再登録する

## 出力

### local モード（既定）

| 項目 | 値 |
|------|----|
| Story 項目 | `create_item` でトラッカーに作成。local アダプタは `<epic-dir>/<story-slug>.md` を `${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` から展開して生成（OKF frontmatter 完備） |
| ラベル | `story` + **`draft`**（昇格前マーカー）+ 必要に応じて `hotfix` 等（`issue.default_labels` の追加分）。`epic:<epic-id>` は `add_label` で付与 |
| 階層フィールド | `set_field` で `objective` / `initiative` / `epic` をセット（local では frontmatter に保存） |
| Points / Risk Score | `set_field` で初期値 0 をセット（local では frontmatter）。実値は `estimate-points` / `identify-risks`（Phase 2）が後段で更新 |
| DoD | `add_comment` で付与（local アダプタは本文末尾の「Definition of Done」セクションに展開） |
| log.md | Epic 階層の `log.md` に `Creation: Story <slug> を作成` を 1 行追記（OKF 規約 §3） |

### github モード（opt-in / Phase 2）

| 項目 | 値 |
|------|----|
| Story 項目 | `create_item` で GitHub Issue を作成（github アダプタ。**Phase 2**） |
| ラベル | `story` + `epic:<epic-id>` + `draft` を `add_label` で付与 |
| 階層フィールド | `set_field` で Projects のフィールドに反映（github アダプタ。**Phase 2**） |
| DoD | `add_comment` でフォローコメント投稿（github アダプタ。**Phase 2**） |

> **ID 規約について**: 本ドキュメント中の `<epic-id>` は **親 Epic README の `id` フィールドの値そのまま** を指す。compose-epic が `id` を組み立てる際、親 Objective に `id_suffix` が設定されていれば `<base>-<suffix>` 形式（例: `oauth-login-a1b2c`）になり、未設定なら base のまま（例: `oauth-login`）になる。本スキルは Epic README の `id` を Read してそのままラベル・フィールドに使うため、suffix の有無に関係なく自動的に正しい値が伝播する。Initiative / Objective も同様に Epic README の `initiative` / `objective` フィールドからそのまま読み取る。

## 前提

### 共通

- 親 Epic README が `<root>/<objective>/<initiative>/<epic>/README.md` に存在する
- `.claude/leadcraft.md` の `output.root_dir` / `dod`（任意）/ `issue.default_labels`（既定 `["story"]`）が埋まっている
- `tracker.provider` で出力先を設定（`local` 既定 / `github` は Phase 2）

### local モード時（既定）

- Epic ディレクトリへの書き込み権限があること（通常はリポジトリ内なので自然に満たされる）
- 既存 Story md と slug が衝突しないこと（衝突時はアダプタが `-2`, `-3` を自動付与）
- 外部依存ゼロのため、`create_item` 等の全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `project` スコープ、`tracker.github.*` の設定）を満たすこと
- 未設定・未実装の操作は graceful degradation（アダプタがスキップして警告。`tracker-contract.md` §5）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

引数が常に最優先される。曖昧な場合（例: 設定が `local` で github の item_ref（`#123`）引数が来た）は、item_ref の形式から provider を推定する。`#<数値>` 形式の item_ref は github の既存項目更新フロー（ステップ 13）、`*.md` パス形式の item_ref は local の既存項目更新フロー（ステップ 13）に入る。これは「item_ref の形が示す provider 側の更新を意図している」というユーザー直観を尊重する設計である。

解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の「操作 → 具体手順」マップを参照して以降の抽象操作を実行する。

## 実行手順

### 1. 親 Epic の特定

Story は必ず Epic の下にぶら下がる。引数や対話で次のいずれかを取得する:

- 親 Epic README の絶対 / 相対パス（推奨）
- 親 Epic ディレクトリのパス
- Epic ID（既存）— `Glob` で `<root>/*/*/*/README.md` を列挙して ID マッチ

該当する Epic README が見つからない場合、`AskUserQuestion` で 3 択を提示:

- 既存 Epic から選ぶ（一覧を提示）
- `compose-epic` で Epic を先に整える（本スキルを中断して案内）
- 「Epic は後で整える」前提で進める（暫定 Epic ID で項目を作り、本文に TODO を残す）

Epic README が見つかった場合は `Read` で取得し、以下を Story 設計の土台にする:

- 概要 / ユーザーストーリーサマリー / 価値仮説
- スコープ（含む / 含まない）/ Epic DoD / 主要ユーザーフロー
- 既存 Story（`list_items({epic: "<epic-id>"})` で重複生成を避ける）

### 2. 追加入力ソースの取り込み（任意）

- 要件メモ / 仕様書（Markdown ファイル、`Read`）
- GitHub Issue / Discussion URL（`WebFetch`、または github プロバイダなら `get_item`）
- Figma / 戦略資料 URL（`WebFetch`）
- Notion ページ（利用可能な MCP ツールを動的検出して呼び出す。MCP が無ければ `WebFetch`）
- チャットでの直接記述

### 3. 設定読み込みと環境検出

`.claude/leadcraft.md` から以下を読み込む:

- `tracker.provider`（および `tracker.github.*`。github プロバイダ時のみ）
- `output.root_dir`
- `issue.default_labels`
- `story_template`（任意。省略時は `${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md`）
- `dod`（任意）

provider 固有の前提チェックはアダプタに委ねる:

- **local**: 外部依存ゼロのため追加チェック不要（`references/backends/local.md`）
- **github（Phase 2）**: `gh` 認証・`project` スコープ・`tracker.github.*` の確認。未設定操作は graceful degradation（`references/backends/github.md`）

### 4. Story 候補の列挙とユーザーレビュー

Epic 内容と追加入力から、想定される Story を列挙し、各候補に以下のメモを添えて `AskUserQuestion` で提示する:

- 仮タイトル / 概要 1〜2 行 / 想定規模（小・中・大）
- 関連する Epic DoD 項目・スコープ項目
- 既存 Story との重複可能性（あれば該当 item_ref）

確認事項:

- 各候補を Story 化するか / マージ / 分割 / 削除
- 漏れている Story はないか
- 優先順位の高い Story から先に詳細化するか

`split_threshold`（既定 13pt）以上が予想される候補はこの時点で分割を提案する。

### 5. 各 Story の詳細設計

選定された Story それぞれについて、順番に詰める。判明している範囲で書き、不明部分は本文に `<!-- TODO: ... -->` を残す。

#### 5-1. タイトル

日本語可。提供価値を 1 行で。項目タイトルとしてそのまま使う。Hotfix の場合は `[Hotfix]` プレフィックスを付ける（テンプレートに合わせる）。

#### 5-2. 背景・目的

Story 固有の背景・ゴールを 2〜4 行。ユーザーストーリー形式（"\<role\> として、\<goal\> したい。なぜなら \<reason\>"）は推奨だが必須ではない。

#### 5-3. 受け入れ基準（Acceptance Criteria）

3〜5 項目のチェックリスト。検証可能で、外部から観測できる振る舞いで書く。

#### 5-4. タスクチェックリスト

3〜7 項目。実装漏れ防止が目的。「テスト追加」「ドキュメント更新」を含める。

#### 5-5. 依存関係

- **前提 Story**: 完了が必要な他 Story（item_ref。local では他 Story md のバンドル絶対パス、github では `#123` 形式）
- **ブロックする Story**: 本 Story の完了を待つ他 Story

新規 Story 同士で依存関係がある場合は、登録順序（依存先を先に登録）を計画する。前提となる item_ref は登録後に判明するため、依存元の本文を `update_item` で後追い更新する。

#### 5-6. 見積もり詳細（プレースホルダー）

雛形の「見積もり詳細」セクションは **初期値（Points=0, O=M=P=0）で出力**。実値は `estimate-points`（Phase 2）が後段で更新する。本フェーズでは `set_field(item_ref, "points", 0)` で初期化する。

#### 5-7. リスクと対応策（プレースホルダー）

「リスクと対応策」セクションも空のテーブルで出力。`set_field(item_ref, "risk_score", 0)` で初期化する。`identify-risks`（Phase 2）が後段で埋める。設計の過程で明らかに重大なリスクが見えた場合のみ、その場で 1 行入れておく。

### 6. 13pt 以上の Story の扱い（強制登録の確認）

ステップ 4 で分割を促しても「このまま登録する」を選んだ Story がある場合、登録前に再度確認する。
- 「分割を推奨する。`compose-epic`（Epic を見直す）または本スキル（Story を再分解）を実行してほしい」
- それでも強制登録する場合は警告ログを表示して進める

### 7. Story 本文の構築

`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md`（または `story_template` で指定された雛形）を `Read` し、以下のプレースホルダを Story の詰めた値で埋める。**OKF frontmatter を完備させる**こと（`references/okf-conformance.md` §2）:

- **frontmatter（OKF）**:
  - `type: story`（OKF 必須）
  - `title`: Story タイトル（ダブルクオート内、`"` はエスケープ）
  - `description`: Story の 1 文要約（OKF 推奨。`index.md` の progressive disclosure と AI 関連度判定の土台。必ず埋める）
  - `tags`: 付与するラベルをミラーリング（`["story", "draft"]`、hotfix なら `["story", "draft", "hotfix"]`）
  - `timestamp`: 現在時刻（ISO 8601。`updated_at` と同値）
  - `resource: null`（local では未同期なので null。github 同期後に Issue URL が入る）
  - `tracker_ref`: 自身の item_ref（local ではバンドル絶対パス。`create_item` の戻り値で確定するため、アダプタが書き込む）
- **frontmatter（leadcraft 拡張）**:
  - `status: draft` / `mode: composed`
  - `objective_id` / `initiative_id` / `epic_id`: Epic README の frontmatter からそのまま転記
  - `points: 0`、`estimation.{o,m,p,e,stddev}`: すべて 0、`estimation.mode: "pert"`（初期値）
  - `risk_score: 0`、`risks: []`
  - `dependencies.blocked_by` / `blocks`: ステップ 5-5 で決めた依存関係を item_ref の配列で埋める（local では他 Story の **バンドル絶対パス**（`/obj/init/epic/other-story.md`）、github では `"#123"` 形式の混在可）
  - `github_issue: null`、`github_issue_url: null`、`uploaded_at: null`
  - `labels`: `["story", "draft"]`（hotfix の場合は `["story", "draft", "hotfix"]`）
- **本文**:
  - `{{STORY_TITLE}}` / `{{STORY_PURPOSE}}`
  - `{{OBJECTIVE_TITLE}}` / `{{INITIATIVE_TITLE}}` / `{{EPIC_TITLE}}`。Epic README へのリンクは **バンドル絶対パス**（`/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md`）で記述する（OKF クロスリンク規約 §4）
  - `{{ACCEPTANCE_CRITERIA_*}}` / `{{TASK_*}}`
  - 見積もり詳細・リスクと対応策はテーブル雛形のまま（`{{POINTS}}` = 0 / `{{O}}` = 0 等）残す。`estimate-points` / `identify-risks`（Phase 2）が後段で埋める
  - `{{DEPENDENCY_ITEMS}}` / `{{BLOCKING_ITEMS}}`: 依存関係を箇条書きで列挙（local では他 Story の **バンドル絶対パス** リンク、github では `#123` リンク）。なければ `なし`

### 8. トラッカーへの登録（抽象操作）

ここまでで Story 1 件 1 件の設計と本文が確定している。provider に応じたアダプタ（`references/backends/<provider>.md`）の実装で、各 Story について以下の抽象操作を順に実行する:

1. **`ensure_label`**: 付与するラベルの存在を保証する。
   - `epic:<epic-id>` ラベル（Epic 単位の絞り込みタグ）
   - `draft` ラベル（昇格前マーカー。詳細は後述）
   - その他の追加ラベル（hotfix 等）
   - local アダプタでは no-op（ラベルは frontmatter の文字列にすぎない）。github アダプタ（Phase 2）では未存在時に `AskUserQuestion` で「作成する / スキップ」を尋ねてから作成する（勝手にラベルを増やさない）

2. **`create_item(title, body, item_type, labels[])`**: ステップ 7 で構築した本文で Story 項目を作成する。
   - `item_type`: `story`（hotfix の場合も `story` ラベル + `hotfix` ラベルで表現）
   - `labels[]`: `issue.default_labels`（既定 `story`）+ `draft` + 追加ラベル
   - 戻り値は item_ref（local: バンドル絶対パス / github: Issue 番号）
   - local アダプタはこのとき Story md を生成し、frontmatter の `tracker_ref` に自身のパスを書き込み、Epic の `log.md` に `Creation` 行を追記する（`references/backends/local.md`）

3. **`add_label(item_ref, "epic:<epic-id>")`**: Epic 絞り込みタグを付与（`create_item` の labels に含めても可。アダプタの都合に従う）。

4. **`set_field`**: 階層フィールドと初期メトリクスをセットする（`tracker-contract.md` §3 の正規語彙）:
   - `set_field(item_ref, "objective", <objective-id>)`
   - `set_field(item_ref, "initiative", <initiative-id>)`
   - `set_field(item_ref, "epic", <epic-id>)`
   - `set_field(item_ref, "points", 0)`
   - `set_field(item_ref, "risk_score", 0)`
   - local では frontmatter の対応キーに保存。github（Phase 2）では Projects フィールドに反映。未設定 / 未実装のフィールドはアダプタがスキップし、結果サマリーに表示する（graceful degradation）

> **`draft` ラベルの設計意図**:
> - 本スキルが登録する Story は、登録時点では見積もり・リスクが未確定であるのが普通である
> - `draft` を付けることで「これは下書きであり、レビューを経て初めて計画に組み込める」状態を視覚化する
> - 昇格（`draft` 削除）は **専用の `review-stories` スキル（Phase 2）** で行う。本スキルは昇格に踏み込まない
> - レビュー前の Story を `list_items({label: "draft"})` で除外・抽出できる

> **見積もり・リスク・レビューへの遷移（Phase 2）**: `estimate-points` / `identify-risks` / `review-stories`、および hook 連携（`notify-draft-added.sh`）は **Phase 2 以降に提供予定**である。本フェーズでは本スキルは Story 登録で完結し、後続スキルを呼び出さない。Phase 2 では hook が `create_item`（draft 付与）を検知して estimate-points を促す設計を予定している。

### 9. DoD フォローコメントの付与（抽象操作）

`dod` リストが設定ファイルにあれば、Story 本文（Acceptance Criteria）とは分けて **`add_comment` で DoD を付与**する。本文と分けるのは、Story 個別の Acceptance Criteria（本文）とチーム共通 DoD（コメント）の責務を分離するためである。

```
add_comment(item_ref, <DoD 本文>)
```

DoD 本文の組み立て:

```markdown
## Definition of Done

> 本内容は `setup-dod` で設定されたチーム共通の完了条件である。Story 個別の Acceptance Criteria は本文を参照。

- [ ] <DoD 項目 1>
- [ ] <DoD 項目 2>
...
```

provider 別の展開先（アダプタが振り分ける）:

- **local**: 本文末尾の `## Definition of Done` セクションにチェックリストとして展開する（`references/backends/local.md` の `add_comment`）。ローカルファイルにはコメント概念がないため本文に保持する
- **github（Phase 2）**: Issue にフォローコメントとして投稿する（`references/backends/github.md`）

`dod` 未設定 / 空の場合はスキップし、「DoD 未設定のためスキップ。`setup-dod` で登録できる」と案内する（local では本文の見出し直下に `> DoD 未設定。\`setup-dod\` で登録できる。` を 1 行入れる）。

### 13. 既存 Story の更新フロー（item_ref 引数時）

引数が既存 Story の item_ref（local: `*.md` パス / github: `#123`）の場合、新規作成ではなく更新フローに入る。

1. **`get_item(item_ref)`** で現状（title / body / fields / labels）を取得
2. 本文の各セクション（背景・受け入れ基準・タスク・依存・見積もり・リスク・DoD）について差分提案
3. ユーザー承認後に **`update_item(item_ref, {body, title?})`** で更新
4. ラベル変更は `add_label` / `remove_label`
5. フィールド変更はステップ 8 の `set_field` を流用

**全体上書きはしない**。差分提案 → 承認 → `update_item` の流れを徹底する。`update_item` は local アダプタでは `updated_at` / `timestamp` の更新と `log.md` への `Update` 行追記を伴う（`references/backends/local.md`）。

**`quick` 項目の昇格パス**: 対象が `quick-stories` で起票されたもの（`quick` ラベル / `mode: quick`）の場合、本スキルでの肉付けは「叩き台 → 完全な Story」への昇格となる。手順:

1. 本文の薄い 3 セクション（階層 / 背景・目的 / 受け入れ基準）を保持しつつ、タスク / 見積もり詳細 / リスクと対応策 / 依存関係 / Definition of Done セクションを追加する
2. ラベルを **`quick` → `draft` に置き換える**（`remove_label(item_ref, "quick")` → `add_label(item_ref, "draft")`）
3. local では合わせて frontmatter の `mode: quick` を `mode: composed` に、`tags` の `quick` を `draft` に置き換える
4. github（Phase 2）で `resource`（同期済み Issue URL）が既にセットされている場合、ユーザーに「合わせて同期先も更新するか」を確認する

> frontmatter の `points` / `estimation.*` / `risks` / `risk_score` は本スキルでは **触らない**（`estimate-points` / `identify-risks`（Phase 2）の責務）。`tracker_ref` / `github_issue` / `uploaded_at` も本スキルでは触らない（`sync-stories`（Phase 2）の責務）。

### 14. 結果サマリー

各 Story について以下を表示する:

- 登録成功: タイトル / item_ref（local: 書き出し先の絶対パス / github: Issue URL）/ provider / mode（composed / quick）/ セットしたフィールド一覧 / スキップしたフィールド / DoD コメント付与の有無
- スキップ: 理由（13pt 以上を強制登録回避 / 既登録 / provider 前提未充足 等）
- 失敗: エラー内容と次のアクション

local モードの場合、サマリーの末尾に **「次のアクション候補（Phase 2 で提供予定）」** として以下を案内する（存在しないスキルとして手順は書かず、提供予定である旨を添える）:

- `estimate-points`: ローカル Story の見積もりを行う（**Phase 2**）
- `identify-risks`: ローカル Story のリスクを識別する（**Phase 2**）
- `sync-stories`: ローカル Story を github トラッカーへアップロードする（**Phase 2**）
- `review-stories`: 品質ゲートを通して `draft` を外す（**Phase 2**）
- `build-bundle`: OKF バンドルの `index.md` / `log.md` を補完・検証する

サマリーを出した後、本スキル単体は終了する。後続スキルの起動は **Phase 2 で hooks のイベントルーターに集約** する設計である（責務分離）。本フェーズでは本スキルから後続スキルを直接呼び出さない。

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `create_item` / `update_item` / `get_item` / `list_items` / `add_comment` / `set_field` / `add_label` / `remove_label` / `ensure_label` / `resource_uri` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **provider 別の出力先**:
  - local（既定）: `<epic-dir>/<story-slug>.md`（OKF concept）のみ生成。外部サービスには触れない
  - github（Phase 2）: GitHub Issue + Projects 側のみ変更
- **OKF 準拠**: local の Story md は OKF concept として `references/okf-conformance.md` §2 を満たす（パース可能な frontmatter + 非空 `type` + `description`）。内部リンク（親 Epic 等）は **バンドル絶対パス**（`/` 始まり）で書く（§4）。Story 作成時は Epic 階層の `log.md` に `Creation` 行を追記する（§3）。`index.md` の更新は `build-bundle` の責務（本スキルは触らない）
- 本スキルは **Story 階層のみ** を扱う。Objective / Initiative / Epic の作成・更新には踏み込まない（それぞれ `compose-objective` / `compose-epic` の責務）
- **登録直後の Story は必ず `draft` 状態**。品質ゲートは `review-stories`（Phase 2）に分離する。本フェーズでは昇格判定に踏み込まない
- 親 Epic README が存在しない場合は `compose-epic` を先に実行するよう推奨する。「Epic は後で整える」も許容（暫定値 + TODO コメント）
- `split_threshold`（既定 13）pt 以上が予想される Story はステップ 4 で分割を提案。それでも 1 件で進める場合は明示的にユーザー判断を確認する
- 見積もり値（Points / O / M / P）とリスクスコアは登録時点では埋めない。`set_field` で 0 に初期化し、`estimate-points` / `identify-risks`（Phase 2）が後段で埋める
- 既存 Story を更新する場合、本文を上書きしない。差分提案 → 承認 → `update_item` の流れを徹底する
- 同一 Story を 2 回登録しない: `list_items({epic: "<epic-id>"})` で既存 Story のタイトル / 本文の特徴から重複検出を試み、疑わしければユーザーに確認する
- ラベルが存在しない場合の扱いはアダプタに委ねる（local は no-op、github は作成可否をユーザー確認）。勝手にラベルを増やさない
- **github の Projects フィールド option 追加に関するガードレール**（Single Select option の CLI / GraphQL 書き換え禁止）は Phase 2 で github アダプタに hook（`guard-project-field-mutation.sh`）として移植する。本フェーズの local 運用では該当しない

### local モード固有の注意

- **ファイル名 slug は kebab-case 英数字のみ**。日本語タイトルの場合はアダプタが英語化案を提示してユーザーに選ばせる（`references/backends/local.md` の `create_item`）
- **既存 md と slug が衝突する場合は自動的に `-2` / `-3` を付与**。既存 md を上書きしない
- **frontmatter が常に source of truth**。本文の表（見積もり詳細・リスク表）は frontmatter と連動させる（`estimate-points` / `identify-risks`（Phase 2）が両方を同時更新）
- **DoD は本文末尾の「Definition of Done」セクションに展開**（`add_comment` の local 実装）。github へ同期する際は、本セクションの内容を分離してフォローコメントとして投稿する（`sync-stories`（Phase 2）の責務）
- **依存関係は他 Story md のバンドル絶対パスでも item_ref でも可**。同 Epic 内のローカル Story 同士を参照する場合はバンドル絶対パス（`/obj/init/epic/other-story.md`）を推奨
