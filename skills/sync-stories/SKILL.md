---
name: sync-stories
description: **ローカルに書き出された Story md ファイル群（既定の `local` プロバイダで生成された OKF concept）を `github` トラッカーへアップロード（新規作成 or 既存更新）** するスキル。`compose-stories` / `quick-stories` のローカルモードで作成された `<epic-dir>/<story-slug>.md` を読み込み、frontmatter の `resource` / `tracker_ref` が未同期（`null`）なら **新規項目作成**、同期済みなら **既存項目更新** として扱う。アップロード後、frontmatter に `resource`（同期先 Issue URL）/ `tracker_ref` / `uploaded_at` を `resource_uri` 経由で書き戻し、md と同期先を紐付ける。階層フィールドセット（Objective / Initiative / Epic / Points / Risk Score）・DoD フォローコメント投稿（`mode: composed` の場合のみ）も抽象操作で実行する。**`github` アダプタは Phase 2 スタブのため、github 操作の大半は「Phase 2 で提供予定」として graceful degradation で案内する**。引数は 1 件の md パス / Epic ディレクトリ（配下の全 Story md を一括）/ 複数 md パスを受け付ける。「ローカルの Story を GitHub に上げる」「Story md を Issue 化する」「sync する」「ローカル Story をアップロードする」「md と Issue を同期する」「ローカルで設計した Story を GitHub に同期する」「オフラインで作った Story をまとめて起票する」「Epic 配下の md を全部 Issue にする」と言われたら起動する。**frontmatter の同期状態（`resource` / `tracker_ref`）が更新の判定基準** であるため、ユーザーが手動で frontmatter を編集していない限り誤って 2 件作成することはない。
argument-hint: "（任意：Story md ファイルパス / Epic ディレクトリ / 複数 md パス）"
allowed-tools: Read, Edit, Glob, Grep, AskUserQuestion, Bash
---

# sync-stories

ローカル Story md（OKF concept・source of truth）を `github` トラッカーへアップロードする単方向同期スキル。

`compose-stories` / `quick-stories` のローカルモードで作成された Story md を読み込み、`github` アダプタ経由で項目（GitHub Issue）として作成するか既存項目を更新する。アップロード後は md の frontmatter に同期先情報（`resource` / `tracker_ref` / `uploaded_at`）を `resource_uri` 経由で書き戻し、以降は同じ md が「リンク済み Story」として扱われる。

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `create_item` / `update_item` / `get_item` / `set_field` / `add_comment` / `add_label` / `remove_label` / `ensure_label` / `resource_uri` の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド等）は github アダプタ（`references/backends/github.md`）に委譲する。

> **Phase 2 の注記（重要）**: 本スキルの同期先は `github` プロバイダであるが、`github` アダプタは現時点で **スタブ**（`references/backends/github.md`）であり、Issue / Projects / フィールド / コメントの具体手順は未移植である。したがって本スキルの github 操作の大半は **Phase 2 で提供予定** であり、実行時は graceful degradation（`references/tracker-contract.md` §5）で「Phase 2 で提供予定。当面はローカル md（OKF concept）を source of truth として運用する」と案内する。ただし **本スキルの手順自体は抽象操作で完全に記述してある**ため、Phase 2 で `github.md` が実装されればそのまま動作する。あわせて、見積もり・リスクを担う `estimate-points` / `identify-risks`、品質ゲートの `review-stories`、hook 連携（`notify-draft-added.sh`）も Phase 2 以降に提供予定であり、本スキルからは存在しない前提で手順を書かない。

**単方向設計（local → github）**:

- ローカル md を編集 → `sync-stories` でアップロード → github 側の項目が更新される
- 逆方向（github 側を編集 → md に取り込む）は本スキルでは扱わない。github 側で直接編集した内容を md に反映したい場合は、`get_item` で本文を取得して手動で md に転記する運用とする

この設計の理由: 双方向同期はコンフリクト解決が複雑化し、責務がぼやけるため。**leadcraft の source of truth は常にローカル md（OKF concept）側にある**（`references/tracker-contract.md` §6）。github はそこからの同期先であり、`resource` フィールドに同期先 URI を記録することで OKF バンドルが「生きた Issue を指すカタログ」として機能する（`references/backends/github.md`）。

## 想定する利用シーン

