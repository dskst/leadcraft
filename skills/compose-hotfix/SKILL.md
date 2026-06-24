---
name: compose-hotfix
description: 緊急対応・障害対応・小規模な保守作業を Hotfix Story として、対話を最小化して **トラッカーへ作業項目として即座に登録する**（既定の `local` プロバイダでは Hotfix 用 Epic 配下のローカル md ファイル＝OKF concept を生成する。`github` プロバイダは opt-in / Phase 2）。階層は設定ファイルの `hotfix.{objective_id, initiative_id, epic_id}` に従い（既定 `operations / maintenance / hotfix`）、本文は「発生事象 / 影響範囲 / 暫定対応 / 根本原因 / 恒久対応 / タイムライン」の構成で組み立てる。ラベル `story` + `hotfix` + `draft` + `epic:<hotfix-epic-id>` を付与し、階層フィールドのセット、DoD フォローコメント付与までを抽象操作経由で一気通貫に実行する。出力先は `tracker.provider` 設定または `--local` / `--github` 引数で切り替える。「hotfix を作る」「障害対応の項目を起票」「緊急対応の起票」「Hotfix を登録する」「インシデントを記録する」「Postmortem を準備する」「障害チケットを切る」「いまの障害を起票して」と言われたら起動する。通常 Story には `compose-stories` を案内する。
argument-hint: "（任意：障害の一行要約、検知経路メモ、既存 Hotfix の item_ref（local: md パス / github: #番号）で更新。モード指定は --local | --github）"
allowed-tools: Read, Edit, Write, Glob, Grep, AskUserQuestion, Bash
---

# compose-hotfix

緊急対応の hotfix を **トラッカーへ素早く登録** するための専用スキル。
通常 Story を登録する `compose-stories` の派生だが、緊急対応の性質に合わせて以下のように振る舞いを変えている:

| 違い | 通常 (`compose-stories`) | Hotfix (本スキル) |
|------|--------------------------|------------------|
| 階層の選択 | 対話で親 Epic を確定する | **固定**（設定ファイルの `hotfix.*`、既定 `operations / maintenance / hotfix`） |
| 本文構造 | 受け入れ基準 / タスク / 見積もり / リスク | 発生事象 / 影響範囲 / 暫定対応 / 根本原因 / 恒久対応 / タイムライン |
| 対話量 | 1 Story につき 6〜10 ステップ | 必要最小限（タイトル + 発生事象 + 影響範囲 + 暫定対応 が揃えば登録可能） |
| 見積もり | プレースホルダーで登録 → `estimate-points`（Phase 2）で更新 | **省略**（Points は 0 のまま）。事後に実績を入れたい場合のみ手動更新 |
| リスク識別 | `identify-risks`（Phase 2）で後追い | **省略**。再発リスクは Epic README にメモ |
| ラベル | `story` + `draft` + `epic:<id>` | `story` + `hotfix` + `draft` + `epic:<hotfix-epic-id>` |
| タイトル | 任意 | `[Hotfix] YYYY-MM-DD: <要約>` 形式を推奨 |

緊急対応中はオペレーターの注意力を奪わないことが重要。本スキルは「最低限の構造化情報を集めて項目を立て、追記は事後に項目上で行う」設計に倒している。

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `create_item` / `update_item` / `get_item` / `list_items` / `add_comment` / `set_field` / `add_label` / `ensure_label` 等の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド・ファイル書き込み等）は各アダプタ（`references/backends/<provider>.md`）に委譲する。

**出力先（provider）の解決**:

| provider | 出力先 | 状態 | 用途 |
|----------|--------|------|------|
| `local` | `<hotfix-epic-dir>/<slug>.md`（OKF concept。Hotfix 用 Epic README と同階層） | **既定** | 外部依存ゼロ。これが source of truth |
| `github` | GitHub Issue + Projects カード + DoD フォローコメント | opt-in / **Phase 2** | local からの同期先 |

既定は `local`。local では Hotfix = `<hotfix-epic-dir>/<slug>.md`（OKF concept）を生成するのが主フローである。

