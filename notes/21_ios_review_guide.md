# 21. iOSアプリ画面レビュー手順

> 目的：iOSアプリ版の画面をオーナーが実機またはSimulatorで確認するための手順。

最終更新: 2026-05-12（iter154.90）
ステータス: Draft v0.2

---

## 1. 事前準備

### Node.js

Expo SDK 54 / React Native 0.81 系は Node.js `>=20.19.4` を要求する。

```bash
nvm use
```

`.nvmrc` に `20.19.4` を指定済み。

### iPhone実機で見る場合（Expo Go）

1. iPhone に Expo Go をインストールする
2. PC と iPhone を同じ Wi-Fi に接続する
3. PCで開発サーバを起動する
4. 表示されたQRコードを iPhone のカメラまたは Expo Go で読む

```bash
npm run mobile:start
```

### iPhone実機で見る場合（Development Build）

Expo Go のQR読み込みを毎回やりたくない場合は、Megrum専用の開発版アプリをiPhoneに入れる。

初回だけ、以下が必要：

- Expo account
- EAS CLI
- Apple Developer account（実機iPhoneへ入れる場合は署名に必要）
- iPhoneのDeveloper Mode有効化（iOS 16以降）

```bash
cd /Users/michitaka/Desktop/Claude/Goods_exchange_platfform_Megrum/mobile
npm install -g eas-cli
eas login
eas build --platform ios --profile development
```

ビルドが完了すると、Expoのページにインストール用リンクが出る。iPhoneでそのリンクを開いて Megrum をインストールする。

インストール後の普段のレビューは以下：

```bash
cd /Users/michitaka/Desktop/Claude/Goods_exchange_platfform_Megrum
git pull
cd mobile
npm run start:dev
```

iPhone側は、ホーム画面の **Megrum** アプリを開く。QRを毎回読む必要はない。

ネイティブ依存を追加・変更した時だけ、開発版アプリを作り直す。

### iOS Simulatorで見る場合

MacにXcode / iOS Simulatorがある場合：

```bash
npm run mobile:ios
```

Development BuildをSimulatorで見る場合：

```bash
cd /Users/michitaka/Desktop/Claude/Goods_exchange_platfform_Megrum/mobile
eas build --platform ios --profile development-simulator
```

---

## 2. Supabase連携ありで見る場合

`mobile/.env.local` を作成し、以下を入れる。

```bash
EXPO_PUBLIC_SUPABASE_URL=...
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=...
```

値は Web版と同じ Supabase project の公開URLと publishable key を使う。秘密鍵は入れない。

環境変数を変更したら、Expo server を再起動する。

---

## 3. 現時点で確認できる画面

- ログイン画面
- Supabase未設定時の案内表示
- Supabase未設定時の「画面だけプレビューする」導線
- ログイン済み時のタブ画面
- ホーム
- マイ在庫
- Wish
- 打診・取引
- プロフィール

---

## 4. レビュー時に見る観点

- iOSらしい画面遷移になっているか
- タブの位置・文字サイズ・押し心地が自然か
- Web版と同じ情報構造として理解できるか
- ログイン前後の導線に違和感がないか
- 画面上の言葉が Megrum の用語とズレていないか

---

## 5. まだExpo Goだけでは確認しづらいもの

- Push通知の本格検証
- App Store配信用のcredentialまわり
- 一部のネイティブ権限挙動

これらは EAS development build / TestFlight の段階で確認する。

---

## 6. トラブルシューティング

### `Could not connect to the server`

Mac と iPhone が同じ Wi-Fi にいても、LAN接続が通らないことがある。その場合は tunnel で起動する。

```bash
cd /Users/michitaka/Desktop/Claude/Goods_exchange_platfform_Megrum/mobile
npx expo start --tunnel --clear
```

`@expo/ngrok` のインストール確認が出たら `y` を押す。

### `ENOENT: no such file or directory, watch .../node_modules`

monorepo の root `node_modules` が無い環境で Metro が監視しようとした時のエラー。

`mobile/metro.config.js` で存在しない watch path を除外するようにしているため、最新版を取得したうえで再起動する。

```bash
cd /Users/michitaka/Desktop/Claude/Goods_exchange_platfform_Megrum
git pull
cd mobile
npx expo start --tunnel --clear
```