- オフラインで `compose-stories --local` を使って Story を設計し終え、まとめて github に起票したい
- 打ち合わせ中に `quick-stories --local` で叩き台 md を量産し、後で github へ投入したい
- ローカル md で `estimate-points` / `identify-risks`（Phase 2）を実行して見積もり・リスクを埋めた後、github 側にも反映したい（既にアップロード済みの md を更新）
- Epic 配下の md を一括で項目化して github 側のボードに並べたい

## 出力

| 項目 | 値 |
|------|----|
| github 項目（Issue） | `create_item` で新規作成 or `update_item` で既存更新。本文は md の本文（frontmatter / HTML コメント除去後）を基に組み立てる。**Phase 2** |
| ラベル | md の frontmatter `labels:` 配列を `add_label` で反映。`epic:<epic-id>` は本スキルが自動付与（`ensure_label` で保証）。**Phase 2** |
| 階層フィールド | `set_field` で `objective` / `initiative` / `epic` / `points` / `risk_score` を frontmatter から反映。**Phase 2** |
| DoD フォローコメント | `mode: composed` の md について、本文末尾の「Definition of Done」セクションを抽出して `add_comment` で投稿（既存があれば再投稿の可否を確認）。`mode: quick` の md ではスキップ。**Phase 2** |
| md frontmatter 書き戻し | `resource`（同期先 Issue URL。`resource_uri` の戻り値）/ `tracker_ref`（github の item_ref）/ `uploaded_at`（ISO 8601）を更新。**この書き戻しは local 側の操作なので Phase 2 でなくても常に実行できる** |

## 前提

- `tracker.github.*` が設定されていること（`references/backends/github.md` の前提。`gh` CLI 認証 + `project` スコープ、owner / project number / field IDs）。未設定の操作は graceful degradation でスキップして警告する（`references/tracker-contract.md` §5）
- 対象 md が `compose-stories` / `quick-stories` のローカルモードで生成された OKF concept であること（frontmatter に `type: story` / `objective` / `initiative` / `epic` / `title` / `labels` を持つ。`references/okf-conformance.md` §2）

## 実行手順

### 1. 対象 md の特定

引数または対話で以下のいずれかを取得:

- **単一 md パス**（例: `<root>/<objective>/<initiative>/<epic>/<story>.md`）
- **Epic ディレクトリ**（例: `<root>/<objective>/<initiative>/<epic>/`）。配下の `*.md` から `README.md`・予約ファイル（`index.md` / `log.md`）を除き、frontmatter の `type: story` を持つもの全件
- **複数 md パス**: 引数を空白区切りで複数指定
- **引数なし**: `AskUserQuestion` で「対象 md のパスまたは Epic ディレクトリを入力」を求める

Epic ディレクトリ指定時は `Glob` で `<dir>/*.md` を列挙し、各 md の frontmatter を `Read` で確認して `type: story` のみ抽出する（`list_items` の local 実装と同じ除外規則。`references/backends/local.md`）。

### 2. 各 md の解析

各対象 md について `Read` し、frontmatter と本文を分離する:

- `frontmatter`:
  - `type`（必ず `story`。違うものはスキップ）
  - `status` / `mode` / `objective` / `initiative` / `epic` / `title` / `description`
  - `points` / `estimation` / `risk_score` / `risks` / `dependencies`
  - `resource` / `tracker_ref` / `uploaded_at`（既存リンクの判定に使用）
  - `labels`
- `本文`: H1 タイトル以降の Markdown。HTML コメント（`<!-- ... -->`）は **除去** する

frontmatter のスキーマ違反（OKF 必須の `type` 欠如・型違反等。`references/okf-conformance.md` §2）が見つかった md はスキップして警告に残す。

### 3. アップロードモードの判定（md 単位）

各 md について、同期状態で以下の 2 つのモードを判定する。判定は frontmatter の `resource` / `tracker_ref`（`null` か否か）と `uploaded_at` を見る:

- `resource: null`（かつ `tracker_ref` が自身のバンドル絶対パスのみ＝未同期）→ **新規項目作成モード**
- `resource` に同期先 URI が入っている → **既存項目更新モード**（その github item_ref を対象とする）

更新モードの場合は `get_item(<github item_ref>)` で対象項目の存在を確認する。項目が見つからない（Close 済み・削除済み・別リポジトリ等）場合は、ユーザーに以下の 3 択を提示:

1. 新規項目として作り直す（frontmatter の `resource` / `tracker_ref` を上書き）
2. 該当 md をスキップ
3. 全体を中止して frontmatter を手動で修正

