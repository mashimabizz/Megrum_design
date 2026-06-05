# 77. 見た目から逆引きする画面メモ

> 目的: 「今見ている画面が RN のどのファイルか分からない」を解消するための逆引きメモ。
>
> 使い方:
> - いま見えている画面に一番近い行を探す
> - `RN元` と `Swift先` をそのまま指示に貼る
> - 必要なら `近いモック` を開いて視覚的に再確認する

最終更新: 2026-06-01
ステータス: Draft v0.1

---

## まず見る場所

- 下タブが `ホーム / 在庫 / Wish / やりとり / めぐり` なら、ほぼ `mobile/app/(tabs)/...`
- 全画面で戻るボタンがあり、1枚物の詳細画面なら `mobile/app/*.tsx`
- 認証画面なら `mobile/app/(auth)/...`

---

## 主要画面の逆引き

| ぱっと見の特徴 | RN元 | Swift先 | 近いモック |
|---|---|---|---|
| 下タブがあり、最初に開くホーム。カードが何枚も並ぶ。 | `mobile/app/(tabs)/index.tsx` | `ios-native/Sources/MegrumApp/HomeScreen.swift` | `Megrum/Megrum Hub Screens.html` |
| 上に検索条件や絞り込み、下にグッズカード一覧。 | `mobile/app/search.tsx` | `ios-native/Sources/MegrumApp/SearchScreen.swift` | `Megrum/Megrum Search Filter.html` |
| 相手との関係図っぽい。左右に「自分が出す / 相手から受け取る」候補。 | `mobile/app/match-detail.tsx` | `ios-native/Sources/MegrumApp/MatchRelationScreen.swift` | `Megrum/Megrum Home Variations.html` |
| 打診作成の1画面目。`私が出す / 受け取る / 待ち合わせ` の切替。 | `mobile/app/proposal-select.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | `Megrum/Megrum Propose Select.html` |
| 打診作成の確認画面。候補一覧、交換条件タグ、送信ボタン。 | `mobile/app/proposal-confirm.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | `Megrum/Megrum C Flow.html` |
| 下タブ `在庫`。自分のグッズ一覧、譲るものやコレクション表示。 | `mobile/app/(tabs)/inventory.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` | `Megrum/Megrum B Inventory.html` |
| グッズ追加 / 編集。写真、タイトル、カテゴリ、数量などを入れる。 | `mobile/app/goods-editor.tsx` | `ios-native/Sources/MegrumApp/GoodsEditorScreen.swift` | `Megrum/Megrum B Inventory.html` |
| 下タブ `Wish`。欲しいもの一覧、優先度や条件が見える。 | `mobile/app/(tabs)/wishes.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` | `Megrum/Megrum Hub Screens.html` |
| 個別条件を作る / 編集する。希望条件、譲るもの、比率など。 | `mobile/app/listing-editor.tsx` | `ios-native/Sources/MegrumApp/IndividualListingsScreen.swift` | `Megrum/Megrum Hub Screens.html` |
| 下タブ `やりとり`。取引や打診の一覧。 | `mobile/app/(tabs)/transactions.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | `Megrum/Megrum C Flow.html` |
| 取引の詳細。チャット、証跡、承認、評価、遅刻/キャンセル導線。 | `mobile/app/transaction-detail.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | `Megrum/Megrum C Flow.html` |
| 証跡撮影や取引完了に近い画面。写真を撮る / 確認する。 | `mobile/app/transaction-capture.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | `Megrum/Megrum C Flow.html` |
| 下タブ `めぐり`。地図、近くの人、掲示板、グルーム系。 | `mobile/app/(tabs)/encounters.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | `Megrum/Megrum MVP v1.html` |
| 掲示板の一覧。スレッドカードが並ぶ。 | `mobile/app/meguri-board.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | `Megrum/Megrum MVP v1.html` |
| 掲示板スレッド詳細。返信が縦に並び、入力欄が下にある。 | `mobile/app/meguri-board-thread.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | `Megrum/Megrum MVP v1.html` |
| 自分プロフィール。統計、設定導線、編集ボタン。 | `mobile/app/(tabs)/profile.tsx` | `ios-native/Sources/MegrumApp/OwnProfileScreen.swift` | `Megrum/Megrum Hub Screens.html` |
| 相手プロフィール。評価、公開グッズ、打診ボタン。 | `mobile/app/user-profile.tsx` | `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift` | `Megrum/Megrum Account Extras.html` |
| 通知一覧。ベル、未読、通知カード一覧。 | `mobile/app/(tabs)/notifications.tsx` | `ios-native/Sources/MegrumApp/NotificationsScreen.swift` | `Megrum/Megrum Account & Support.html` |
| 設定。通知、プライバシー、ヘルプ、法務文書への導線。 | `mobile/app/help.tsx`, `mobile/app/settings-privacy.tsx`, `mobile/app/notification-settings.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `Megrum/Megrum Account & Support.html` |
| ログイン / 新規登録 / Welcome。認証系の最初の画面。 | `mobile/app/(auth)/welcome.tsx`, `mobile/app/(auth)/login.tsx`, `mobile/app/(auth)/signup.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | `Megrum/Megrum Auth Onboarding.html` |

---

## そのまま使う依頼文

```text
今見ている画面はこれです:
- ぱっと見の特徴: 相手との関係図っぽい。左右に候補が出る

RN元:
mobile/app/match-detail.tsx

Swift先:
ios-native/Sources/MegrumApp/MatchRelationScreen.swift

今回やりたいこと:
RN版の候補選択の挙動をSwiftへ寄せたい。
iOS標準コンポーネント優先、仕様変更なし。

最初にやってほしいこと:
RNとSwiftの差分を3点以内で整理してから、差分1件だけ実装して。
```

---

## 次にやるとよいこと

- 画面を見て迷ったら、このファイルではなく「見た目の特徴」を1行で送る
- こちらで `RN元` と `Swift先` を確定する
- そのあと 1 画面 1 論点で実装指示する
