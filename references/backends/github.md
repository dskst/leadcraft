# トラッカーアダプタ: github（opt-in）

`tracker.provider: github` のときに使うアダプタ。Story を **GitHub Issue + GitHub Projects (v2)** として扱う実装済みアダプタである。

`github` は **opt-in** であり、leadcraft の既定 provider は `local`（外部依存ゼロ）である。OSS のゼロ設定起動は `local` で成立させ、チーム共有・進捗管理を GitHub Projects 中心に乗せたいプロジェクトだけが `github` を選ぶ。

leadcraft の source of truth は常にローカル md（OKF concept）側であり、github アダプタはそこからの **同期先** である。Story の真実は local md にあり、Issue URL を `resource` に、Issue 番号を `tracker_ref` に記録することで、OKF バンドルが「生きた Issue を指すカタログ」として機能する。

抽象操作の定義は `references/tracker-contract.md` を参照。本ファイルは各操作の **github 実装** を、実際に動く `gh` コマンド列で定める。

## 前提

### gh CLI の認証

- `gh` CLI がインストール済みで認証済みであること。未認証なら `gh auth login` を案内する。
- Projects (v2) を操作する `set_field` / `list_items`（Projects 経由）には `project` スコープが必要。未付与なら `gh auth refresh -s project` を案内する。
- Issue のラベル操作・コメント投稿には `repo` スコープが必要（通常 `gh auth login` で付与される）。
- 認証状態は `gh auth status` で確認する。

### 設定（`.claude/leadcraft.md`）

`tracker.github.*` を設定する。`setup-baseline` の同梱テンプレートに雛形がある。

```yaml
tracker:
  provider: "github"   # local（既定）から github に切り替える
  github:
    owner: "<owner>"            # org または user 名（例: <owner>）
    project_number: <project-number>  # Projects (v2) の番号（例: 7）
    project_name: ""           # 任意（人間可読のメモ）
    fields:                    # gh project field-list で取得したフィールド ID
      objective: ""            # Text または Single Select
      initiative: ""           # Text または Single Select
      epic: ""                 # Text または Single Select
      points: ""               # Number
      risk_score: ""           # Number
      status: ""               # Single Select
```

- `fields.*` の値は、後述の `set_field` 内「フィールド ID の解決」で `gh project field-list --format json` から取得した ID を貼る。
- `issue.default_labels`（既定 `["story"]`）も参照する。

### graceful degradation（contract §5）

- `tracker.github.owner` / `tracker.github.project_number` が未設定（空 / `0`）の場合、**Issue 作成までは行い、Projects への追加・フィールド設定はスキップして警告する**。Issue 自体は起票されるため作業は止まらない。
- `tracker.github.fields.<name>` が未設定のフィールドは、`set_field` 時に当該フィールドだけスキップして警告する（他フィールドは処理を続行）。
- `gh` 未認証 / `project` スコープ欠如時は、認証コマンドを案内したうえで、可能な範囲（Issue 作成・ラベル・コメント）だけ実行する。

## item_ref

GitHub Issue 番号（例: `123`）。provider 非依存の不透明な識別子として扱い、OKF concept の frontmatter には `tracker_ref` として保存する。`resource_uri` は Issue の HTML URL。

シェル変数では本ドキュメントを通じて以下を使う:

| 変数 | 由来 |
|------|------|
| `ISSUE_NUMBER` | item_ref（Issue 番号） |
| `ISSUE_URL` | Issue の HTML URL |
| `PROJECT_OWNER` | `tracker.github.owner` |
| `PROJECT_NUMBER` | `tracker.github.project_number` |
| `PROJECT_NODE_ID` | Projects (v2) の node-id（`gh project view` で取得・キャッシュ） |
| `PROJECT_ITEM_ID` | Issue を Projects に追加したときの item ID |