> **Phase 2 の注記**: `github` プロバイダのアダプタは現時点でスタブ（`references/backends/github.md`）であり、Issue / Projects の具体手順は未移植である。`--github` 指定時、アダプタが未実装の操作については「Phase 2 で提供予定。当面は `local` で記録し、後日 `sync-stories`（Phase 2）でアップロードする」と案内する。見積もり・リスクへの遷移を担う `estimate-points` / `identify-risks`、品質ゲートの `review-stories`、hook 連携（`notify-draft-added.sh` 等）も **Phase 2 以降に提供予定**であり、本スキルからは存在しない前提で手順を書かない。

## 想定する利用シーン

- 本番障害を検知し、対応者が複数いるため早く項目を立てて状況を集約したい
- バグ修正・小規模な運用作業を後で振り返れるよう記録として残したい
- Postmortem の下地として、発生事象 / タイムライン / 暫定対応 / 恒久対応の枠を先に作っておきたい
- 既存の Hotfix を肉付けしたい（タイムライン追記、根本原因確定、恒久対応リンク）

通常の機能要求 / ユーザーストーリーは本スキルの対象外。`compose-stories` を案内する。

## 出力

### local モード（既定）

| 項目 | 値 |
|------|----|
| Hotfix 項目 | `create_item` でトラッカーに作成。local アダプタは `<hotfix-epic-dir>/<slug>.md` を生成。本文は hotfix 用構造（発生事象 / 影響範囲 / 暫定対応 / 根本原因 / 恒久対応 / タイムライン） |
| テンプレート | `${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` を流用し、hotfix 用構造に差し替える（hotfix 専用テンプレートは持たない。詳細はステップ 6） |
| frontmatter | OKF 必須 `type: story` + `description`（1 文要約）+ `tags`（labels をミラー）+ `timestamp` + `resource: null` + `tracker_ref`（自身のバンドル絶対パス）。leadcraft 拡張 `status: draft` / `mode: composed` / 階層 ID / `points: 0` / `risk_score: 0` |
| タイトル | `[Hotfix] YYYY-MM-DD: <要約>`（自動でプレフィックスと日付を補完） |
| ラベル | `story` + `hotfix` + `draft` を `create_item` で付与。`epic:<hotfix-epic-id>` を `add_label` |
| 階層フィールド | `set_field` で `objective` / `initiative` / `epic` を固定値でセット（local では frontmatter に保存）。`points` / `risk_score` は 0 |
| DoD | `add_comment` で付与（local アダプタは本文末尾の「Definition of Done」セクションに展開） |
| log.md | Hotfix 用 Epic 階層の `log.md` に `Creation: Story <slug> を作成` を追記（OKF 規約 §3） |

### github モード（opt-in / Phase 2）

| 項目 | 値 |
|------|----|
| Hotfix 項目 | `create_item` で GitHub Issue を作成（hotfix 用構造）。**Phase 2** |
| ラベル | `story` + `hotfix` + `draft` + `epic:<hotfix-epic-id>` を `add_label` |
| 階層フィールド | `set_field` で Projects フィールドに固定値を反映。`points` / `risk_score` は 0。**Phase 2** |
| DoD | `add_comment` でフォローコメント投稿。**Phase 2** |

> **ID 規約について**: 本ドキュメント中の `<hotfix-epic-id>` 等は **Hotfix 用 Epic README の `id` / `initiative` / `objective` フィールドの値そのまま** を指す。compose-epic が `id` を組み立てる際、親 Objective に `id_suffix` が設定されていれば `<base>-<suffix>` 形式（例: `hotfix-a1b2c`）になり、未設定なら base のまま（例: `hotfix`）になる。本スキルは Hotfix 用 Epic README の frontmatter を Read してそのままラベル・フィールドに使うため、suffix の有無に関係なく自動的に正しい値が伝播する（自前で suffix を展開しない）。

## 前提

### 共通

- `.claude/leadcraft.md` の以下が埋まっている:
  - `output.root_dir`
  - `hotfix.{objective_id, initiative_id, epic_id}`（既定 `operations / maintenance / hotfix`）
  - `issue.default_labels`（既定 `["story"]`）
  - `dod`（任意）
  - `tracker.provider`（出力先。`local` 既定 / `github` は Phase 2）
- Hotfix 用 Epic README が `<root>/<hotfix.objective_id>/<hotfix.initiative_id>/<hotfix.epic_id>/README.md` に存在する（無い場合は `compose-epic` で作成するよう案内）

