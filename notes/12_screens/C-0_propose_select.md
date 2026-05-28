# C-0: 提示物選択（Propose Select）

> 打診の準備段階。譲・受け取る・待ち合わせ の3要素をすべて確定してから C-1 に進む。

最終更新: 2026-05-01（iter41）
関連JSX: `Megrum/propose-select.jsx::ProposeSelectScreen`
関連HTML: `Megrum/Megrum Propose Select.html`
関連 iter: 27 / 28 / 29 / 33

---

## 画面の目的

ホーム or 検索からマッチング相手のプロフを見て「打診する」を押した直後の画面。
- **何を出すか**（自分の在庫から）
- **何を受け取るか**（相手の譲一覧から）
- **いつ・どこで会うか**（待ち合わせ）

の3つを1画面（3タブ）でセットアップし、最終確認のメッセージ作成（C-1 propose）に進む。

## 画面ID

このファイルでカバーする 6 variant（`notes/11_screen_inventory.md` 参照）：

| 画面ID | scenario | initialTab | initialMeetupType |
|---|---|---|---|
| `C0-mine-perfect` | `full` | `mine` | （default `scheduled`） |
| `C0-theirs-perfect` | `full` | `theirs` | （default） |
| `C0-forward` | `forward` | `mine` | （default） |
| `C0-backward` | `backward` | `theirs` | （default） |
| `C0-meetup-scheduled` | `full` | `meetup` | `scheduled` |
| `C0-meetup-now` | `full` | `meetup` | `now` |

---

## 入力データ

### Props

```ts
{
  tweaks: BrandColors,                           // 全画面共通のブランドカラー
  scenario: 'full' | 'forward' | 'backward',     // どのマッチタイプから来たか
  initialTab: 'mine' | 'theirs' | 'meetup',      // 初期表示タブ
  initialMeetupType: 'now' | 'scheduled',        // 待ち合わせタブの初期モード
}
```

### React state

```ts
const [tab, setTab] = useState(initialTab);

// 提示物（譲 / 受け取る）
const [myItems, setMyItems] = useState<Item[]>(myInitial);   // 自分の在庫＋selected/selectedQty
const [theirItems, setTheirItems] = useState<Item[]>(theirInitial); // 相手の譲＋selected/selectedQty

// 待ち合わせ
const [meetupType, setMeetupType] = useState(initialMeetupType);  // 'now' | 'scheduled'
const [meetupMinutes, setMeetupMinutes] = useState(15);            // 5/10/15/30
const [selectedAW, setSelectedAW] = useState('aw1');               // AW id or 'custom'
const [customDate, setCustomDate] = useState('');
const [customTime, setCustomTime] = useState('');
const [customLocation, setCustomLocation] = useState('');
const [registerAsAW, setRegisterAsAW] = useState(true);            // ☑ AW自動登録（デフォルトON）
```

### 前画面からの引き継ぎ

- `partner_user_id`：打診先のユーザー
- `match_context`：マッチタイプ（`perfect` / `forward` / `backward`）と triggerアイテム

### データモデル参照

- 自分の在庫：`user_haves WHERE user_id = me AND kind = 'for_trade' AND status = 'available'`
- 相手の譲：`user_haves WHERE user_id = partner AND kind = 'for_trade' AND status IN ('available', 'in_negotiation')`
- 自分のAW：`availability_windows WHERE user_id = me AND status = 'active'`
- 相手と被る AW：`availability_windows` で時空交差判定 → 「★ 相手と一致」バッジ

---

## 表示要素

### ヘッダー（固定）

- 戻るボタン（`<` アイコン）
- タイトル「提示物の選択」＋ 相手情報（`@handle`・★rating・取引N回・距離m）
- ステップバッジ（紫 pill）：`STEP 1/3`
- **3タブ**：
  - 「私が出す」（カウントバッジ：選択数の合計）
  - 「受け取る」（カウントバッジ：選択数の合計）
  - 「待ち合わせ」（バッジ：✓ 緑 or ! warn色）

### 本体（タブごとに切り替え）

#### A. mine タブ（私が出す）