ユーザー入力（タイトル・本文）に含まれるシェルメタ文字（`` ` ``、`$()`、`;`、`&` 等）は、本文を `--body-file`（一時ファイル）経由で渡し、タイトル等はシェル変数経由で渡すことで無害化する。`gh` 実行前にメタ文字を検査し、危険なら警告して中止する。

## 操作の実装

### create_item(title, body, item_type, labels[])

1. 本文 `body` を `mktemp` で一時ファイルに書き出す。

   ```bash
   TMP=$(mktemp -t story-issue.XXXXXX.md)
   # 本文を TMP に書き出す
   ```

2. ラベル CSV を組み立てる。`issue.default_labels`（既定 `story`）+ `item_type` 由来（`hotfix` 等）+ 呼び出し側が渡した正規ラベルを、後述の正規語彙マッピング（§ ラベルの正規語彙）で github ラベル名に変換して連結する。各ラベルは事前に `ensure_label` で存在を保証する。

3. Issue を作成する。タイトルはシェル変数、本文は `--body-file` で渡す。

   ```bash
   gh issue create \
     --title "$STORY_TITLE" \
     --body-file "$TMP" \
     --label "$LABEL_CSV"
   rm -f "$TMP"
   ```

4. 戻り値の Issue 番号を取得する。`gh issue create` は作成した Issue の HTML URL を標準出力に返すため、URL 末尾から番号を抽出する。

   ```bash
   ISSUE_URL=$(gh issue create --title "$STORY_TITLE" --body-file "$TMP" --label "$LABEL_CSV")
   ISSUE_NUMBER="${ISSUE_URL##*/}"   # 例: https://github.com/<owner>/<repo>/issues/123 → 123
   ```

5. item_ref（`ISSUE_NUMBER`）を返す。Projects への追加・フィールド設定は `set_field` の責務（呼び出し側が階層 / Points / Risk Score を順に `set_field` する）。

### update_item(item_ref, {title?, body?})

- 本文を更新する場合は `mktemp` で一時ファイルに書き出し、`--body-file` で渡す。**全体上書きではなく、差分提案 → 承認 → 反映の流れを前提とする**（呼び出し側スキルが本文の対象セクションのみ書き換える）。

  ```bash
  TMP=$(mktemp -t story-edit.XXXXXX.md)
  # 更新後の本文全体を TMP に書き出す
  gh issue edit "$ISSUE_NUMBER" --body-file "$TMP"
  rm -f "$TMP"
  ```

- タイトルを変更する場合のみ `--title` を渡す（変更が無ければ省略してノイズを避ける）。

  ```bash
  gh issue edit "$ISSUE_NUMBER" --title "$NEW_TITLE"
  ```

### get_item(item_ref)

- Issue 本文・タイトル・ラベルを取得する。

  ```bash
  gh issue view "$ISSUE_NUMBER" --json title,body,labels,comments,url
  ```

- 個別フィールドだけ取り出す場合は `--jq` を併用する。

  ```bash
  gh issue view "$ISSUE_NUMBER" --json body --jq .body
  ```

- Projects のフィールド値を取得する場合は、Projects のアイテム一覧から当該 Issue を引く。

  ```bash
  gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    --jq '.items[] | select(.content.number=='"$ISSUE_NUMBER"')'
  ```

  返却 JSON の各アイテムにフィールド値が含まれる。フィールド名は Projects 上の表示名（`Points` / `Risk Score` 等）で参照できる。

### list_items({label?, status?, epic?})

- ラベルで絞る（最も基本的な経路）。`story` ラベル + Epic 絞り込みラベル `epic:<epic-id>` 等を `--label` で AND 指定する。

  ```bash
  # Epic 配下の story を列挙
  gh issue list --label "epic:<epic-id>" --label story --state open \
    --json number,title,body,labels

  # draft 全件
  gh issue list --label draft --state open --json number,title,labels

  # 全 story
  gh issue list --label story --state open --json number,title,body,labels
  ```

- Projects のビュー / フィールドで絞り込む場合は、Projects アイテム一覧を取得して `--jq` でフィルタする（例: `status` フィールドや階層フィールドで絞る）。

  ```bash
  gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    --jq '.items[] | select(.status=="<status>")'
  ```

- `status` 正規概念で絞る場合は、Single Select の表示名（`status` フィールドの option 名）に対応させる。

### add_comment(item_ref, body)

- コメント本文を `mktemp` で一時ファイルに書き出し、`--body-file` で投稿する（メタ文字エスケープを避けるため `--body-file` を徹底）。

  ```bash
  TMP=$(mktemp -t story-comment.XXXXXX.md)
  # コメント本文を TMP に書き出す
  gh issue comment "$ISSUE_NUMBER" --body-file "$TMP"
  rm -f "$TMP"
  ```

- 用途例: DoD フォローコメント（`setup-dod` の DoD をチェックリストで投稿）、review-stories のサマリーコメント。
- 既存コメントを置換したい場合（冪等な再投稿）は、コメント ID を引いて REST API で本文を差し替える。

  ```bash
  # owner/repo を解決
  REPO=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')
  # マーカーを含む既存コメントの ID を探す
  COMMENT_ID=$(gh issue view "$ISSUE_NUMBER" --json comments \
    --jq '.comments[] | select(.body | contains("<!-- review-stories: summary -->")) | .id')
  # 置換（本文は一時ファイル）
  gh api -X PATCH "/repos/$REPO/issues/comments/$COMMENT_ID" -F body=@"$TMP"
  ```

  <!-- TODO: 要検証 — gh issue view --json comments の .comments[].id が REST の issues/comments/<id> エンドポイントで使える数値 ID と一致するか（GraphQL node ID との差異）を環境で確認する -->

### set_field(item_ref, field_name, value)

**本アダプタの中核**。Issue を Projects に追加し、`field_name`（正規語彙）を github の Projects フィールド ID へマッピングして値を設定する。

#### 前段: graceful degradation 判定

- `tracker.github.owner` / `tracker.github.project_number` が未設定なら、**本操作全体をスキップして警告**する（Issue は既に作成済みなので作業は止めない）。

#### 1. Issue を Projects に追加（未追加時のみ）

```bash
PROJECT_ITEM_ID=$(gh project item-add "$PROJECT_NUMBER" \
  --owner "$PROJECT_OWNER" \
  --url "$ISSUE_URL" \
  --format json --jq '.id')