### local モード時（既定）

- Hotfix 用 Epic ディレクトリへの書き込み権限があること（通常はリポジトリ内なので自然に満たされる）
- 既存 md と slug が衝突しないこと（衝突時はアダプタが `-2`, `-3` を自動付与）
- 外部依存ゼロのため、`create_item` 等の全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `project` スコープ、`tracker.github.*` の設定）を満たすこと
- 未設定・未実装の操作は graceful degradation（アダプタがスキップして警告。`tracker-contract.md` §5）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`compose-stories` と同じロジック。`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

引数が常に最優先される。既存項目更新の引数（local: `*.md` パス / github: `#<番号>`）が渡された場合は、その item_ref の形式から provider を推定する。解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の「操作 → 具体手順」マップを参照して以降の抽象操作を実行する。

## 実行手順

### 1. 起動モードの判定

引数から起動モードを判定する:

- 既存項目の item_ref（local: `*.md` パス / github: `#<number>`）: **既存 Hotfix の更新モード**（タイムライン追記 / 根本原因確定 / 恒久対応リンク等。ステップ 10）
- それ以外（要約テキスト / 空）: **新規登録モード**

不明な場合は `AskUserQuestion` で「新規登録 / 既存更新」を確認する。

### 2. 重複検出（新規登録モードのみ）

緊急対応では同一障害の二重登録が発生しやすい。登録前に直近のオープン Hotfix を `list_items({label: "hotfix"})` で取得し、ユーザーに重複の可能性を確認させる。

- local: `<hotfix-epic-dir>/*.md` のうち `tags`/`labels` に `hotfix` を含む md を列挙する
- github（Phase 2）: オープンな `hotfix` ラベル Issue を列挙する

結果をユーザーに提示し、`AskUserQuestion` で「同じ障害の項目があるか / 新規で登録するか」を確認する。既存があれば「既存更新モード」（ステップ 10）に切り替える。

### 3. 設定読み込みと環境検出

`.claude/leadcraft.md` から `tracker.provider`（および `tracker.github.*`。github プロバイダ時のみ）/ `output.root_dir` / `issue.default_labels` / `dod` / `hotfix.*` を読み込む。

`hotfix.*` が未設定なら既定値（`operations / maintenance / hotfix`）を使用する旨をユーザーに通知する。

provider 固有の前提チェックはアダプタに委ねる:

- **local**: 外部依存ゼロのため追加チェック不要（`references/backends/local.md`）
- **github（Phase 2）**: `gh` 認証・`project` スコープ・`tracker.github.*` の確認。未設定操作は graceful degradation（`references/backends/github.md`）

#### 3-1. Hotfix 用階層 ID の解決

`hotfix.{objective_id, initiative_id, epic_id}` を起点に、Hotfix 用 Epic README を特定して**階層 ID をその frontmatter からそのまま読み取る**。これにより `id_suffix` の有無は透過で扱える（自前で suffix を展開しない。`compose-stories` / `quick-stories` と同じ方針）。

手順:

1. `<root>/<hotfix.objective_id>/<hotfix.initiative_id>/<hotfix.epic_id>/README.md` の存在を `Glob` で確認する
2. 見つからない場合（`id_suffix` 付きのディレクトリ名になっている等で base 名と一致しない場合）は、`<root>/*/*/*/README.md` を `Glob` で列挙し、frontmatter の `objective`/`initiative`/`epic`（または `id`）が `hotfix.*` の base 名と前方一致するものを Hotfix 用 Epic として候補に挙げ、`AskUserQuestion` で確定する
3. 確定した Hotfix 用 Epic README を `Read` し、以下を取得する:
   - `objective` ID（`HOTFIX_OBJECTIVE_ID`。Objective には通常 suffix を付けない）
   - `initiative` ID（`HOTFIX_INITIATIVE_ID`）
   - `epic` ID（`HOTFIX_EPIC_ID`。`id_suffix` 設定時は `<base>-<suffix>` 形式になっている）
   - Epic / Initiative / Objective のタイトル（本文の H1 または `title` frontmatter）
4. Hotfix 用 Epic README が見つからない場合は本スキルを中断し、`compose-epic` で Hotfix 用 Epic を先に整えるよう案内する

