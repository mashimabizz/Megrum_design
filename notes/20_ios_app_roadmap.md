# 20. iOSアプリ化ロードマップ

> 目的：既存Webアプリ版と機能連動する iOS ネイティブアプリを、React Native / Expo で段階的に立ち上げるための実装方針。

最終更新: 2026-05-12（iter154.75）
ステータス: Draft v0.1

---

## 1. 方針

- iOS版は `mobile/` に Expo / React Native / TypeScript で実装する。
- Web版は `web/` の Next.js を継続する。
- Web/iOS は同じ Supabase Auth / DB / Storage に接続し、ユーザー・在庫・Wish・個別募集・打診・取引・チャットを連動させる。
- 状態判定、マッチング優先度、在庫残数、個別募集判定など、挙動ズレが致命的になるロジックは `packages/core/` へ切り出す。
- 色、余白、影などの共通トークンは `packages/design/` へ置く。

## 2. リポジトリ構成

```txt
web/                 # 既存Next.js Webアプリ
mobile/              # Expo / React Native iOSアプリ
packages/core/       # 状態判定・マッチング・共通型
packages/design/     # ブランドカラー・余白・影
packages/supabase/   # Supabase連携の共通補助
supabase/            # migration / seed
notes/               # 設計判断
```

## 3. 技術選定

| 領域 | 採用 |
|---|---|
| iOSアプリ | Expo SDK 54 / React Native / TypeScript |
| ルーティング | Expo Router |
| 認証・DB・Storage | Supabase |
| セッション永続化 | AsyncStorage / SecureStore |
| Push通知 | Expo Notifications + EAS |
| 地図 | `react-native-maps`（iOSはApple Maps優先） |
| 配信 | EAS Build → TestFlight → App Store |

## 4. 最初のPoC範囲

1. Expo Router のタブ/スタック遷移
2. Supabase Auth のセッション永続化
3. プロフィール取得
4. ホームのマッチ候補読み込み
5. 画像表示・画像アップロード
6. Apple Maps ベースの地図表示
7. Expo Push Token 登録

ここまでを「iOS版として成立するか」の技術検証ラインにする。

## 5. 実装順

1. 認証・オンボーディング
2. ホーム
3. マイ在庫
4. Wish
5. 個別募集
6. マッチング詳細・関係図
7. 提示物選択・待ち合わせ
8. 打診一覧
9. 取引チャット
10. 通知・プロフィール・設定

## 6. オーナーに依頼が必要になるもの

必要になったタイミングで個別に依頼する。

- Apple Developer Program 登録
- App Store Connect のチーム権限
- Bundle ID の最終決定（暫定: `tokyo.megrum.app`）
- EAS / Expo アカウント連携
- Supabase staging / production の環境変数
- Push通知の本番運用方針
- App Store 用スクリーンショット・説明文・プライバシー項目

## 7. 現時点の注意

- 生成された最新Expo環境は Node.js `>=20.19.4` を要求する。ローカルは `v20.11.1` だったため、実機開発やEAS前にNode更新が必要。
- Expo Go だけではPush通知や一部ネイティブ挙動の検証に限界があるため、早めに development build を作る。
- Webの Server Actions に入っている重要ロジックは、iOSから直接呼べない。共通化またはRPC/API化を優先する。

## 8. 画面レビュー

レビュー手順は [`notes/21_ios_review_guide.md`](21_ios_review_guide.md) に集約する。