- **シナリオヒント**（`linear-gradient(135deg, lavender, sky)` 背景の小カード）
- **絞込チップ**：すべて／推し別／グッズ種別／★wish一致のみ（横スクロール）
- **アイテムリスト**：
  - 各行：チェックボックス（紫 ON/OFF）＋ サムネ ＋ 名前 ＋ wish一致バッジ ＋ 在庫数
  - 選択時、在庫数 > 1 ならステッパー `[− N/max +]` 表示（iter29）
  - 在庫×1 で選択中は「選択中 ×1」表記のみ
  - チェックON時、selectedQty は max（在庫数）に自動セット

#### B. theirs タブ（受け取る）

- mine と同構造、ただし対象は相手の譲
- 「★ wish 一致」バッジが目立つ（自分のwishと一致）

#### C. meetup タブ（待ち合わせ）

- **モード切替**（紫 pill toggle）：🚀 いますぐ ／ 📅 日時指定
- **🚀 いますぐ モード**：
  - 合流可能時間チップ：5分以内 / 10分以内 / 15分以内 / 30分以内
  - 合流場所カード：場所名（駅・施設）＋ mini map preview ＋ 「変更」ボタン
  - ヒント：「相手が承諾した直後に合流できる距離にいることが前提」
- **📅 日時指定 モード**：
  - **登録済AW radio list**：日時 ＋ 場所 ＋ 「★ 相手と一致」バッジ（被ってる場合）
  - **OR 区切り**
  - **カスタム日時カード**：日付・時刻・場所 ＋ ☑ AW自動登録（デフォルトON、`linear-gradient` 背景）
  - **mini map preview**（選択中 AW or カスタム場所）

### ボトム（固定）

- **提示物 summary**（横並び・3行）：
  - 「あなたが出す ×N枚」 + 商品名サマリ
  - ↔ アイコン
  - 「あなたが受け取る ×N枚」 + 商品名サマリ
- **待ち合わせ summary**：📍 + 待ち合わせ要約（「5/3 (土) 14:00〜」等）
- **CTA**（紫→水色グラデ）：
  - 全条件OK時：`次へ：メッセージ作成 →`
  - 提示物不足：`提示物を両方から選んでください`
  - 待ち合わせ未設定：`待ち合わせを設定してください`

---

## アクション（ユーザー操作と遷移先）

| 操作 | 動作 | 状態変化 |
|---|---|---|
| アイテムタップ | 選択トグル。ON時、selectedQty=max にセット | `myItems`/`theirItems`[i].selected, selectedQty 更新 |
| ステッパー +/- | 数量増減（範囲：1〜在庫数） | `selectedQty` 更新 |
| meetup モード切替 | 🚀 / 📅 のトグル | `meetupType` 更新 |
| 即時：分数チップ | 5/10/15/30 をタップ | `meetupMinutes` 更新 |
| 日時指定：AW radio | リストの中から1つ選択 | `selectedAW = aw.id` |
| 日時指定：カスタム選択 | カスタムカードをタップ | `selectedAW = 'custom'` |
| カスタム：日付/時刻/場所入力 | （実装は OS picker、現状はモック） | `customDate`/`customTime`/`customLocation` 更新 |
| AW自動登録チェック | ☑ トグル | `registerAsAW` 更新 |
| 「次へ：メッセージ作成 →」 | C-1 打診作成画面へ遷移 | `Proposal.status = 'draft'` で記録 |
| 戻る | 1つ前の画面（プロフ or マッチカード） | 状態破棄（draft 保存は要確認） |

### 遷移先

- 次へ → `C1-propose`（c-flow.jsx::ProposeScreen）
- 戻る → ホーム or プロフ（履歴依存）

---

## バリデーション・エラー

### `canProceed` 条件

```ts
const canProceed =
  myCount > 0
  && theirCount > 0
  && meetupSet;

const meetupSet =
  meetupType === 'now'
    ? true                                     // 即時はチップ選択済が前提
    : selectedAW === 'custom'
      ? !!(customDate && customTime && customLocation)
      : true;                                  // 既存AW選択は無条件OK
```

### 表示時のバリデーション

| ケース | 表示 |
|---|---|
| myCount === 0 && theirCount === 0 | CTA: `提示物を両方から選んでください`、disabled |
| myCount === 0 \|\| theirCount === 0 | 同上 |
| 提示物OK、meetup未設定 | CTA: `待ち合わせを設定してください`、disabled |
| 提示物OK、meetup設定済 | CTA: `次へ：メッセージ作成 →`、enabled |