ラベル名・階層フィールド値・本文中の階層情報すべてに、Read で得た正規 ID（`HOTFIX_OBJECTIVE_ID` / `HOTFIX_INITIATIVE_ID` / `HOTFIX_EPIC_ID`）を使う。

### 4. 必須情報の収集（対話を最小化）

`AskUserQuestion` を 1〜2 回に絞って最小限の情報を集める。一度に複数項目を聞いて往復回数を減らす。

#### 4-1. タイトル要約（必須）

- 質問: 「障害 / 対応の内容を 1 行で要約してほしい（例: `payment-api 500 error spike`、`auth セッション切れの大量発生`）」
- 入力された要約から、タイトルを自動構築する: `[Hotfix] YYYY-MM-DD: <要約>`
- 日付は実行日（`Bash` で `date +%Y-%m-%d`）。タイムゾーンは運用に応じて調整可能

#### 4-2. 発生事象 / 検知経路（必須）

- 質問: 「何が起こったか、どう検知したかを 2〜4 行で教えてほしい（時刻 / 検知者 / 検知方法など）」
- 自由記述で受け取り、本文の「発生事象 / 検知経路」セクションにそのまま貼る

#### 4-3. 影響範囲（必須）

- 質問: 「影響を受けるユーザー / システムと、業務影響レベル（High / Medium / Low）を教えてほしい」
- 自由記述 + High/Medium/Low の選択
- 「検知から対応開始までの時間」も任意で取る

#### 4-4. 暫定対応（必須 / チェックリスト形式）

- 質問: 「現時点で実施している（または予定している）応急処置を 2〜5 項目で挙げてほしい（チェックリストにする）」
- 例: 該当エンドポイントをロールバック、監視で正常化を確認、ステークホルダーへの一次連絡
- `- [ ]` 形式のチェックリストとして本文に貼る。完了済みは `- [x]`

#### 4-5. 根本原因（任意）

- 緊急時は原因不明のまま登録することが多い。判明していなければ「不明 / 調査中」を許容
- 判明している場合は 2〜4 行で記述。直接原因と背景要因を分けて書くと振り返りに使いやすい旨を案内

#### 4-6. 恒久対応の要否（任意）

- 質問: 「恒久対応が必要か？必要なら別 Story を起こすが、本スキルでは Hotfix 項目だけを作る」
- 必要: チェックボックス `- [ ] 恒久対応が必要（別途 Story を起票）` を有効化し、リンク欄に「TODO: 起票後に追記」を残す
- 不要: チェックボックス `- [x] 暫定対応で完結（再発リスクは許容範囲）` を有効化

### 5. 任意情報の追加（スキップ可能）

`AskUserQuestion` で「タイムライン / 関連ドキュメントを今追加するか」を確認する。緊急対応中はスキップを推奨し、登録後に更新フローで追記する流れにする。

- **タイムライン**: 時刻と出来事を 1 行ずつ並べる表。登録時点で判明している事象だけ書き、対応中に追記する
- **関連ドキュメント**: 障害レポート / Postmortem / 関連 Story / 関連 PR / チャットスレッド URL 等

### 6. Hotfix 本文の構築

`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` を `Read` し、**hotfix 用構造に差し替えて**本文を組み立てる。hotfix 専用テンプレートは持たず、共有テンプレートの frontmatter（OKF 完備）を流用して本文セクションだけを hotfix 用に置き換える。

> **テンプレート流用の方針**: story-local.md の frontmatter（`type: story` / `title` / `description` / `tags` / `timestamp` / `resource` / 階層 ID / `points: 0` / `risk_score: 0` / `tracker_ref` 等）はそのまま使い、本文の「受け入れ基準 / タスク / 見積もり詳細 / リスクと対応策 / 依存関係 / 参考」セクションを hotfix 用セクション（発生事象 / 影響範囲 / 暫定対応 / 根本原因 / 恒久対応 / タイムライン / 関連ドキュメント）に置き換える。「Definition of Done」セクションは残す（ステップ 9 で展開）。<!-- TODO: 将来 hotfix が頻用されるなら専用テンプレート skills/compose-hotfix/templates/hotfix-local.md を切り出すことを検討する。現状は共有テンプレートの流用で足りる -->