> **同期状態の表現について**: local の `tracker_ref` は自身のバンドル絶対パス、`resource` は同期前 `null`（`references/backends/local.md` の `create_item` / `resource_uri`）。github 同期後は `resource` に Issue URL（`resource_uri` の戻り値）、`tracker_ref` を github の item_ref（Issue 番号）に更新する。本スキルは「`resource` が null か否か」を新規 / 更新の唯一の判定基準とする。

### 4. 親 Epic README の検証

各 md の親ディレクトリの `README.md` を `Read` し、frontmatter から `objective` / `initiative` / `epic`（ID）を取得。md の frontmatter に書かれた階層 ID と照合し、不一致なら警告して md の値を優先するか Epic README の値を優先するかをユーザーに確認する。

通常は **md の値を信頼する**（compose-stories / quick-stories が Epic README から正しく転記しているはず）。ただし手動編集による不整合が疑われる場合のみ確認する。

### 5. ラベルの構築（抽象操作）

`epic:<epic-id>` を必ず先頭に追加し、`ensure_label` で存在を保証する（github アダプタは未存在時にユーザー確認のうえ作成。`references/backends/github.md`）。md の frontmatter `labels:` 配列の項目を後ろに連結する。

ラベル例（正規語彙。`references/tracker-contract.md` §4）:

```
新規 composed: epic:<epic-id>, story, draft
新規 quick:    epic:<epic-id>, story, quick
更新（既存）:   既存ラベルを保持しつつ、md の frontmatter labels で増減があれば反映
```

更新モードでは `add_label` / `remove_label` で差分を反映する（全消し → 全付け直しは避ける）。`ensure_label` / `add_label` / `remove_label` の github 実装は **Phase 2**。

### 6. 本文の組み立て

md の本文を github 項目の本文として使う。ただし以下の前処理を行う:

- **HTML コメント `<!-- ... -->` を全削除**（マルチライン対応）
- **frontmatter ブロック（先頭 `---` 〜 `---`）を削除**
- **「Definition of Done」セクション全体を抜き出して別変数に保存**（`mode: composed` の場合のみ）。本文側からは「Definition of Done」セクション（見出しから次の見出し直前まで）を削除し、DoD はフォローコメントに分離する（`add_comment`）。local の DoD は本文末尾に保持される設計（`references/backends/local.md` の `add_comment`）なので、ここで本文から切り出してコメントへ振り替える
- **「レビューサマリー」セクション**（`review-stories` が本文末尾に追記したもの）がある場合は、github では `add_comment` でコメントに振り替えるか、そのまま本文に残すかをチーム好みで判断（既定は **コメントへ振り替え**）
- **フッター**（`---` 区切り後の `*Generated by ...*` の 1 行）は保持・差し替え・削除のいずれでも可（既定は **削除**）

整形後の本文を `create_item` / `update_item` に渡す（github アダプタが `--body-file` 等の具体手段に変換する。`references/backends/github.md`）。

### 7. 項目の作成 / 更新（抽象操作）

#### 7-A. 新規項目作成

```
item_ref = create_item(<title>, <整形済み本文>, "story", <ステップ 5 のラベル配列>)
```

戻り値は github の item_ref（Issue 番号）。`resource_uri(item_ref)` で同期先 URI（Issue の HTML URL）を取得する。**Phase 2**（未実装時はスキップして「Phase 2 で提供予定」と案内し、frontmatter 書き戻しもスキップする）。

#### 7-B. 既存項目更新

```
update_item(<github item_ref>, {title?: <title>, body: <整形済み本文>})
# ラベルの差分反映
add_label / remove_label を差分のみ呼ぶ
```

タイトル変更があった場合のみ `title` を渡す（変更がなければ `body` のみ）。`update_item` / `add_label` / `remove_label` の github 実装は **Phase 2**。

### 8. 階層フィールドのセット（抽象操作）

**新規作成時のみ Projects 追加相当の初期化**を行う（既存項目更新時は既に追加済みである前提）。`set_field` で frontmatter の値を反映する（正規語彙。`references/tracker-contract.md` §3）:

```
set_field(item_ref, "objective", <objective-id>)
set_field(item_ref, "initiative", <initiative-id>)
set_field(item_ref, "epic", <epic-id>)
set_field(item_ref, "points", <frontmatter の points>)
set_field(item_ref, "risk_score", <frontmatter の risk_score>)
```

更新モードでも `points` / `risk_score` の **値が frontmatter と github 側で異なる場合は更新する**（Story の正は md 側なので、差分があれば md → github の方向で反映）。`set_field` の github 実装（Projects フィールドへの反映）は **Phase 2**。未設定 / 未実装のフィールドはアダプタがスキップし、結果サマリーに表示する（graceful degradation。`references/tracker-contract.md` §5）。