```

既に追加済みの Issue（更新フロー等）は、item-add の代わりに Issue 番号から item ID を逆引きする。

```bash
PROJECT_ITEM_ID=$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
  --jq '.items[] | select(.content.number=='"$ISSUE_NUMBER"').id')
```

Projects 追加に失敗しても登録全体を失敗扱いにせず、Issue 作成までは成功している旨と手動リトライ用コマンドを表示する。

#### 2. Project の node-id を解決（一度だけ取得してキャッシュ）

`item-edit` には Project の node-id が必要。

```bash
PROJECT_NODE_ID=$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id')
```

#### 3. フィールド ID の解決

`field_name`（正規語彙）→ github フィールド ID のマッピングは、まず `.claude/leadcraft.md` の `tracker.github.fields.*` から解決する。

| 正規 field_name | 設定キー | Projects フィールド型 |
|-----------------|----------|------------------------|
| `objective` | `tracker.github.fields.objective` | Text または Single Select |
| `initiative` | `tracker.github.fields.initiative` | Text または Single Select |
| `epic` | `tracker.github.fields.epic` | Text または Single Select |
| `points` | `tracker.github.fields.points` | Number |
| `risk_score` | `tracker.github.fields.risk_score` | Number |
| `status` | `tracker.github.fields.status` | Single Select |

設定にフィールド ID が無い場合（初回セットアップ等）は、`gh project field-list` で一覧を取得して照合する。

```bash
gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json
# 表示名から ID を引く例（Points フィールド）:
FIELD_ID=$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
  --jq '.fields[] | select(.name=="Points").id')
