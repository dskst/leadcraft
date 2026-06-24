---
name: setup-baseline
description: フィボナッチ見積もりの基準点（2pt/8pt）となる代表Storyをユーザーから引き出し、プロジェクト設定ファイル（.claude/leadcraft.md）に保存する。トラッカー非依存（既定 local、github は opt-in）。「見積もりの基準を決めたい」「baselineを設定する」「ストーリーポイントの基準を作る」「2と8のリファレンスを登録する」と言われたら起動する。
argument-hint: "（任意：基準点の説明やリセット指示）"
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Bash
---

# setup-baseline

leadcraft プラグインの見積もり基準点（2pt と 8pt の代表 Story）を対話的に登録するスキル。
Story の保存先は `tracker.provider` によって異なる（既定 `local`、opt-in で `github`）が、
本スキルは**トラッカーへのアクセスを行わない**。設定ファイルの編集のみに閉じる。

## 役割

フィボナッチによるストーリーポイント見積もりは「相対見積もり」であり、基準となる
代表 Story を最初に決めることで他 Story の見積もりが安定する。このスキルは
ユーザーから 2pt と 8pt の代表 Story を引き出し、設定ファイルに保存する。

## 設定ファイルの場所

| 項目 | 値 |
|------|----|
| 設定ファイル | `.claude/leadcraft.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/setup-baseline/templates/leadcraft.md` |

設定ファイルをチーム共通設定としてコミットする場合は、`tracker.*` など個人固有の値を
含まないことを確認してからコミットする。

## 実行手順

### 1. 既存設定の確認

`.claude/leadcraft.md` が存在するか確認する。

- 存在する場合: 現在の baseline を表示し、上書きするか確認する
- 存在しない場合: `${CLAUDE_PLUGIN_ROOT}/skills/setup-baseline/templates/leadcraft.md` を読み込んで雛形にする

### 2. 基準点の引き出し

AskUserQuestion で 2 つの基準点を順に確認する。

**2pt 基準点の質問例**:
- 「2pt の代表 Story として登録する作業内容を教えてほしい。
  ヒント: 半日〜1日で完了、技術的に明確、依存関係が少ない、レビュー含めて1サイクルで終わる規模」

**8pt 基準点の質問例**:
- 「8pt の代表 Story として登録する作業内容を教えてほしい。
  ヒント: 数日〜1週間程度、複数ファイルに渡る変更、設計判断を含む、外部依存を1〜2件含む規模」

ユーザーが「過去の事例を提案してほしい」と言った場合、
プロジェクト内のドキュメント・コミット履歴・既存 Story ファイルから候補をいくつか提示してもよい
（`tracker.provider` が `local` の場合は OKF バンドル内の Story md を参照する）。

### 3. 設定ファイルへの保存

`.claude/leadcraft.md` に以下のフォーマットで保存する。

```yaml
baseline:
  small:
    points: 2
    reference_story: "（ユーザー入力した代表Story名）"
    description: "（補足説明）"
  large:
    points: 8
    reference_story: "（ユーザー入力した代表Story名）"
    description: "（補足説明）"
```

ファイルが存在しない場合は、雛形（`${CLAUDE_PLUGIN_ROOT}/skills/setup-baseline/templates/leadcraft.md`）をコピーしてから baseline 部分を更新する。
存在する場合は baseline セクションのみを更新し、他の設定は保持する。

### 4. 結果の表示

保存内容をユーザーに表示し、必要に応じて以下を案内する:
- 他のフィボナッチ点（1, 3, 5, 13, 21）も登録したい場合は `additional_baselines` を手動追加できる
- 基準点を変更したくなったら再度このスキルを実行できる
- DoD（完了の定義）を設定したい場合は `/setup-dod` を実行できる
- 次のステップとして `/compose-stories` で要件分解に進める

## 注意事項

- 基準点は「客観的な事実」ではなく「このチーム/このプロジェクトでの相対基準」である
- ユーザーが基準点を即答できない場合、無理に押し出さず「あとで決めてもよい」と促す
- `.claude/` ディレクトリが存在しない場合は `mkdir -p` で作成する（事前にユーザーに作成可否を確認）
- 既存の `.claude/leadcraft.md` の他のキー（`output` / `tracker` / `okf` / `dod` 等）は絶対に消さない
- トラッカーへの書き込み（Issue 作成等）は本スキルの責務外。`tracker.provider` の値は読まない