frontmatter には以下をセットする（`references/okf-conformance.md` §2、story-local.md の規約に従う）:

- `type: story` / `mode: composed` / `status: draft`
- `title`: `[Hotfix] YYYY-MM-DD: <要約>` / `description`: 1 文要約（必ず埋める）
- `tags: ["story", "hotfix", "draft"]`（labels をミラー）
- `objective_id` / `initiative_id` / `epic_id`: ステップ 3-1 で Read した Hotfix 用 Epic の正規 ID を転記
- `points: 0` / `risk_score: 0` / `risks: []`（hotfix は見積もり・リスクをスキップ）
- `resource: null` / `tracker_ref`: アダプタが書き込む

本文（階層セクションの Epic README へのリンクは **バンドル絶対パス**で書く。OKF クロスリンク規約 §4）:

```markdown
## 階層（固定）

- **Objective**: {{OBJECTIVE_TITLE}}（`<HOTFIX_OBJECTIVE_ID>`）
- **Initiative**: {{INITIATIVE_TITLE}}（`<HOTFIX_INITIATIVE_ID>`）
- **Epic**: {{EPIC_TITLE}}（`<HOTFIX_EPIC_ID>`、[README](/<HOTFIX_OBJECTIVE_ID>/<HOTFIX_INITIATIVE_ID>/<HOTFIX_EPIC_ID>/README.md)）

> 本項目は `compose-hotfix` で緊急対応として登録された。階層は設定ファイルの `hotfix.*` で固定。
> 階層フィールドにも同じ値をセットする。

## 発生事象 / 検知経路

<4-2 の入力>

## 影響範囲

- **影響を受けるユーザー / システム**: <4-3 の入力>
- **検知から対応開始までの時間**: <4-3 の入力>
- **業務影響レベル**: <High / Medium / Low>

## 暫定対応（応急処置）

<4-4 のチェックリスト>

## 根本原因（判明している範囲）

<4-5 の入力。空なら「調査中」と記述>

## 恒久対応の要否

<4-6 のチェックボックス>

## タイムライン

| 時刻 | 出来事 |
|------|--------|
| <初期入力 or 登録時刻> | <検知 / 登録> |

## 関連ドキュメント

- **障害レポート / Postmortem**: <空 or 入力>
- **関連 Story / PR**: <空 or 入力>
```

タイトル・本文ともユーザー入力をそのまま展開する。local アダプタにファイルとして書き出す際、シェルを介さずツール（Write/Edit）で書き込むため、シェルメタ文字のエスケープは不要（github（Phase 2）アダプタ側で `gh` に渡す際の取り扱いはアダプタの責務）。

### 7. トラッカーへの登録（抽象操作）

provider に応じたアダプタ（`references/backends/<provider>.md`）の実装で、以下の抽象操作を順に実行する:

1. **`ensure_label`**: 付与するラベルの存在を保証する。
   - `hotfix` ラベル
   - `draft` ラベル（昇格前マーカー）
   - `epic:<HOTFIX_EPIC_ID>` ラベル（Epic 絞り込みタグ）
   - local アダプタでは no-op（ラベルは frontmatter の文字列にすぎない）。github アダプタ（Phase 2）では未存在時に `AskUserQuestion` で「作成する / スキップ」を尋ねてから作成する（勝手にラベルを増やさない）
2. **`create_item(title, body, "story", ["story", "hotfix", "draft"])`**: ステップ 6 の本文で Hotfix 項目を作成する。
   - `item_type`: `story`（hotfix は `story` ラベル + `hotfix` ラベルで表現する。`references/tracker-contract.md` §2・§4）
   - 戻り値は item_ref（local: バンドル絶対パス / github: Issue 番号）
   - local アダプタはこのとき Hotfix md を生成し、`tracker_ref` を書き込み、Hotfix 用 Epic の `log.md` に `Creation` 行を追記する（`references/backends/local.md`）