```

解決した ID は `tracker.github.fields.*` に保存して以降は再解決を避ける。`tracker.github.fields.<name>` が未設定でフィールドも見つからない場合は、当該フィールドをスキップして警告する（結果サマリーに「スキップしたフィールド」として表示する）。

#### 4. フィールド型ごとの set 方法

`$FIELD_ID` は解決済みのフィールド ID、`$VALUE` は設定値。

- **Number フィールド**（`points` / `risk_score`）:

  ```bash
  gh project item-edit \
    --id "$PROJECT_ITEM_ID" \
    --field-id "$FIELD_ID" \
    --project-id "$PROJECT_NODE_ID" \
    --number "$VALUE"
  ```

- **Text フィールド**（`objective` / `initiative` / `epic` を Text 型で運用する場合）:

  ```bash
  gh project item-edit \
    --id "$PROJECT_ITEM_ID" \
    --field-id "$FIELD_ID" \
    --project-id "$PROJECT_NODE_ID" \
    --text "$VALUE"
  ```

- **Single Select フィールド**（`status`、または `objective` / `initiative` / `epic` を Single Select 型で運用する場合）:

  まず `gh project field-list` で当該フィールドの option ID を表示名から引き、`--single-select-option-id` で指定する。

  ```bash
  OPTION_ID=$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    --jq '.fields[] | select(.id=="'"$FIELD_ID"'").options[] | select(.name=="'"$VALUE"'").id')
  gh project item-edit \
    --id "$PROJECT_ITEM_ID" \
    --field-id "$FIELD_ID" \
    --project-id "$PROJECT_NODE_ID" \
    --single-select-option-id "$OPTION_ID"
  ```

  該当 option が存在しない場合（例: Epic フィールドに新しい Epic ID を入れたい）は、**CLI / GraphQL からの option 追加は禁止**（後述「ガードレール」参照）。ユーザーに「Web UI で手動追加してから再実行」または「このフィールドをスキップ」の 2 択を提示する。既存 option ID を参照するだけの `item-edit ... --single-select-option-id <ID>` は破壊的でないため許可される。

未設定のフィールド ID はスキップし（エラーにしない）、設定漏れに気づけるよう結果サマリーに表示する。

### add_label / remove_label(item_ref, label)

- ラベルは `add_label` 実行前に `ensure_label` で存在を保証する。

  ```bash
  gh issue edit "$ISSUE_NUMBER" --add-label "$LABEL"
  gh issue edit "$ISSUE_NUMBER" --remove-label "$LABEL"
  ```

- 一括の置換（全消し → 全付け直し）は避け、差分のみ add / remove する（手動で付けたラベルを誤って消さないため）。
- 用途例: `draft` 卒業時に `remove_label(item_ref, "draft")` し、必要なら `add_label(item_ref, "ready")`。`quick` → `draft` 昇格時に `remove_label(item_ref, "quick")` + `add_label(item_ref, "draft")`。

### ensure_label(label, color?)

1. ラベルの存在を確認する。

   ```bash
   gh label list --json name --jq '.[].name' | grep -qx "$LABEL"
   ```

2. 無ければ作成する。**ユーザーに作成可否を確認してから**実行する（勝手にラベルを増やさない）。`color` は正規概念ごとの既定色を使う。

   ```bash
   gh label create "$LABEL" --color "$COLOR" --description "$DESC" || true
   ```

   正規概念ごとの既定色:

   | 正規ラベル | 既定 color | description 例 |
   |-----------|-----------|----------------|
   | `epic:<epic-id>` | `1D76DB` | `Epic: <epic-title>` |
   | `draft` | `FBCA04` | Story がレビュー前のドラフト状態。review-stories で卒業させる |
   | `ready` | `0E8A16` | Story がレビューを通過し、計画に組み込み可能な状態 |
   | `story` / `quick` / `hotfix` | チーム任意（デフォルト色でよい） | 各正規概念に対応 |

### resource_uri(item_ref)

- Issue の HTML URL を返す。OKF concept の `resource` フィールドに記録する。

  ```bash
  gh issue view "$ISSUE_NUMBER" --json url --jq .url
  ```

- `create_item` 実行時に `gh issue create` が返す URL（`$ISSUE_URL`）をそのまま使ってもよい。

## ラベルの正規語彙

contract §4 の正規概念を github ラベルにそのまま対応させる。

| 正規概念 | github ラベル名 |
|----------|-----------------|
| `story` | `story` |
| `draft` | `draft` |
| `quick` | `quick` |
| `hotfix` | `hotfix` |
| `ready` | `ready` |
| `epic:<epic-id>` | `epic:<epic-id>` |

`points` / `risk_score` は **ラベルにしない**（Projects の Number フィールドで管理する）。

## ガードレール: Projects Single Select option の破壊的変更を禁止

GitHub Projects (v2) の Single Select フィールド（Epic / Objective / Initiative / Status などのタグ）の **option を CLI / GraphQL から書き換える操作は、プラグイン同梱の `hooks/guard-project-field-mutation.sh`（`PreToolUse` フック）がハードブロックする**。本フックは `tracker.provider == github` のときに作動する。

ブロック対象（フックが `permissionDecision: deny` を返すコマンド）:

- `gh api graphql` 経由の GraphQL mutation: `updateProjectV2Field` / `createProjectV2Field` / `deleteProjectV2Field` / `updateProjectV2FieldConfiguration`
- `gh project field-create` / `gh project field-delete`

なぜブロックするか:

- これらは見た目が「option 追加」でも、GitHub 側で **内部 option ID を再発番** することがある。
- その結果、既存 Issue のフィールド値の紐付けが解除され（実質リセット）、共有 Project を参照する他ツール / ダッシュボードも壊れる。
- 共有インフラへの不可逆な変更を自動実行するのは事故源でしかないため、スキルからも LLM の自走からも発行を禁止する。**フックを無効化・迂回して回避してはならない**。

許可される操作（フックの対象外。破壊的でないため）:

- `gh project field-list`（既存フィールド / option ID の参照）
- `gh project item-edit ... --single-select-option-id <既存 ID>`（既存 option を Issue にセットするだけ）

option 追加の正しい運用（**Web UI 手動のみ許可**）:

1. GitHub の Project 画面を開く。
2. 該当フィールド（Epic / Objective / Initiative など）の設定 → `+ Add option` で新しい値を追加する。
3. 追加後、本アダプタの `set_field`（`item-edit ... --single-select-option-id <ID>`）で個別 Issue にセットする。

`set_field` が Single Select の option 未存在に当たった場合は、「Web UI で手動追加してから再実行」または「このフィールドをスキップ（後から追いセット可）」の 2 択をユーザーに提示する。

## 設計上の不変条件

- **source of truth は local md（OKF concept）**。github アダプタは同期先であり、Story の真実はローカル md 側にある。`resource` に Issue URL、`tracker_ref` に Issue 番号を記録して双方を紐付ける。
- **Issue 本文の全体上書きをしない**。更新は差分提案 → 承認 → 該当セクションのみ反映の流れを徹底する（起票時の原本性を保つ設計）。
- **見積もり詳細（Points / O / M / P / E / σ）とリスクは Issue 本文の表に保持**し、Projects には集約値（`points` / `risk_score` Number フィールド、`status` Single Select）のみ持たせる。本文の表と Projects フィールドは連動させる（`estimate-points` / `identify-risks` が両方を同時更新する）。
- **graceful degradation を常に守る**。Projects 未設定・フィールド ID 未設定・スコープ欠如のいずれでも、可能な操作（Issue 作成・ラベル・コメント）だけは実行し、不可能な操作はスキップして警告する（contract §5）。
- **Projects Single Select の破壊的変更は不可**。option 追加は Web UI 手動のみ。フックによりハードブロックされる。