> **Projects フィールド option のガードレール**: github アダプタの Single Select フィールド option を CLI / GraphQL から書き換える操作はハードブロックされる（`references/backends/github.md` の「ガードレール」。元プラグインの `guard-project-field-mutation.sh` を Phase 2 で移植）。option 追加は Web UI 手動操作のみ許可する。`set_field` が未存在 option に当たった場合は「Web UI で追加 / フィールドスキップ」の 2 択を案内する。

### 9. DoD フォローコメントの投稿（抽象操作）

`mode: composed` の md について、ステップ 6 で本文から抜き出した「Definition of Done」セクションを `add_comment` で投稿する。`mode: quick` の md ではスキップする（quick の方針に合わせる）。

```
add_comment(item_ref, <Definition of Done セクション本文>)
```

既存項目更新時は、過去に投稿された DoD コメントがあるか `get_item(item_ref)`（コメント取得）で確認:

- **過去 DoD コメントなし**: 新規投稿（`add_comment`）
- **過去 DoD コメントあり**: ユーザーに「上書き再投稿 / スキップ / 新規追加」の 3 択を提示。上書き再投稿の場合はアダプタがコメントを置換する（`references/backends/github.md`）

抜き出した DoD が空（チェックリスト項目なし、または `> DoD 未設定...` のプレースホルダーのみ）の場合は投稿スキップ。`add_comment` の github 実装は **Phase 2**。

### 10. md frontmatter の書き戻し（local 側操作・常に実行可能）

アップロードに成功した md について、以下のフィールドを `Edit` で更新する。**これは local md（OKF concept）側への書き込みであり、github アダプタの Phase 2 実装に依存しない**（ただし `resource` に入れる URI は `resource_uri(item_ref)` の戻り値なので、github 操作が成功した場合のみ確定値が得られる。未実装でスキップした場合は書き戻しもスキップする）:

```yaml
# Before（新規作成・未同期）
resource: null
tracker_ref: "/<objective>/<initiative>/<epic>/<story>.md"   # 自身のバンドル絶対パス
uploaded_at: null

# After（同期後）
resource: "https://github.com/<owner>/<repo>/issues/123"      # resource_uri の戻り値
tracker_ref: "123"                                             # github の item_ref（Issue 番号）
uploaded_at: "2026-06-24T12:34:56+09:00"
```

あわせて OKF 標準の `timestamp`（= `updated_at`）を現在時刻に更新し、Epic 階層の `log.md` に `Update: Story <slug> を github に同期` を 1 行追記する（`references/okf-conformance.md` §3）。

`uploaded_at` のタイムスタンプは `date -Iseconds` または `date +"%Y-%m-%dT%H:%M:%S%z"` で取得する（環境による差分は許容）。

frontmatter のその他のフィールド（`type` / `status` / `mode` / 階層 ID / `points` / `estimation` / `risk_score` / `risks` / `dependencies` / `labels` / `title` / `description`）は触らない。

> **OKF クロスリンクとの整合**: `resource` に同期先 Issue URL が入ることで、当該 Story の OKF concept は「生きた Issue を指すカタログ」になる（`references/okf-conformance.md` §2 の `resource` 推奨、`references/backends/github.md` の「OKF との関係」）。`tracker_ref` を github の item_ref に切り替えても、本文内の親 Epic への内部リンクは引き続きバンドル絶対パス（`/` 始まり）で維持する（§4）。

### 11. 結果サマリー

各 md について以下を表示する:

- 新規作成成功: タイトル / 同期先 URI（`resource`）/ セットしたフィールド一覧 / DoD コメント投稿の有無 / 更新後の frontmatter（`resource` / `tracker_ref` / `uploaded_at`）
- 既存更新成功: タイトル / 同期先 URI / 反映した本文・ラベル・フィールドの差分 / DoD コメントの扱い（再投稿 / スキップ / 新規追加）
- スキップ: 理由（`type` 違反 / 階層 ID 不整合で中止 / `resource` が指す項目が見つからず中止 / **github アダプタ未実装（Phase 2）** 等）
- 失敗: エラー内容とリトライ用の手順
- 複数件処理時は **件数集計**（例: 「8 件のうち 7 件成功（新規 5 / 更新 2）、1 件スキップ」）も併記