3. **`add_label(item_ref, "epic:<HOTFIX_EPIC_ID>")`**: Epic 絞り込みタグを付与（`create_item` の labels に含めても可。アダプタの都合に従う）。
4. **`set_field`**: 階層フィールドと初期メトリクスを固定値でセットする（`tracker-contract.md` §3 の正規語彙）:
   - `set_field(item_ref, "objective", <HOTFIX_OBJECTIVE_ID>)`
   - `set_field(item_ref, "initiative", <HOTFIX_INITIATIVE_ID>)`
   - `set_field(item_ref, "epic", <HOTFIX_EPIC_ID>)`
   - `set_field(item_ref, "points", 0)`（緊急対応の性質上、見積もりなしを既定値とする）
   - `set_field(item_ref, "risk_score", 0)`（リスク識別はスキップ）
   - local では frontmatter の対応キーに保存。github（Phase 2）では Projects フィールドに反映。未設定 / 未実装のフィールドはアダプタがスキップし、結果サマリーに表示する（graceful degradation）

> **`draft` ラベルの設計意図**: Hotfix も登録時点では振り返りが未確定であるのが普通である。`draft` を付けることで「これは下書きであり、根本原因確定・恒久対応リンクを経て初めて完了扱いにできる」状態を視覚化する。`draft` の昇格（削除）は `review-stories`（Phase 2）または更新フロー（ステップ 10-4）で行う。

> **見積もり・リスクをスキップする理由**: 緊急対応では「最低限の構造化情報で項目を立て、振り返りは事後に行う」ことを優先する。Points / Risk Score は 0 で初期化し、事後に必要なら手動で `estimate-points` / `identify-risks`（Phase 2）を実行できる（ただし通常は省略してよい）。

### 8. （欠番）

> 旧版では Projects 追加を独立ステップとしていたが、本版では階層フィールドのセットをステップ 7 の `set_field` に統合した（Projects 追加と field 設定は github アダプタが `set_field` の内部で扱う。`references/backends/github.md`）。

### 9. DoD フォローコメントの付与（抽象操作）

`dod` リストが設定ファイルにあれば、Hotfix 本文（暫定対応など）とは分けて **`add_comment` で DoD を付与**する。緊急対応の項目にも DoD は適用される（テスト追加・レビュー取得・ドキュメント更新などはチーム共通の完了基準）。

```
add_comment(item_ref, <DoD 本文>)
```

DoD 本文の組み立て・展開先は `compose-stories` のステップ 9 と同一:

- **local**: 本文末尾の `## Definition of Done` セクションにチェックリストとして展開する（`references/backends/local.md` の `add_comment`）
- **github（Phase 2）**: Issue にフォローコメントとして投稿する（`references/backends/github.md`）

`dod` 未設定 / 空の場合はスキップし、「DoD 未設定のためスキップ。`setup-dod` で登録できる」と案内する（local では本文の見出し直下に `> DoD 未設定。\`setup-dod\` で登録できる。` を 1 行入れる）。

### 10. 既存 Hotfix の更新フロー（item_ref 引数時 / 重複で既存を選んだ場合）

引数が既存 Hotfix の item_ref（local: `*.md` パス / github: `#<number>`）の場合、または重複検出で既存を選んだ場合に実行する。

#### 10-1. 既存項目の取得

**`get_item(item_ref)`** で現状（title / body / fields / labels）を取得する。

#### 10-2. 追記項目の確認

`AskUserQuestion` で「何を追記するか」を選択させる:

- タイムライン追記（時刻 + 出来事を 1 行）
- 根本原因の確定 / 更新
- 暫定対応の進捗（チェックリストの `- [ ]` → `- [x]`）
- 恒久対応 Story のリンク追加（item_ref 入力）
- 関連ドキュメント追加（URL）
- 一般本文の追記（自由記述）

#### 10-3. 本文の更新

該当セクションのみを差分で書き換える。本文を取得 → 該当箇所を編集 → **`update_item(item_ref, {body})`** で反映する。他のセクションは触らない。**全体上書きはしない**（差分提案 → 承認 → `update_item`）。`update_item` は local アダプタでは `updated_at` / `timestamp` の更新と `log.md` への `Update` 行追記を伴う（`references/backends/local.md`）。

#### 10-4. 状態遷移

「Hotfix を完了扱いにしてよいか」を任意で確認する。完了条件:

- 暫定対応のチェックリストがすべて `- [x]`
- 「恒久対応の要否」が「暫定対応で完結」または恒久対応 Story がリンクされている