### カスタム日時の必須項目

- 日付 ＋ 時刻 ＋ 場所 のすべてが入力済でないと `meetupSet=false`

---

## エッジケース

| ケース | 挙動 |
|---|---|
| 自分の在庫が空（for_trade なし） | mine タブが空状態：「在庫を登録してください」CTA → B-2 撮影へ |
| 相手の譲が空 | theirs タブが空状態：「相手は譲を登録していません」（実質マッチしないので来ない想定） |
| 自分の AW が空 | meetup タブの 日時指定モード：「カスタム日時のみ表示」+ カスタム自動選択 |
| 相手と被る AW がない | 「★ 相手と一致」バッジは出ない、リスト全部表示 |
| 通信失敗（在庫取得） | エラー表示 + retry ボタン （⚠️ 要確認） |
| 既に同じ相手と negotiating な Proposal がある | C-1.5 へリダイレクト or 警告（⚠️ 要確認） |
| 提示中のアイテムが他のネゴで `in_deal` になった | リアルタイム反映 or 提案送信時にエラー（⚠️ 要確認） |

---

## 関連 API（仮）

⚠️ 要確認（`notes/13_api_spec.md` で確定予定）

| 用途 | エンドポイント案 | メソッド |
|---|---|---|
| 自分の在庫取得 | `/api/items?user_id=me&kind=for_trade&status=available` | GET |
| 相手の譲取得 | `/api/users/:id/items?kind=for_trade` | GET |
| 自分のAW取得 | `/api/aws?user_id=me&status=active` | GET |
| 相手と被るAW判定 | `/api/aws/intersect?user_id_a=me&user_id_b=:partner` | GET |
| Proposal 作成（draft）| `/api/proposals` | POST（status=draft） |
| Proposal 送信 | `/api/proposals/:id/send` | POST |

### Proposal 作成時の payload（仮）

```json
{
  "receiver_id": "uuid",
  "match_type": "perfect",
  "sender_have_ids": ["uuid", ...],
  "sender_have_qtys": [2, 1],
  "receiver_have_ids": ["uuid", ...],
  "receiver_have_qtys": [3],
  "message": "（C-1 で書く）",
  "meetup_type": "scheduled",
  "meetup_now_minutes": null,
  "meetup_scheduled_aw_id": "uuid",
  "meetup_scheduled_custom": null
}
```

または `meetup_scheduled_aw_id=null` ＋ `meetup_scheduled_custom={...}` のどちらか。

`register_as_aw=true` の場合、サーバ側で AW を `created_via='auto_from_proposal'` で同時作成 → その id を `meetup_scheduled_aw_id` にセット。

---

## 状態遷移（09 との対応）

C-0 で「次へ」を押した時点で：
- `proposals.status = 'draft'` でDB登録（or 送信時まで遅延）⚠️ 要確認
- 「打診を送る」（C-1）後 → `status = 'sent'`

`09_state_machines.md` §1 Proposal Lifecycle の `[*] → draft → sent` に対応。

---

## 関連 docs

- [`notes/05_data_model.md`](../05_data_model.md) §1 マスタ / §3 user_haves / §4 aws / §5 proposals
- [`notes/09_state_machines.md`](../09_state_machines.md) §1 Proposal Lifecycle
- [`notes/10_glossary.md`](../10_glossary.md) §E マッチング / §F 場所・時間
- [`notes/11_screen_inventory.md`](../11_screen_inventory.md) §B-1 C-0
- [`notes/08_design_iterations.md`](../08_design_iterations.md) iter27/28/29/33

---

## 未確定項目

| # | 項目 | 解決時期 |
|---|---|---|
| 1 | draft Proposal を DB に保存するタイミング（即時 or 送信時） | API spec 確定時 |
| 2 | 既存ネゴある相手への新規打診の振る舞い | 実装フェーズ |
| 3 | 通信失敗時のリトライUI | 実装フェーズ |
| 4 | 提示中アイテムの状態変更（他者ネゴで `in_deal`）の同期 | 実装フェーズ |
| 5 | meetup `now` モードでの「合流場所」をどう決めるか（GPS現在地？固定？） | 設計詰め |