> **Phase 2 未実装時のサマリー**: `github` アダプタが未移植の現フェーズでは、ステップ 7〜9（create_item / update_item / set_field / add_comment）は graceful degradation でスキップされ、全件が「Phase 2 で提供予定のためスキップ」として表示される。この場合 frontmatter 書き戻し（ステップ 10）も行わない（同期先 URI が確定しないため）。ユーザーには「現状はローカル md（OKF concept）が source of truth として完結している。github 同期は Phase 2 で `github.md` 実装後に利用可能になる」と案内する。

次のアクション候補:

- 見積もり / リスクが未入力の md がある場合: `/estimate-points <md-path>` / `/identify-risks <md-path>`（**Phase 2**）
- アップロード済み Story の品質ゲート: `/review-stories <item_ref>`（`draft` ラベル付きの場合）
- OKF バンドルの目次・履歴を整える: `/build-bundle`

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `create_item` / `update_item` / `get_item` / `set_field` / `add_comment` / `add_label` / `remove_label` / `ensure_label` / `resource_uri` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順は github アダプタ（`references/backends/github.md`）に委譲する
- **本スキルは単方向（local → github）**。github 側で直接編集された内容を md に取り込むのは扱わない
- **github アダプタは Phase 2 スタブ**。Issue / Projects / フィールド / コメントの操作は未移植のため、実行時は graceful degradation で「Phase 2 で提供予定」と案内する（`references/tracker-contract.md` §5、`references/backends/github.md`）。frontmatter 書き戻し（local 側操作）は github 操作が成功した場合のみ行う
- **frontmatter の同期状態（`resource` / `tracker_ref`）が更新の判定基準**。手動で `resource` を書き換えると別の項目を上書きする恐れがあるため、ユーザーが意図的に編集している場合のみ許容する
- **`resource` が指す項目が存在しない場合**は中止確認を行う（誤って関係ない項目を上書きしないため）
- **本文の HTML コメントは項目化時に除去**する。frontmatter の `<!-- ... -->` も含めて削除する
- **`mode: composed` の DoD はフォローコメントに分離**（`add_comment`）、`mode: quick` の DoD は元から書き出されていないため投稿しない
- **タイトルの変更検知**: 更新モードでは frontmatter `title` と github 側の現タイトルを比較し、差があるときのみ `update_item` の `title` を渡す（不要な更新ノイズを避ける）
- **ラベル差分は `add_label` / `remove_label` で反映**（一括置換はしない）。手動で github 側に付けたラベルを誤って消さないため
- **Projects フィールド option 未存在時のハードブロック**（Single Select option の CLI / GraphQL 書き換え禁止、Web UI 手動追加かフィールドスキップの 2 択）は `references/backends/github.md` のガードレール。元プラグインの `guard-project-field-mutation.sh` を Phase 2 で移植し、`provider == github` のときのみ作動させる
- **複数件処理で 1 件失敗しても全体を中止しない**。失敗した md だけ結果サマリーに残し、残りは続行する
- **`uploaded_at` のタイムゾーンはローカル**（実行環境の `date` に従う）
- **同じ Story を 2 回アップロードしない**: frontmatter の `resource` が null の状態で同じタイトルの項目が既に存在する場合（例: ユーザーが手動で起票していた）、新規作成前に `list_items({label: "story"})` 等でタイトル一致の項目があるか軽くチェックし、見つかれば確認する（github 実装は Phase 2）
- **md の frontmatter スキーマ違反は早期スキップ**。安全側に倒すため、不確かな md にはアップロードしない（修正してから再実行を促す。OKF 適合条件は `references/okf-conformance.md` §6）
- **OKF 準拠**: 同期後の frontmatter 書き戻しは OKF concept の適合（パース可能な frontmatter + 非空 `type` + `description` + `resource`）を維持する（`references/okf-conformance.md` §2）。同期で md を更新した際は Epic 階層の `log.md` に `Update` 行を追記する（§3）。本文の親 Epic への内部リンクはバンドル絶対パス（§4）を維持する。`index.md` の更新は `build-bundle` の責務（本スキルは触らない）
- **hook 連携は Phase 2**: Phase 2 で `github` アダプタが `create_item`（draft 付与）を行うと `notify-draft-added.sh`（Phase 2）が発火して `estimate-points` 起動のリマインダーを注入する設計を予定している。ローカルで既に見積もり済みの md をアップロードした場合、見積もりは frontmatter から `set_field` で github 側に反映されているため、hook 側の起動候補は手動で「不要」と判断して進める（hook はあくまでリマインダーであり強制起動ではない）。本フェーズでは hook は移植されていない