完了とする場合: `remove_label(item_ref, "draft")` で draft を外す（必要なら `set_field(item_ref, "status", "ready")`）。github（Phase 2）で Issue クローズが必要なら、その操作はアダプタに委ねる。

### 11. 結果サマリー

ユーザーに以下を表示する:

- 新規登録: タイトル / item_ref（local: 書き出し先の絶対パス / github: Issue URL）/ provider / セットしたフィールド一覧 / スキップしたフィールド / DoD コメント付与の有無
- 既存更新: 更新したセクション / item_ref / 状態遷移（完了扱いの有無）
- 失敗: エラー内容と次のアクション

最後に次のアクション候補（Phase 2 で提供予定のものは「提供予定」と添える）:

- 「タイムラインを追記したい」場合は本スキルを item_ref 引数で再実行
- 「恒久対応を Story 化したい」場合は `/compose-stories` を案内
- 「障害傾向を振り返りたい」場合は `list_items({label: "hotfix"})` で一覧を取得
- `sync-stories`: ローカル Hotfix を github トラッカーへアップロードする（**Phase 2**）
- `build-bundle`: OKF バンドルの `index.md` / `log.md` を補完・検証する

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `create_item` / `update_item` / `get_item` / `list_items` / `add_comment` / `set_field` / `add_label` / `remove_label` / `ensure_label` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **provider 別の出力先**:
  - local（既定）: `<hotfix-epic-dir>/<slug>.md`（OKF concept）のみ生成
  - github（Phase 2）: GitHub Issue + Projects 側のみ変更
- **OKF 準拠**: local の Hotfix md は OKF concept として `references/okf-conformance.md` §2 を満たす（パース可能な frontmatter + 非空 `type` + `description`）。内部リンクは **バンドル絶対パス**（§4）。作成時は Hotfix 用 Epic 階層の `log.md` に `Creation` 行を追記（§3）。`index.md` は `build-bundle` の責務
- **緊急対応中はオペレーターの注意力を奪わない**。聞くのはタイトル要約・発生事象・影響範囲・暫定対応の 4 つに絞り、それ以外は事後追記でよいことを明示する
- **階層は設定ファイルの `hotfix.*` で固定**。階層フィールドも固定値をセットする。プロジェクトの命名規約に合わせて `hotfix.*` を変更できる
- **重複登録を防ぐ**ため、登録前に `list_items({label: "hotfix"})` で既存を確認する
- **暫定対応と恒久対応を混同しない**。Hotfix は応急処置の記録、恒久対応は別 Story で本来の Objective / Initiative / Epic 配下に切る
- 見積もり / リスク識別はスキップ。事後に必要なら手動で `estimate-points` / `identify-risks`（Phase 2）を実行できる（ただし通常は省略してよい）
- ラベルが存在しない場合の扱いはアダプタに委ねる（local は no-op、github は作成可否をユーザー確認）。勝手にラベルを増やさない
- 本文を後から書き換える際は、上書きせず該当セクションのみを差分編集する（タイムラインなどは追記式で運用するため）
- 障害発生中はタイトル / 影響範囲が判明していない可能性がある。仮の値で登録し、確定したら更新モードで書き換える運用を推奨する
- 同じ障害が複数の Hotfix に分散しないよう、関連する項目は本文の「関連 Story / PR」セクションに必ずリンクする

### local モード固有の注意

- **ファイル名 slug は kebab-case 英数字のみ**。日本語タイトルの場合はアダプタが英語化案を提示してユーザーに選ばせる（`references/backends/local.md` の `create_item`）。`[Hotfix]` プレフィックスや日付は slug には含めず、要約部分から slug を生成する
- **既存 md と slug が衝突する場合は自動的に `-2` / `-3` を付与**。既存 md を上書きしない
- **frontmatter が常に source of truth**。本文と frontmatter の階層 ID・labels を連動させる
- **DoD は本文末尾の「Definition of Done」セクションに展開**（`add_comment` の local 実装）。github へ同期する際は本セクションをフォローコメントへ振り替える（`sync-stories`（Phase 2）の責務）
- **`tracker_ref` は local アダプタが書き込む**（自身のバンドル絶対パス）。`github_issue` / `uploaded_at` は本スキルでは触らない（`sync-stories`（Phase 2）が github 同期時に書き戻す）
