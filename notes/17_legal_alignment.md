# 17. 法的文書 整合性管理（Legal Alignment）

> **目的**：弁護士納品の規約原典（2024-07-18）と現行 Megrum 設計の関係を整理。
> iter47 では「docx 改訂不要・現行規約をそのまま運用」方針だった。2026-05-31時点の初回提出は現地交換MVPへ再固定していたが、2026-06-28時点の現行Swift Native実装では郵送交換・住所開示経路が復活し、2026-06-29時点では会員間支払い情報・銀行口座情報、顔検出・顔候補付けデータ、APNs通知本文、カスタムURL scheme・認証リダイレクト・ディープリンク、Keychain session保存、退会申請・削除予定日、公開プロフィール・性別・活動エリア・年齢表示、評価・通報・ブロック・モデレーション、削除申出・送信防止措置、Storage公開範囲、署名URL、外部AI画像送信の保存/表示/運用経路も確認したため、本メモ上部の追記を優先する。

最終更新: 2026-07-03（公開前チェック / Megrum Plus IAPチェックイン既定OFF / AdMobチェックイン既定OFF / 退会申請時通知device失効 / meguri-board-media Storage policy縮小 / 近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / 運営通知・通知本文統制 / StoreKit・IAP販売可否・復元失敗 / IAP App Privacy同期 / 公開法務ページ同期No-Go / 現行Swift NativeのStorage公開範囲・署名URL / 公開プロフィール・性別・活動エリア・未成年・生年月日・年齢表示・広告年齢制限 / 評価・通報・ブロック・モデレーション / UGC・App Review 1.2 / App Store評価・公開レビュー返信 / 漏えい等初動・事故疑い / 広告宣伝メール・販促通知 / 公式連絡・フィッシング / 削除申出・送信防止措置 / サポートSLA・専門助言非保証 / 退会申請・削除予定 / 郵送交換 / 会員間支払い情報 / 待ち合わせ候補・日程公開 / 緊急時・安全対応非代替 / 会場・施設ルール / 有料権限・ブースト非決済手段 / UserDefaults・端末内ローカル設定 / 国外移転・外国第三者提供・国外アクセス / 登録禁止グッズ・規制物品 / 第三者SDK・OSSライセンス / 顔候補付け / APNs主線・legacy Expo条件付き・Push通知4.5.4 / AdMob実設定・ATT・テスト広告・広告通報 / StoreKit / TestFlight・ベータ機能 / 責任上限・利用者補償・存続条項 / UGC削除後利用 / 会員間支払い税務責任 / 運営者情報開示 / 外部AI送信 / 外部画像URL / 写真メタデータ / カメラ・写真ライブラリ・共有シート / カスタムURL scheme・認証リダイレクト・ディープリンク / Keychain・session保存・refresh token / MapKit・CoreLocation・精密位置・逆ジオコーディング / 公式非提携・権利物 / 古物営業・チケット不正転売 / EU DSA・配信地域 / ホーム候補・検索・レコメンド・Product Personalization / Apple標準EULA方針を規約・プライバシーポリシーへ反映）
ステータス: 弁護士納品原典を保持しつつ、現行仕様ベースの規約・プライバシーポリシードラフトを管理

---

## 2026-07-03 追記：Megrum Plus IAPチェックイン既定を提出安全側へ変更

- `ios-native/Config/MegrumNative.xcconfig` に `MEGRUM_PLUS_IAP_ENABLED=NO` を追加し、Info.plistの `MegrumPlusIAPEnabled` へ渡すようにした。Release build settingsでも `MEGRUM_PLUS_IAP_ENABLED=NO` を確認した。
- `MegrumPlusRuntimeConfiguration` は、環境変数又はInfo.plistに `1`、`true`、`yes`、`on` が明示される場合だけIAPを有効化する。未設定、空文字、`$(MEGRUM_PLUS_IAP_ENABLED)` のような未解決placeholderは無効として扱う。
- `SubscriptionSettingsScreen` はIAP無効時にStoreKitの商品情報照会、購入、復元を早期停止し、`SubscriptionSettingsContent` は購入ボタンと復元ボタンを表示せず「購入機能は公開準備中です」と表示する。既存の状態更新、サーバー由来の有料権限表示、DEBUG用の権限切替は別扱いで残す。
- 初回提出で有料機能を出す場合は、local/CI設定で `MEGRUM_PLUS_IAP_ENABLED=YES` を明示したうえで、App Store Connect商品、価格、IAP Availability、公開特商法、FAQ、Review Notes、Purchases回答、Server API検証、Server Notifications、返金/取消/期限切れ/請求失敗同期、手動有料権限上書きとの区別を再確認する。
- 新規購入導線を既定停止しても、既存権限、手動上書き、退会申請時の購読案内、削除完了時の権限停止、将来IAP有効化時の返金/取消/期限切れ同期は未解決のままなので、公開前No-Goとして残す。

---

## 2026-07-03 追記：AdMobチェックイン既定を提出安全側へ変更

- `ios-native/Config/MegrumNative.xcconfig` のチェックイン既定を、`MEGRUM_ADS_ENABLED=NO`、`MEGRUM_ADMOB_APP_ID` 空、production ad unit id空、test ad unit id空、`MEGRUM_ADMOB_TEST_ADS_ENABLED=NO` に変更した。
- `xcodebuild -project ios-native/MegrumNative.xcodeproj -scheme MegrumNative -configuration Release -showBuildSettings` で、Releaseの `MEGRUM_ADS_ENABLED=NO` と `MEGRUM_ADMOB_TEST_ADS_ENABLED=NO` を確認した。Debugはtarget overrideで `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` が残るが、`MEGRUM_ADS_ENABLED=NO` のため既定では `MobileAds.shared.start()` の起動条件を満たさない。
- `ios-native/Config/MegrumNative.local.xcconfig.example` に、広告検証時だけlocal configへ明示的に埋めるAdMob項目を追加した。広告を初回提出で出す場合は、local/CI設定で明示的に有効化し、Google公式データ開示、SDK Privacy Manifest、App Privacy回答、ATT/IDFA/Tracking回答、UMP同意管理要否、test ads除去、広告通報導線を実ビルドと一致させる。
- Google Mobile Ads SDKのSwiftPM依存、Xcode link、Info.plistのAdMob/SKAdNetwork項目は残るため、広告を出さない提出でも、実機又は審査ビルドでSDK初期化と広告リクエストが発生しないこと、App Store Connect回答と公開Privacyが矛盾しないことは提出前確認に残す。

---

## 2026-06-29 追記：近距離公開・作成位置情報を補強

- 現行Swift Nativeでは、`MegrumLocationState` が `CLLocationManager` を `kCLLocationAccuracyNearestTenMeters`、`distanceFilter = 10` で使い、`CLGeocoder.reverseGeocodeLocation` で座標を場所名へ変換する。
- 取引チャットでは `messages.message_type = 'location'` が `location_lat`、`location_lng`、`location_label` を保存し、`TradeLocationPreviewBubble` は地図プレビューと緯度/経度表示を出す。服装写真は `outfit_photo`、到着状況は `arrival_status` として追記型メッセージに保存され、参加者だけが読めるRLSだが、相手保存、通知、署名URL、端末キャッシュ、スクリーンショットを完全防止できない。
- 打診作成では待ち合わせ候補が `startAt`、`endAt`、`placeName`、`lat`、`lng` を持ち、UI下書きは最大5件、送信payloadは有効候補を最大3件に丸める。現地交換モードは `user_local_mode_settings.last_lat/lng` と `activity_windows.center_lat/lng`、半径、有効時間を保存する。
- めぐりでは `groom_posts.origin_lat/lng` と `meguri_board_threads.origin_lat/lng`、閲覧者lat/lng、公開範囲を用いて近距離表示、閲覧、返信可否を判定する。Swift側は詳細閲覧/作成で1km制限を使う一方、RPC/一覧には3km系の互換判定が残るため、法務文言は「1km/3kmは安全・匿名保証ではない」と整理する。
- 利用規約第15条へ、近距離公開、1km、3km、同じ都道府県、同じスポット等が匿名化、秘匿化、安全確認、本人確認、所在確認、ストーカー防止又は推測防止を保証しないこと、自宅、学校、勤務先、宿泊先、座席番号、未成年者の居場所等を入力、投稿又は共有しないことを追加した。
- プライバシーポリシー第2.5条、第2.6条及び第13条へ、グルーム/掲示板の作成座標、閲覧者座標、距離、公開範囲、現地交換モード最終座標、活動ウィンドウ中心座標、保持/削除例外を追加した。
- 公開前No-Go: Precise Location、App Privacy、FAQ、Review Notes、アプリ内コピーで、現在地共有、近距離投稿、現地交換モード、待ち合わせ候補、グルーム、掲示板が見えるのに、精密座標、作成位置、閲覧者座標、保持例外、推測リスク、地図サービス送信、緊急対応非代替を説明しない状態では提出しない。

参照:
- `ios-native/Sources/MegrumApp/MegrumLocationState.swift`
- `ios-native/Sources/MegrumApp/TradeDetailScreenActions.swift`
- `ios-native/Sources/MegrumApp/TradeMessageSendIntents.swift`
- `ios-native/Sources/MegrumApp/TradeOperationalMessagePresentation.swift`
- `ios-native/Sources/MegrumApp/TradeMessageBubbleContentParts.swift`
- `ios-native/Sources/MegrumData/SupabaseMessageRows.swift`
- `ios-native/Sources/MegrumData/SupabaseMessageClientSends.swift`
- `ios-native/Sources/MegrumData/SupabaseMessagePayloadBuilder.swift`
- `ios-native/Sources/MegrumData/SupabaseProposalPayloads.swift`
- `ios-native/Sources/MegrumApp/ProposalCreateMeetupModels.swift`
- `ios-native/Sources/MegrumApp/ProposalMeetupPlaceSheet.swift`
- `ios-native/Sources/MegrumApp/SupabaseHomeLocalModePersistence.swift`
- `ios-native/Sources/MegrumApp/HomeLocalModeSettingsContent.swift`
- `ios-native/Sources/MegrumApp/MeguriAccessPolicy.swift`
- `ios-native/Sources/MegrumData/SupabaseBoardClient.swift`
- `ios-native/Sources/MegrumData/SupabaseBoardRows.swift`
- `ios-native/Sources/MegrumData/SupabaseGroomPayloads.swift`
- `supabase/migrations/20260503210000_add_messages.sql`
- `supabase/migrations/20260503120000_add_local_mode_settings.sql`
- `supabase/migrations/20260506100000_add_proposal_meetup_candidates.sql`
- `supabase/migrations/20260627090000_enhance_meguri_groom_board.sql`
- `supabase/migrations/20260628063000_add_meguri_board_create_rpc.sql`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`

---

## 2026-06-29 追記：会員間支払い・金融規制境界を補強

- 現行Swift Nativeでは、支払い方法設定画面で銀行振込、PayPay、現金交換、その他を選択できる。銀行振込を選ぶ場合、銀行名、支店名、口座種別、口座番号、口座名義の入力が必須で、`PaymentSettingsDraft` は口座番号を数字だけに正規化し、本人向けプレビューでは末尾4桁以外をマスクする。
- `user_payment_settings` は本人だけが読み書きできるRLS付きテーブルで、取引前の候補表示には `users.payment_methods` / `users.payment_note` の要約を使い、銀行口座詳細は公開プロフィール又はホーム候補の通常selectへ混ぜない設計になっている。
- 金額指定取引が合意成立した場合、`respond_to_proposal_for_viewer` は `user_payment_settings` から `proposals.sender_payment_settings` / `receiver_payment_settings` へ、成立時点の支払い情報スナップショットをコピーする。取引詳細では、相手の支払い方法、銀行名、支店名、口座種別、口座番号、口座名義を成立後の当事者向けシートに表示する。
- 現行コード上、PayPayは「リンク登録なし。対応可否だけを表示します」として扱われ、送金リンク又はQRコード登録の専用欄はない。一方、その他メモや取引チャットに外部ID、送金リンク、QRコード等が入力される可能性を、禁止・注意・サポート文面側で抑える必要がある。
- 2026-06-29に公式情報を確認したところ、財務省関東財務局の資金移動業ページは、資金移動業を「銀行等の預金取扱等金融機関以外の一般事業者が為替取引を業として営むもの」と整理し、事前登録が必要であること、2026-06-01施行・適用の改正でクロスボーダー収納代行にも資金移動業規制が適用され得ることを案内している。Megrumは現行仕様上、資金の受領、保管、送金、収納代行、回収、返金、チャージバック、エスクローへ踏み込まず、会員間支払い情報の表示補助に留める前提で文言を保守的に固定する。
- 利用規約第14条へ、取引成立後に当事者へ支払い方法、銀行名、支店名、口座種別、口座番号、口座名義、金額指定その他成立時点の支払い情報スナップショットが表示され得ること、及び相手会員による保存、スクリーンショット、転記又は外部サービス上での利用を運営者が完全に防止できないことを追加した。
- 同条へ、Megrumが資金の受領、保管、送金、収納代行、立替、精算、返金、チャージバック対応、本人確認、口座名義確認、信用審査、支払能力確認、残高確認、債権回収、前払式支払手段の発行、資金移動、暗号資産交換、金融商品取引又はエスクローを行わないことを追加した。
- プライバシーポリシー第2.4条、第5条、第6条及び第10条へ、支払い情報スナップショット、外部ID、送金リンク又はQRコードを含み得るメモ、口座名義確認非保証、支払い設定変更後も合意済み取引のスナップショットを必要範囲で保持することを追加した。
- 公開ページ、FAQ、App Privacy、保持削除表、外部サービス台帳、セキュリティ監査、アプリ内コピー、App Store提出文面では、支払い設定、銀行振込、口座番号入力、口座名義、金額指定取引又は合意後の支払い情報表示を出す場合、Financial Info / Payment Info、目的外利用禁止、参加者限定表示、成立後スナップショット保持、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/決済代行/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR真正性確認の非保証を必須確認にする。
- 公開前No-Goとして、現行Webの短縮Terms/Privacyを正式URLとして提出し、成立後支払い情報スナップショット、口座番号表示、外部決済非関与、送金リンク/QRコード注意、Payment Info回答を説明しない状態を追加する。

参照:
- `ios-native/Sources/MegrumApp/PaymentSettingsScreen.swift`
- `ios-native/Sources/MegrumApp/PaymentSettingsDraft.swift`
- `ios-native/Sources/MegrumApp/PaymentSettingsMethodViews.swift`
- `ios-native/Sources/MegrumApp/TradeAgreementDisclosureSheet.swift`
- `ios-native/Sources/MegrumApp/TradeAgreementAfterDealViews.swift`
- `ios-native/Sources/MegrumApp/TradeDetailScreenDerivedState.swift`
- `ios-native/Sources/MegrumCore/UserPaymentModels.swift`
- `supabase/migrations/20260613090000_add_user_payment_settings.sql`
- `supabase/migrations/20260626004000_add_proposal_payment_snapshots.sql`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- e-Gov 資金決済に関する法律: https://laws.e-gov.go.jp/law/421AC0000000059
- 財務省関東財務局 資金移動業関係: https://lfb.mof.go.jp/kantou/kinyuu/pagekt_cnt_20250516001sikinidou.html
- 金融庁 令和7年資金決済法改正に係る政令の公布及びパブリックコメント結果等: https://www.fsa.go.jp/news/r7/sonota/20260522/20260522.html

---

## 2026-06-29 追記：手動有料権限・権限上書き境界を補強

- 現行Web管理画面では、`billing.read` 権限で `subscriptions`、`user_entitlements`、`plan_overrides` を閲覧し、`entitlements.manage` 権限で有料権限の手動上書きを行える。フォームは対象ユーザー、feature key、active/inactive、任意の期限、理由を受け付ける。
- `setManualEntitlement` は対象ユーザーを user ID、handle又はemailから解決し、`plan_overrides` に `feature_key`、`active`、`reason`、`expires_at`、`created_by` を挿入し、`user_entitlements` を `source = 'manual_override'`、`override_id`、`metadata.reason` 付きでupsertする。監査ログには `entitlement.manual_override`、理由、変更前後、override_id等が残る。
- Swift Native側の有料判定は `user_entitlements` を参照し、`UserEntitlementSource` には `subscription`、`manual_override`、`system`、`purchase` がある。したがって、App Store購入由来の権限と、サポート又は運営対応による手動権限が同じ最終権限テーブルを通じて機能表示に影響し得る。
- 利用規約第7条へ、問い合わせ対応、購入又は復元の同期不具合、返金、取消、チャージバック、請求失敗、キャンペーン、トライアル、障害対応、不正利用調査、規約違反対応、アカウント制限、セキュリティ対応、会計又は法令対応、検証、公開前テストその他運営上必要な場合に、有料権限を手動で付与、停止、有効化、無効化、期限設定、修正、復旧、取消又は調整できることを追加した。
- 同条へ、手動付与、一時表示又は暫定対応が、購入完了、返金、補償、無償提供の継続、販売継続、利用資格又は将来の権限維持を保証しないこと、運営者が事実確認、アプリストア又は指定決済事業者の記録、法令、規約、会計処理又は安全上の必要に応じて撤回、訂正、停止又は再調整できることを追加した。
- プライバシーポリシー第2.9条、第10条及び第13条へ、feature key、source、manual override、plan override、override ID、付与又は停止理由、作成者、期限、変更前後の状態、監査ログ、IPアドレス、User-Agent等を扱うことを追加した。
- IAPワークシート、公開FAQ、サポート返信テンプレート、Go/No-Go判定表、提出前セキュリティ監査チェックリスト、用語集へ、手動上書きは購入証明、返金確定、補償又は無償提供継続ではないこと、理由、期限、対象確認、変更前後、作成者、監査ログが必要であることを同期した。
- 公開前No-Goとして、有料導線が見える状態で、手動有料権限上書きの理由、期限、対象確認、監査ログ又は非保証説明がない状態、又は手動上書きを購入完了、返金確定、補償、無償提供継続、App Store決済取消の根拠として案内する状態を追加した。

参照:
- `web/src/app/admin/billing/page.tsx`
- `web/src/app/admin/actions.ts`
- `web/src/lib/admin/permissions.ts`
- `ios-native/Sources/MegrumCore/SubscriptionModels.swift`
- `ios-native/Sources/MegrumData/SupabaseEntitlementClient.swift`
- `supabase/migrations/20260627023000_add_megrum_plus_subscription_foundation.sql`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/33_iap_product_setup_worksheet.md`
- `notes/34_support_response_templates.md`
- `notes/50_release_go_no_go_decision_matrix.md`
- `notes/54_prelaunch_security_audit_checklist.md`
- `notes/55_public_help_faq_draft.md`

---

## 2026-06-29 追記：運営通知・通知本文統制を補強

- 現行Web管理画面では、`notifications.send` 権限を持つ管理者が `/admin/operations` から運営通知を送信できる。送信先は指定ユーザー又は全有効ユーザーで、サーバー側actionは `admin_announcement` として `notifications` 行を作成し、title/body/link_pathを保存する。
- APNs配送Functionは、`notifications` の `title` と `body` をAPNs alertへ渡し、`linkPath` をpayloadへ含める。したがって管理画面の通知本文は、アプリ内通知だけでなくロック画面、通知センター、連携端末又はOS通知プレビューに表示され得る。
- 管理画面の監査ログには、送信理由、audience、recipient_count、title、link_path等が残る一方、通知本文そのものは通知行及び直近通知表示で確認される。本文を監査metadataへ含める経路は現行読み取りでは未確認のため、通知行、APNs payload、管理画面表示、ログを分けて説明する。
- 利用規約第40条へ、運営者が事故通知、規約変更、安全確認、通報・異議対応、課金・権限、個別サポート、サービス運営等のため、全有効会員、一部会員又は特定会員へ運営通知を送る場合があること、送信対象、タイトル、本文、リンク、理由、対象件数、送信日時等を保存する場合があること、通知が法的・安全・取引・技術上の助言、相手方の行動、返金、補償、復旧、解決又は一定の結果を保証しないことを追加した。
- プライバシーポリシー第2.7、第11条及び第13条へ、運営通知の宛先区分、対象ユーザー、対象者検索値、対象件数、通知タイトル、本文、リンク先、送信理由、作成者、監査ログ、配信結果、開封/既読状態、ロック画面又は管理画面表示、保存期間を追加した。
- App Review適合マトリクス、セキュリティ監査チェックリスト、外部サービス台帳、FAQ、アプリ内コピー、サポートトリアージRunbook、用語集へ、運営通知の全体送信、本文機微情報排除、送信理由、対象件数、二重確認、監査ログ、誤送信時Incident対応、ロック画面からの完全回収非保証を同期した。
- 公開前No-Goとして、全体送信できる運営通知に、宛先区分、対象件数、本文、リンク先、送信理由、監査ログ、誤送信時のIncident手順がない状態、又は住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文、secret、内部ID等を通知本文へ入れる状態を追加した。

参照:
- `web/src/app/admin/actions.ts`
- `web/src/app/admin/operations/page.tsx`
- `web/src/lib/admin/permissions.ts`
- `supabase/migrations/20260627015000_add_admin_operations_console_support.sql`
- `supabase/functions/send-apns-notification/index.ts`
- `ios-native/Sources/MegrumCore/NotificationModels.swift`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/48_external_service_vendor_register.md`
- `notes/53_app_review_guideline_compliance_matrix.md`
- `notes/54_prelaunch_security_audit_checklist.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`
- `notes/67_support_inbox_triage_runbook.md`

---

## 2026-06-29 追記：StoreKit・IAP販売可否・復元失敗境界を補強

- AppleのIn-App Purchase及びApp Store ConnectのIAP関連ヘルプでは、アプリ内で利用するデジタル商品、サブスクリプション、IAP商品の情報、価格、Availability、審査用情報等をApp Store Connectで管理する前提が示されている。Megrumのメグルムプラスはアプリ内のデジタル機能であり、iOSではApp Storeのアプリ内課金を前提に整理するのが保守的である。
- 2026-06-29時点のSwift Nativeコードでは、`SubscriptionSettingsContent` にメグルムプラスの購入ボタン、復元ボタン、StoreKitから取得した `offer.priceText`、フッター固定文言「価格は月額500円です。App Storeのサブスクリプションとして更新・解約できます。」が存在した。2026-07-03時点では `MEGRUM_PLUS_IAP_ENABLED=NO` のチェックイン既定を追加し、IAP無効時は購入/復元ボタン、StoreKit商品情報照会、購入、復元actionを停止する。IAPを有効化した場合は、購入成功後にサーバー同期を行い、同期失敗時は「購入は確認できました。サーバー同期は次回起動時に再確認してください。」と表示する経路がある。
- `SettingsLegalViews` の特定商取引法に基づく表記は、正式な法的本文ではなく公開前レビュー後の原文へ差し替えるための要約表示である。アプリ内要約又は設定内入口だけで、ログイン不要の正式な公開特商法ページを公開済みとして扱わない。
- 利用規約第7条へ、有料サービス名、価格、購入ボタン、復元ボタン、特典説明、ステータス、特定商取引法に基づく表記への入口又はサポート案内が表示される場合でも、App Store Connectの商品状態、審査状態、販売地域、価格設定、販売停止、会員のアカウント地域、支払方法、通信環境、年齢又は保護者承認、サーバー検証、アカウント状態等により、購入、復元、利用又は権限反映ができない場合があることを追加した。
- プライバシーポリシー第2.9条及び第10条へ、商品情報照会、価格取得、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止状態等の記録を扱うことを追加した。
- App Privacyインベントリ、App Store Connect回答シート、Privacy Manifest/SDK監査台帳、App Store配信地域・IAP Availabilityチェックリストへも、商品情報照会、価格取得、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止を同期した。Purchasesだけで足りない場合はIdentifiers又はOther Dataの扱いも実ビルドとApp Store Connectの最新UIで確認する。
- 公開前No-Goとして、メグルムプラスの購入ボタン、復元ボタン、価格、特典説明又は状態表示が見えるのに、App Store Connect商品、IAP Availability、公開特商法ページ、FAQ、Review Notes、Privacy/App Privacy、サーバー検証、返金/取消/期限切れ同期が未整備である状態を追加した。

参照:
- Apple In-App Purchase: https://developer.apple.com/in-app-purchase/
- Apple In-App Purchase information: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information/
- Apple Auto-renewable subscription information: https://developer.apple.com/help/app-store-connect/reference/auto-renewable-subscription-information/
- Apple Set availability for In-App Purchases: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases/
- `ios-native/Sources/MegrumApp/SubscriptionSettingsContent.swift`
- `ios-native/Sources/MegrumApp/SubscriptionSettingsScreen.swift`
- `ios-native/Sources/MegrumApp/SettingsLegalViews.swift`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/25_public_legal_support_pages.md`
- `notes/33_iap_product_setup_worksheet.md`
- `notes/27_app_privacy_data_inventory.md`
- `notes/43_app_privacy_connect_answer_sheet.md`
- `notes/44_privacy_manifest_sdk_audit.md`
- `notes/68_app_store_territory_dsa_iap_availability.md`
- `notes/63_public_page_redaction_qa.md`

---

## 2026-06-29 追記：公開法務ページ同期No-Goを補強

- 現行Web実装の公開ルートは、コード読み取り上 `/terms`、`/privacy`、`/support` が中心で、公開ページ内のTerms/Privacy更新日は `2026年6月26日` だった。一方、法務ドラフト、Word改訂案、FAQ、サポート文面、App Review関連メモは2026-06-29時点で、Keychain/session保存、外部AI、AdMob、位置情報、写真メタデータ、郵送交換、会員間支払い、顔候補付け、UGC・App Review 1.2、公開レビュー返信、事故初動、販促通知、公式連絡・フィッシング等を追加済みである。
- 現行 `/terms` と `/privacy` の短縮本文をApp Store ConnectのPrivacy Policy URL、利用規約URL、アプリ内同意リンク、Support関連リンク又はReview Notesの正式本文として扱うと、提出文書と実際にユーザーが読める本文が分裂する。特にPrivacyはApp Privacy回答、外部サービス台帳、SDK/通信監査、通知、広告、位置情報、写真、AI、レビュー返信、事故疑い、販促同意/停止履歴、不審連絡報告と一致させる必要がある。
- 登録同意画面は現行コード上 `https://megrum.jp/terms` と `https://megrum.jp/privacy` を指す。公開正URLを `/legal/terms` と `/legal/privacy` にする場合は、完成ビルド側のリンク更新又はWeb側のリダイレクトで同じ正式本文へ到達させる必要がある。コード変更禁止の本作業では、実装変更ではなく公開前No-Goとして記録する。
- Supportページは現行コード上 `/support` が存在するが、公開原稿で想定する `/support/account-deletion`、`/support/privacy-request`、`/support/report`、`/support/ai`、`/support/faq`、`/support/ads` は、実装、アンカー、リダイレクト又はApp Store入力値の調整が確認されるまで公開済みとして扱わない。
- 公開前No-Goとして、2026-06-29版のMarkdown又はWordだけを更新し、公開Web、アプリ内同意リンク、Support関連リンク、App Store Connect入力値、Review Notes、App Privacy回答の到達先が古い短縮本文のまま残る状態を明示した。

参照:
- `web/src/app/terms/page.tsx`
- `web/src/app/privacy/page.tsx`
- `web/src/app/support/page.tsx`
- `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift`
- `notes/25_public_legal_support_pages.md`
- `notes/37_public_url_publication_checklist.md`
- `notes/63_public_page_redaction_qa.md`
- `notes/66_legal_review_publication_runbook.md`

---

## 2026-06-29 追記：公式連絡・フィッシング境界を補強

- IPAの情報セキュリティ安心相談窓口では、フィッシングや不正ログイン等の相談・注意喚起が扱われている。Megrumはメール認証、パスワードリセット、Google/Appleログイン、カスタムURL scheme、通知linkPath、運営通知、会員間支払い情報を扱うため、公式サポートやキャンペーンを装う連絡で認証コード、認証リンク、金融機関ログイン情報等を求められるリスクがある。
- 現行規約には認証リンク共有禁止や秘密情報送信禁止が既にあるが、運営者側が「サポート、返金、キャンペーン、安全確認、本人確認の名目で何を求めないか」を明示しないと、ユーザーがなりすまし連絡と公式連絡を区別しづらく、開発者側もサポート返信や広告文面の統制を説明しにくい。
- 利用規約第24条へ、本アプリ、運営者、アプリストア、金融機関、配送事業者、会場、権利者、公式アカウント、サポート、キャンペーン、決済、返金、本人確認等を装う虚偽案内、フィッシング、外部サイト誘導、外部チャット誘導、秘密情報提供要求を禁止行為として補強した。
- 利用規約第40条へ、運営者は、サポート、本人確認、返金、キャンペーン、広告、決済又は安全確認の名目で、パスワード、認証コード、認証リンク、access token、refresh token、API key、secret、秘密鍵、金融機関ログイン情報、暗証番号、クレジットカード番号、送金用QRコード等の不要な秘密情報の提供を求めるものではないことを追加した。
- 同条へ、会員はメール、SMS、Push通知、アプリ内通知、外部チャット、外部SNS又はWebサイト上の案内について、公式ドメイン、アプリ内導線、送信元、リンク先及び内容を確認し、不審な連絡又はなりすましが疑われる場合はリンクを開かず、情報を入力又は送信しないことを追加した。
- プライバシーポリシー第2.10、第3条へ、不審な連絡、フィッシング、なりすまし又は外部誘導の報告に関する送信元、メールヘッダー、URL、リンク先、スクリーンショット、通知画像、外部チャット内容、発生日時、相手アカウント、関係する取引又は投稿、調査結果及び対応履歴を、調査及び注意喚起のために扱うことを追加した。
- FAQ、アプリ内コピー、サポート返信テンプレート、App Review適合マトリクスへ、Megrum公式がパスワード、認証コード、認証リンク、金融機関ログイン情報、暗証番号、クレジットカード番号、送金用QRコードを求めないこと、Review Notesやサポート返信でこれらを求めるように読ませないNo-Goを反映した。

参照:
- IPA 情報セキュリティ安心相談窓口: https://www.ipa.go.jp/security/anshin/
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`
- `notes/34_support_response_templates.md`
- `notes/53_app_review_guideline_compliance_matrix.md`

---

## 2026-06-29 追記：広告宣伝メール・販促通知の同意/停止境界を補強

- 消費者庁は特定電子メール法の所管情報として、同法、ガイドライン、現行法条文及び迷惑メール相談センター等への導線を公開している。広告宣伝メールを扱う場合は、事前同意、同意記録、送信者情報、問い合わせ先、配信停止導線及び停止後の送信抑止を、実装・運用・公開文書で説明可能にする必要がある。
- Apple App Review Guidelines 4.5.4の観点でも、Push通知をアプリ利用の必須条件にせず、機微情報を送らず、プロモーション又は直接マーケティング目的のPush通知には明示的同意とオプトアウト手段を用意する必要がある。
- 現行Swift Nativeには、`NotificationCenterContent`、`MegrumAppStateNotificationActions`、`SettingsStatusTextResolver`、`user_notification_settings`、APNs端末登録、通知既読管理があり、Supabase/Webには `admin_announcement` 種別及び `notifications.send` 権限による運営通知送信経路がある。現状の中心は取引、安全、めぐり、運営連絡だが、運営通知やキャンペーン表示が将来の広告宣伝・直接マーケティングに広がる可能性がある。
- 利用規約第40条へ、プロモーション、キャンペーン、広告宣伝又は直接マーケティング目的の電子メール、プッシュ通知、アプリ内通知その他の連絡について、必要に応じて事前同意、同意記録、送信者情報、問い合わせ先、配信停止手段及び停止後の反映措置を講じることを追加した。
- 同条へ、会員が配信停止又は通知設定変更を行った場合でも、取引、安全、認証、課金、規約変更、法令対応その他本アプリの提供又は会員保護に必要な連絡は送信又は表示され得ることを明記した。これにより、マーケティング停止が安全通知・取引通知の放棄と誤読されるリスクを下げる。
- プライバシーポリシー第2.7、第3条、第11条、第13条へ、販促連絡に関する同意状態、同意日時、同意取得画面、同意文言又はポリシーのバージョン、配信停止履歴、抑止リスト、配信結果、開封/クリック、不達/エラー、送信者情報及び問い合わせ先表示の記録を、法令遵守、不正配信防止、苦情対応、監査及び内部統制のために扱うことを追加した。
- FAQ、アプリ内コピー、App Review適合マトリクスへ、広告宣伝メール又は販促通知は必要連絡と別管理であり、停止後も取引、安全、認証、課金、規約変更又は法令対応の連絡は残り得ること、同意記録・停止手段・送信者情報・問い合わせ先がない状態で販促Push又は広告宣伝メールを送らないことを反映した。

参照:
- 消費者庁 特定電子メールの送信の適正化等に関する法律（特定電子メール法）: https://www.caa.go.jp/policies/policy/consumer_transaction/specifed_email/
- e-Gov 特定電子メールの送信の適正化等に関する法律: https://laws.e-gov.go.jp/law/414AC0000000026
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`
- `notes/53_app_review_guideline_compliance_matrix.md`

---

## 2026-06-29 追記：漏えい等初動・事故疑いの責任承認境界を補強

- 個人情報保護委員会の公式情報では、個人の権利利益を害するおそれがある一定の漏えい等について、報告及び本人通知が必要になる場合がある。要配慮個人情報、財産的被害のおそれ、不正目的の行為、多数本人に関わる場合等は特に注意が必要で、速報、確報、本人通知、関係機関報告の要否は事案発覚時点の公式情報と弁護士確認に従う必要がある。
- 現行Swift Native/Supabase/Webには、Keychain session、access token、refresh token、APNs token、Storage公開URL/署名URL、公開証跡、Function logs、OSLog、管理者権限、監査ログ、RLS、service role key、外部AI、AdMob、App Store審査証跡など、漏えい等又は事故疑いの初動対象になり得る情報と運用がある。
- 利用規約第27条へ、個人情報、認証情報、token、secret、API key、署名URL、通知token、支払い情報、郵送先情報、位置情報、証跡その他保護すべき情報の漏えい、誤表示、誤送信、不正アクセス、改ざん、外部サービスへの想定外送信、第三者閲覧又はこれらのおそれがある場合に、アカウント、投稿、取引、取引チャット、有料サービス等を一時制限、停止、凍結、非表示等できることを追加した。
- 同条へ、事故疑い時に原因及び影響範囲の調査、証跡保全、ログ又はスクリーンショットの必要最小限の保存、対象機能の一時停止、token、secret、API key等の無効化又は更新、外部サービス照会、本人通知、関係機関報告、公表、再発防止策等を行うことがある旨を追加した。
- ただし、調査、連絡、通知、報告、公表、機能停止又は再発防止策は、法令上必要な対応、被害拡大防止又は事実確認のために行うものであり、漏えい等への該当性、運営者の法的責任、損害賠償義務、補償、返金、復旧、原因の確定、再発防止の完全性又は一定期間内の調査完了を認め、又は保証するものではないことを明記した。
- プライバシーポリシー第12条へ、事故疑い時の調査、証跡保全、一時制限、認証情報の無効化又は更新、外部サービス照会、本人通知、関係機関報告、公表、再発防止策の取扱いと、初動連絡・本人通知・報告・公表が責任承認又は解決保証ではない境界を追加した。
- 事故初動RunbookとFAQへ、初回返信又は受付番号が、漏えい等への該当性、原因、責任、補償、返金、復旧又は再発防止を確定するものではないこと、公開レビューやSNSに個別事故情報を書かないことを反映した。

参照:
- 個人情報保護委員会 漏えい等の対応とお役立ち資料: https://www.ppc.go.jp/personalinfo/legal/leakAction/
- 個人情報保護委員会 漏えい等報告・本人への通知の義務化: https://www.ppc.go.jp/news/kaiseihou_feature/roueitouhoukoku_gimuka/
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/49_privacy_security_incident_response_runbook.md`
- `notes/55_public_help_faq_draft.md`

---

## 2026-06-29 追記：App Store評価・公開レビュー返信の境界を補強

- Apple公式ヘルプは、App Store Connectで評価・レビュー確認、公開返信、concern report、overview rating resetを扱えることを示している。開発者返信はApp Store product page上で公開され、表示反映に時間がかかる場合があり、編集又は削除できるが、公開欄であることを前提に扱う必要がある。
- Apple公式ヘルプ上、低評価、技術的問題、不具合、改善要望又は誤解があるレビューへの返信を優先しつつ、返信に個人情報、マーケティング表現、スパム、攻撃的又は不適切な表現を含めない運用が求められる。レビュー本文自体に個人情報、秘密情報、攻撃的表現等がある場合は、公開返信で引用せず、concern reportを検討する。
- 利用規約第40条へ、App Storeその他アプリストア上の評価、レビュー、レビュー要約、開発者返信、concern report、overview rating reset等は、当該アプリストアの規約、ポリシー及び技術仕様に従うこと、会員がレビュー等の公開欄に個人情報、取引ID、注文番号、認証情報、金融機関情報、本人確認書類、証跡URL、スクリーンショット等を含めないことを追加した。
- 同条へ、運営者の公開レビュー返信は、公開の一般的な案内、問い合わせ窓口への誘導又は事実確認中である旨を示すものであり、個別サポート、本人確認、事故認定、法的責任の承認、補償、返金、相手会員への措置、復旧、削除又は解決を保証しないことを追加した。
- プライバシーポリシー第2.10、第3条、第8条、第11条、第13条へ、アプリストア上の評価、レビュー本文、レビュー要約、レビュアー表示名、国又は地域、対象アプリバージョン、評価日時、編集又は返信状態、開発者返信案及び返信履歴、concern report、overview rating resetに関する記録を、品質改善、公開返信、サポート誘導、審査対応、証跡管理及び監査のために扱うことを反映した。
- 公開前No-Goとして、App Store公開レビュー又は開発者返信に、個人情報、取引情報、認証情報、金融機関情報、証跡URL、スクリーンショット、内部ログ、相手会員への措置、返金/補償断定、評価変更依頼、値引き誘導、マーケティング又は攻撃的表現を入れない。

参照:
- Apple Respond to reviews: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/respond-to-reviews/
- Apple Ratings and reviews overview: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/ratings-and-reviews-overview/
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/74_app_store_ratings_reviews_response_runbook.md`
- `notes/53_app_review_guideline_compliance_matrix.md`

---

## 2026-06-29 追記：UGCとApp Review Guideline 1.2境界を補強

- Apple App Review Guidelinesは2026-06-29時点で2026-06-08更新版を確認した。Guideline 1.2では、UGC又はソーシャルネットワークを含むアプリについて、不適切投稿を防ぐ方法、攻撃的コンテンツの通報と適時対応、濫用ユーザーのブロック、ユーザーが容易に連絡できる公開連絡先が必要とされる。また、ポルノ、Chatroulette風体験、ランダム又は匿名チャット、実在人物の外見評価、脅迫、いじめを主目的とするUGCサービスはApp Storeに適さない旨が示されている。
- 現行Swift Nativeには、プロフィール、グッズ画像、グルーム、スポット掲示板、取引チャット、証跡、評価コメント、通報、ブロック、通報/ブロックに関するSwift画面、`groom_reports`、`meguri_board_reports`、汎用 `reports`、管理画面の通報対応権限がある。一方で、投稿前/投稿時の不適切コンテンツフィルタ、NGワード、自動検知、投稿保留、投稿拒否の実装範囲は提出前の実ビルド照合が必要。
- 利用規約第24条へ、不適切投稿防止のため、投稿前後の注意喚起、入力制限、投稿頻度制限、URL、画像、添付形式、位置範囲、アカウント状態、通報履歴、NGワード等に基づくフィルタリング、自動検知、ルールベース判定、人手確認、投稿保留、投稿拒否、返信停止、表示制限、削除、アカウント制限等を行うことがある旨を追加した。ただし、全ての不適切投稿を投稿前に検知、審査又は削除する保証はしない。
- 同条へ、めぐり、グルーム、スポット掲示板、取引チャット等は、会員登録に基づく推し活グッズ交換及び関連情報共有のための機能であり、わいせつコンテンツ、ランダムチャット、匿名チャット、出会い、性的接触、実在人物の外見評価、脅迫、いじめ、嫌がらせ、晒し、危険行為又はこれらを主目的とする利用のための機能ではないことを追加した。
- FAQ、アプリ内安全コピー案、App Review Guideline適合マトリクス、App Store審査提出パックへ、UGCを提出する場合は、投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先、運用SOPを実ビルドと一致させ、未実装のフィルタ又は即時監視をReview Notesに書かないことを反映した。
- 公開前No-Goとして、UGC機能をランダム/匿名チャット、出会い、性的接触、実在人物の外見評価、脅迫、いじめ、嫌がらせ、晒し目的に見せない。投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先が実ビルドで説明できない状態では、グルーム、スポット掲示板、取引チャット、評価コメント等のUGCを提出スクショ、App Store説明、Review Notes、デモデータに出さない。

参照:
- Apple App Review Guidelines Guideline 1.2 User-Generated Content: https://developer.apple.com/app-store/review/guidelines/
- `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift`
- `ios-native/Sources/MegrumApp/MegrumAppStateAccountSettingsActions.swift`
- `ios-native/Sources/MegrumApp/MegrumAppStateGroomActions.swift`
- `ios-native/Sources/MegrumApp/MegrumAppStateMeguriActions.swift`
- `supabase/migrations/20260529191000_add_location_scoped_groom_board.sql`
- `supabase/migrations/20260530193000_add_meguri_board_edit_controls.sql`
- `supabase/migrations/20260627015000_add_admin_operations_console_support.sql`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/53_app_review_guideline_compliance_matrix.md`
- `notes/24_app_store_submission_pack.md`

---

## 2026-06-29 追記：サポートSLA・専門助言非保証を補強

- 現行運用文書には、`support@megrum.jp`、App Store Support URL、問い合わせ受付、通報、削除申出、個人情報請求、購入/IAP問い合わせ、App Review連絡、安全相談、事故疑い、公開レビュー返信の運用がある。少人数運用で「原則2営業日以内」「24時間以内」「当日中」「1営業日以内」等の目安を出す必要はあるが、これが固定SLA、問題解決保証、削除保証、復旧保証、返金保証、相手会員への措置保証、個別理由開示保証として読まれるリスクがある。
- 利用規約第40条へ、FAQ、サポートページ、アプリ内表示、メール又は個別返信において示す返信目安、対応目安、確認予定、優先度、受付番号、エスカレーション先又は対応方針は、運営上の目安であり、法令上必要な場合を除き、一定期間内の返信、回答、調査、削除、復旧、返金、補償、相手会員への措置、結果の実現又は個別理由の開示を保証しないことを追加した。
- 同条へ、ヘルプ、FAQ、サポート返信、Review Notes、アプリ内安全案内、課金案内、通報又は問い合わせへの回答は、本アプリの利用方法、運営方針又は一般的注意の説明であり、法律、税務、会計、医療、警備、防犯、金融、配送、権利処理、本人確認、真贋鑑定、入場資格等についての専門的な助言、鑑定、保証又は代理ではないことを追加した。
- FAQ、サポート返信テンプレート、サポート受信トリアージRunbook、アプリ内法務・安全コピー集にも、返信目安は保証ではないこと、専門判断が必要な場合は弁護士、税理士、警察、消防、消費生活センター、金融機関、配送事業者、会場又は施設管理者等へ相談することを反映した。
- 公開前No-Goとして、`原則2営業日以内`、`24時間以内`、`当日中`、`1営業日以内` 等を、必ず返信する期限、SLA確定、法的義務、削除保証、復旧保証、返金保証、補償保証、相手への処分保証又は即時安全対応保証のように説明しない。サポート回答、FAQ、Review Notes、公開レビュー返信、アプリ内安全案内では、Megrumが法律相談、税務相談、医療相談、防犯保証、金融助言、配送保証、権利処理代理、真贋鑑定、入場資格確認を行うように見せない。

参照:
- `notes/legal/01_terms_of_service_draft.md`
- `notes/55_public_help_faq_draft.md`
- `notes/34_support_response_templates.md`
- `notes/67_support_inbox_triage_runbook.md`
- `notes/56_in_app_legal_safety_copy_deck.md`

---

## 2026-06-29 追記：有料権限・ブーストの非決済手段境界を補強

- 現行Swift Nativeには、StoreKitによるメグルムプラス購入・復元経路、`megrum.plus.monthly`、`UserSubscriptionState`、`user_entitlements`、ホーム/検索のPlus優先表示、グルームアーカイブ上限、個別募集上限拡張、旧Premium/旧めぐりPlus互換権限が存在する。収益化メモには、将来のブースト残数、発動、24時間優先表示、広告非表示等の設計も残っている。
- 利用規約第7条へ、ブースト、優先表示、広告非表示、作成上限拡張、保存枠拡張その他有料サービスに関する権限、残数、特典、バッジ又は表示上の状態は、本アプリ内でのみ利用できるサービス上の利用権であり、現金、金券、電子マネー、暗号資産、ポイント、前払式支払手段、資金移動、預り金、投資商品、決済手段又は第三者への支払手段として設計又は提供されるものではないことを追加した。
- 第7条へ、これらの権限、残数、特典、バッジ又は表示上の状態について、運営者が明示的に認める場合を除き、第三者への譲渡、貸与、相続、担保設定、換金、返金請求、売買、交換、外部サービスへの持ち出し又はアカウント間移転を禁止することを追加した。
- 返金、取消、期限切れ、アカウント制限、規約違反、機能終了、仕様変更又は運営上必要な場合に、失効、消費、停止、取消、調整又は削除され得ることを明記した。
- プライバシーポリシー第2.9条へ、ブースト残数、付与数、消費数、発動履歴、対象、効果期間、優先表示状態、広告非表示状態、上限拡張状態、保存枠拡張状態、バッジ表示状態、失効等を取得情報として追加した。
- FAQ、アプリ内安全コピー案、IAPワークシート、収益化メモへ、ブーストや優先表示が、取引成立、閲覧数、返信、評価、売買又は交換成立を保証しないこと、現金化、譲渡、売買、アカウント間移転、外部サービスへの持ち出しができないことを反映した。収益化メモ上の「未使用分のみ可（30日以内）」は一律返金約束に見えるため、App Store返金手続、利用規約、法令、返金/取消イベントとサーバー残数調整に従う表現へ変更した。
- 公開前No-Goとして、ブースト、優先表示、メグルムプラス、広告非表示、上限拡張、保存枠拡張、バッジ、残数を、現金価値、ポイント、前払式支払手段、資金移動、預り金、決済手段、譲渡可能資産、投資商品、取引成立保証、閲覧数保証、返信保証、評価向上保証又は返金保証のように説明しない。App Store表示、アプリ内価格、特商法表記、FAQ、Review Notes、サーバー検証、返金/取消/期限切れ同期が揃うまで有料導線を見せない方針を維持する。

参照:
- Apple Developer In-App Purchase: https://developer.apple.com/in-app-purchase/
- 資金決済に関する法律: https://laws.e-gov.go.jp/law/421AC0000000059
- `ios-native/Sources/MegrumApp/SubscriptionSettingsContent.swift`
- `ios-native/Sources/MegrumApp/MegrumPlusPurchaseClient.swift`
- `ios-native/Sources/MegrumApp/MegrumPlusAccessPolicy.swift`
- `ios-native/Sources/MegrumApp/SearchResultFilterPolicy.swift`
- `ios-native/Sources/MegrumApp/HomeDiscoveryCandidateSorter.swift`
- `notes/16_monetization.md`
- `notes/33_iap_product_setup_worksheet.md`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`

---

## 2026-06-29 追記：会場・施設ルールとイベント主催者非関与の責任境界

- 現行Swift Nativeでは、現地交換モード、場所メモ、会場名、駅名、会場周辺、会場横、東京ドーム22ゲート前、会場ロビー等の表示・プレビュー・入力欄が存在する。ユーザー体験上は自然だが、イベント主催者、興行主、会場、駅、商業施設、公共空間、交通機関又は店舗がMegrum上の交換を承認、公認、提携、許可、推奨又は安全確認したように見えるリスクがある。
- 利用規約第15条へ、イベント主催者、興行主、会場、施設、駅、商業施設、公共空間、交通機関、警備会社、店舗、自治体その他関係者が定める利用規則、掲示、案内、警備員又はスタッフの指示、撮影禁止、交換、譲渡、物販、金銭授受、滞留、行列、荷物、通行、立入り、営業時間その他の制限を会員自身が確認し、従うことを追加した。
- 第15条へ、通行妨害、滞留、騒音、周辺住民又は来場者への迷惑、無許可営業、無許可の物販、勧誘、転売、チラシ配布、禁止エリアへの立入り、施設設備の占有、会場又は施設の運営妨害、警備員、スタッフ又は管理者の指示違反を禁止する説明を追加した。
- 第15条へ、イベント名、会場名、駅名、店舗名、施設名、場所名、地図、距離、周辺情報又は会場情報が表示されても、当該イベント、主催者、興行主、会場、施設、店舗、交通機関又は権利者がMegrum、現地交換、会員間取引、待ち合わせ又は投稿を承認、公認、提携、許可、推奨又は安全確認したことを意味しないことを追加した。
- 第26条の禁止行為へ、会場・施設・駅・イベント等のルール、掲示、案内、警備員又はスタッフ指示に反し、通行妨害、滞留、無許可営業、無許可の物販、勧誘、転売、禁止エリア立入り、撮影禁止違反、施設設備占有等を行うことを禁止対象として追加した。
- 公開FAQとアプリ内安全コピー案にも、会場、駅、施設、イベント主催者、警備員、スタッフのルールに従うこと、表示された場所が交換を公認又は許可しているとは限らないことを追加した。
- 公開前No-Goとして、会場名、駅名、施設名、イベント名、地図、場所メモ、現地交換モード、グルーム又はスポット掲示板を、会場公認の交換場所、主催者提携サービス、施設許可済み導線、滞留や物販の許可、警備員確認済み、安全確認済みスポット、会場ルール適合保証のように説明しない。Review Notes、FAQ、アプリ内コピー、サポート返信では、表示場所が参考情報であり、現地ルール確認は会員責任であることを維持する。

参照:
- `ios-native/Sources/MegrumApp/HomeLocalModeSettingsContent.swift`
- `ios-native/Sources/MegrumApp/ProposalCreateConditionSteps.swift`
- `ios-native/Sources/MegrumApp/NativePreviewTradeData.swift`
- `ios-native/Sources/MegrumApp/HomeGroomEntrySurface.swift`
- `ios-native/Sources/MegrumApp/MeguriBoardThreadListViews.swift`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`

---

## 2026-06-29 追記：緊急時・安全対応の非代替と生命身体財産保護

- 現行Swift Nativeでは、現地交換、待ち合わせ候補、位置情報共有、服装写真共有、到着状況、取引チャット、通報、ブロック、異議申し立て、評価、証跡が存在する。一方で、Megrumは警察、消防、医療機関、警備会社、付き添い、本人確認、所在確認、常時監視又は事故防止サービスではない。
- 利用規約第15条へ、身体の危険、犯罪被害、差し迫った脅迫、ストーカー行為、詐欺、盗難、暴行、医療上の緊急事態、災害、会場又は施設内トラブル等では、アプリ内の通報、問い合わせ、ブロック、位置情報共有、服装写真共有、到着状況又は安全案内を待たず、警察、消防、医療機関、会場スタッフ、施設管理者、消費生活センターその他適切な公的機関又は専門機関へ連絡又は相談することを追加した。
- 利用規約第15条へ、通報、ブロック、異議申し立て、問い合わせ、位置情報共有、服装写真共有、到着状況、安全案内等は、緊急通報、救助、警備、警察対応、医療対応、法律相談、身元確認、所在確認、常時監視、付き添い、事故防止又は公的救済手段の代替ではないこと、運営者が即時監視、即時返信、現場対応、関係機関連絡、保護、救助又は被害防止を保証しないことを明記した。
- プライバシーポリシー第3条、第6条、第7条へ、生命、身体又は財産の保護、安全確保補助、緊急対応、法令遵守、権利保護のため、必要な範囲で通報、異議申し立て、問い合わせ、取引、証跡、位置情報、服装写真等の関連情報を確認又は提供し得ることを追加した。
- 第三者提供については、個人情報保護法上、本人又は第三者の生命、身体又は財産の保護のため必要で本人同意取得が困難な場合、公衆衛生又は児童健全育成のため特に必要で本人同意取得が困難な場合、国機関等への協力が必要な場合等の例外があるため、その範囲に合わせて整理した。
- 公開前No-Goとして、Megrumの通報、ブロック、位置情報、服装写真、到着状況、安全案内、モデレーション又はサポートを、緊急通報、警察・消防・医療への自動連絡、警備、付き添い、本人確認、安全確認済み、事故防止、ストーカー防止、詐欺防止、救助保証又は即時対応保証のように説明しない。アプリ内コピー、FAQ、サポート返信では、危険時はアプリ内対応を待たず公的機関又は現地管理者へ相談する導線を維持する。

参照:
- 個人情報保護法: https://laws.e-gov.go.jp/law/415AC0000000057
- `ios-native/Sources/MegrumApp/TradeDisputeSheet.swift`
- `ios-native/Sources/MegrumApp/TradeMessageOverflowMenu.swift`
- `ios-native/Sources/MegrumApp/MegrumLocationState.swift`
- `ios-native/Sources/MegrumApp/PublicUserProfileModerationViews.swift`
- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`

---

## 2026-06-29 追記：第三者SDK・OSSライセンスの責任境界を追加

- 現行Swift Nativeの `ios-native/Package.swift` では、Google Mobile Ads SDKをSwiftPM依存として取り込み、`MegrumApp` targetで `GoogleMobileAds` productをiOS条件付きでlinkしている。Web側にはNext.js、React、Tailwind、ESLint等多数のnpm依存とライセンスファイルが存在する。
- 利用規約第31条へ、本アプリにはOS、アプリストア、外部SDK、クラウドサービス、広告SDK、地図、認証、決済、AI、通知、フォント、画像処理、OSSその他第三者が権利を有するソフトウェア、ライブラリ、API、データ、フォント又は素材が含まれ、又は連携し得ることを追加した。
- これら第三者要素の知的財産権、利用条件、ライセンス表示、禁止事項、責任制限、更新、停止又は終了は、各権利者、提供者、アプリストア又は外部サービスが定めるライセンス、規約、ポリシー又は技術仕様に従うことを明記した。
- 本規約は、第三者ソフトウェア、SDK、API、データ、商標、ロゴ、フォント又は素材について、本アプリの通常利用に必要な範囲を超える権利を会員へ許諾しないこと、権利表示、ライセンス表示又は技術的保護手段の削除、改変、回避、無効化を禁止することを追加した。
- 公開前No-Goとして、OSS/SDKのライセンス表示又は第三者権利表示を不要と判断しない。Google Mobile Ads、Apple/Google/Supabase/OpenAI等のロゴ、SDK、API、データ又は商標について、Megrum規約だけで再利用権を許諾しているように説明しない。最終リリース前にOSS notice、SDK attribution、アプリ内/公開Web/審査資料の表示要否を別途確認する。

参照:
- `ios-native/Package.swift`
- `ios-native/Package.resolved`
- `web/package.json`
- `web/node_modules/*/LICENSE*`
- `notes/legal/01_terms_of_service_draft.md`

---

## 2026-06-29 追記：未成年・生年月日・広告年齢制限の責任境界を補強

- 現行Swift Nativeでは、アカウント設定フローで生年月日入力が必須で、年齢又は年代表示を生成し得る。一方で、最低年齢制限、公的年齢確認、身分証確認、保護者同意確認、保護者管理機能は未確認である。
- 広告実装ではGoogle Mobile Ads SDK / AdMob構成があり、現行検索ではATT要求、UMP同意管理、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御、child-directed treatment、users under age of consent向け設定、test device id指定は未確認である。
- 利用規約第3条へ、Megrumは別段の明示がない限りApp StoreのKids Categoryその他子ども向け専用カテゴリを対象とするサービスではなく、実年齢、法定代理人同意、保護者管理、年齢確認又は広告適合性が常に確認済みであることを保証しないことを追記した。
- 利用規約第8条へ、自己申告年齢、生年月日、年齢区分、端末、OS、アプリストア、広告配信事業者の設定、同意状態、地域、法令又はプラットフォームポリシーに応じて、広告リクエスト、パーソナライズ広告、トラッキング、広告カテゴリ、広告表示、レコメンド又はProduct Personalizationを制限、停止又は変更し得ることを追記した。
- プライバシーポリシー第16条へ、自己申告の生年月日又は年齢、年齢区分、同意状態、地域、端末、OS、アプリストア、広告配信事業者又は外部サービスの設定に基づき、広告、レコメンド、Product Personalization、AI機能、外部送信、位置情報、会員間連絡、会員間支払い等を制限、停止又は変更し得ることを追記した。
- 公開前No-Goとして、App Store Age Rating、Review Notes、広告設定、FAQ、アプリ内コピー、サポート返信で、MegrumをKids Category対象、子ども向け専用、年齢確認済み、保護者同意確認済み、広告内容を年齢別に全件確認済み、不適切広告が出ない、又はAdMobのchild-directed/under-age設定が完了済みであるかのように説明しない。広告を出す場合は、実ビルドのAdMob設定、ATT/UMP/非パーソナライズ広告、年齢関連設定、テスト広告除去、App Privacy回答を別途P0で照合する。

参照:
- Apple App Review Guidelines Kids Category: https://developer.apple.com/app-store/review/guidelines/#kids-category
- Google AdMob child-directed treatment: https://support.google.com/admob/answer/6223431
- Google AdMob users under age of consent: https://support.google.com/admob/answer/9004919
- `ios-native/Sources/MegrumApp/AccountSetupScreen.swift`
- `ios-native/Sources/MegrumApp/AdNativeUIKitBridge.swift`
- `notes/43_app_privacy_connect_answer_sheet.md`
- `notes/44_privacy_manifest_sdk_audit.md`

---

## 2026-06-29 追記：登録禁止グッズ・規制物品の列挙を補強

- 現行Swift Nativeでは、グッズ登録、在庫情報、wish、個別募集、取引打診、検索、AI候補、画像登録、タグ付け等で、ユーザーがグッズ名、説明、画像、カテゴリ、状態、交換可否、金額指定等を登録できる。コード上、全ての禁止品、年齢制限品、規制品、本人確認書類、チケット情報、QR/バーコード、配送伝票、危険物、医薬品、酒類、たばこ等を登録前に網羅的に自動判定する前提にはできない。
- 既存利用規約第12条は、法令・権利者規約違反、偽造品、盗品、チケット、危険物、医薬品等を大枠で禁止していたが、現行機能は写真、画像メタデータ、AI候補、郵送交換、会員間支払い、現地交換、通報/異議申し立てを含むため、禁止対象をより具体化した。
- 利用規約第12条へ、火薬類、銃砲刀剣類、武器、毒物、劇物、発火/爆発/漏えい/腐食/感染/有害物質又は配送事故のおそれがあるもの、医薬品、医薬部外品、医療機器、化粧品、コンタクトレンズ、衛生用品、食品、飲料、サプリメント、酒類、たばこ、電子たばこ、年齢確認/資格/許認可/届出/専門的管理を要するものを明示した。
- また、本人確認書類、学生証、社員証、会員証、保険証、個人番号、クレジットカード、キャッシュカード、SIMカード、電話番号、メールアドレス、ログイン情報、認証コード、バーコード、QRコード、配送伝票、追跡番号、位置情報、学校名、勤務先、顔写真等を、公開又は取引対象化に適しない情報として明記した。
- 公開前No-Goとして、FAQ、サポート返信、アプリ内コピー、Review Notes、広告説明で、Megrumがこれら規制物品、年齢制限品、本人確認書類、決済/通信/入場用媒体、危険物、医薬品、食品、酒類、たばこ、SIM、アカウント等の交換を許可又は保証しているように説明しない。通報対応では、該当可能性があるだけでも表示制限、削除、取引停止、アカウント制限、関係機関相談を検討できる前提にする。

参照:
- 医薬品、医療機器等の品質、有効性及び安全性の確保等に関する法律: https://laws.e-gov.go.jp/law/335AC0000000145
- 銃砲刀剣類所持等取締法: https://laws.e-gov.go.jp/law/333AC0000000006
- 毒物及び劇物取締法: https://laws.e-gov.go.jp/law/325AC0000000303
- 酒税法: https://laws.e-gov.go.jp/law/328AC0000000006
- たばこ事業法: https://laws.e-gov.go.jp/law/359AC0000000068
- `notes/legal/01_terms_of_service_draft.md`
- `ios-native/Sources/MegrumApp/SettingsLegalViews.swift`

---

## 2026-06-29 追記：国外移転・外国第三者提供・国外アクセスの説明を補強

- 個人情報保護法上、外国にある第三者への個人データ提供では、本人への情報提供、同意取得、基準適合体制又はその他法令上認められる措置の確認が必要になる。個人情報保護委員会の外国第三者提供ガイドラインでは、提供先の国が特定できない場合にも、特定できない理由や本人の判断に資する参考情報の提供が論点になる。
- 現行Megrumは、Supabase、Apple、Google、OpenAI、Google Mobile Ads / AdMob、APNs、MapKit / CoreLocation / CLGeocoder、ZipCloud、ホスティング、CDN、メール/サポート、App Store、外部SNS、外部決済サービス、金融機関その他外部サービスを利用し得る。外部サービス又はその再委託先、サブプロセッサ、保守/監視/障害対応/サポート拠点が国外に所在し、国外から個人データへアクセス、保存又は処理する可能性がある。
- プライバシーポリシー第8条/第9条へ、委託先、外部サービス、再委託先、サブプロセッサ、運用、保守、サポート、監視、障害対応、広告配信、AI処理、通知配信、地図、認証、決済、ホスティング、CDN等で国外処理が生じ得ること、全ての処理が日本国内で完結することを保証しないことを追記した。
- 第9条では、移転又は処理され得る情報の例として、アカウント情報、識別子、認証情報、プロフィール、ユーザーコンテンツ、画像、位置情報、検索又は利用履歴、広告又は診断情報、問い合わせ内容、ログ、証跡、決済又は購読状態を明記した。
- 外部サービス、データセンター、配信先、広告配信先、利用者端末又は所在地、再委託先又はサブプロセッサの変更により移転先国が変動し得るため、全ての国・制度・保護措置を事前に一律特定できない場合があること、その場合も合理的に可能な範囲で情報提供することを整理した。
- 公開前No-Goとして、「Megrumの個人データはすべて日本国内だけで保存・処理される」「国外の委託先・再委託先・サブプロセッサからアクセスされない」「OpenAI、Google、Apple、Supabase、広告、通知、地図、ホスティング、サポート等への国外移転は一切ない」と説明しない。逆に、外国第三者提供や国外アクセスがあり得るのに、移転先が変動し得ること、合理的な情報提供、外部サービス規約/Privacy適用を説明しない状態で公開しない。

参照:
- 個人情報保護法: https://laws.e-gov.go.jp/law/415AC0000000057
- 個人情報保護委員会 外国にある第三者への提供編: https://www.ppc.go.jp/personalinfo/legal/guidelines_offshore/
- `notes/48_external_service_vendor_register.md`
- `notes/legal/02_privacy_policy_draft.md`

---

## 2026-06-29 追記：UserDefaults・AppStorage・URLCacheの端末内保存をPrivacyへ追加

- `ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` を申告している。AppleのRequired Reason API説明上、UserDefaultsはPrivacy Manifestで利用理由を示す対象であり、App Privacy回答や公開Privacyのデータ説明とは役割が異なる。
- 現行Swift Nativeでは、`@AppStorage` により、交換方法の希望、同一都道府県条件、日程重複条件、活動都道府県、選択日、郵送条件、近くモードの有効状態、活動場所名、緯度経度、開始時刻、継続時間、半径、掲示板の都道府県又は閲覧範囲等が端末内UserDefaults系保存領域に残り得る。
- `HomeLocalCoordinateStorageCodec` は緯度経度を小数8桁の文字列として保存・復元できる。`MegrumRemoteImageCache` は `URLCache` のdisk cacheとして `MegrumRemoteImages` を利用し、リモート画像を端末内キャッシュする。
- プライバシーポリシーへ、UserDefaults、AppStorage、URLCacheその他端末内の保存領域又はキャッシュに、交換条件、日程条件、活動場所、緯度経度、掲示板の表示範囲、画像キャッシュ等を保存する場合があること、端末、OS、バックアップ、復元、アプリ削除、再インストール、キャッシュ削除又は空き容量管理により保存・消去・復元の挙動が異なることを追記した。
- 公開前No-Goとして、Privacy ManifestにUserDefaults Required Reasonがあるだけで、App Privacyや公開Privacyでローカル保存データの説明が不要と判断しない。反対に、UserDefaults/AppStorageへ近くモードの緯度経度、活動場所、日程条件等が残り得るのに、「端末内に個人情報や位置情報は保存しない」と説明しない。

参照:
- Apple Describing use of required reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- `ios-native/App/PrivacyInfo.xcprivacy`
- `ios-native/Sources/MegrumApp/HomeExchangeSettingsStorageKeys.swift`
- `ios-native/Sources/MegrumApp/HomeScreen.swift`
- `ios-native/Sources/MegrumApp/HomeLocalLocationModels.swift`
- `ios-native/Sources/MegrumApp/MegrumRemoteImageCache.swift`

---

## 2026-06-29 追記：待ち合わせ候補・日程公開の取扱いを明確化

- 現行Swift Nativeでは、`ProposalMeetupInput` が `startAt`、`endAt`、`placeName`、`latitude`、`longitude` を保持し、打診作成では `meetupCandidates` として複数候補を扱う。`SupabaseProposalPayloads` は、`meetup_start_at`、`meetup_end_at`、`meetup_place_name`、`meetup_lat`、`meetup_lng`、`meetup_candidates`、`expose_calendar` をpayload化する。
- これはOSのカレンダーアプリ又はEventKitから予定を読み取るものではなく、Megrum内で会員が入力又は選択する活動予定、空き時間、候補日時、候補場所、緯度経度、カレンダー形式での表示可否を扱うものとして整理する。ただし、利用者の行動予定、生活パターン、居場所推測につながり得るため、位置情報及び取引情報として慎重に説明する。
- 利用規約第13条/第14条/第15条へ、待ち合わせ候補には候補日時、開始時刻、終了時刻、場所名、緯度経度、複数候補、カレンダー形式での表示可否が含まれ得ること、相手会員による検討、ネゴ、条件確認、取引成立、異議申し立て、通報対応その他運営上必要な範囲で表示、保存又は利用され得ることを追記した。
- プライバシーポリシーでは、現地交換における取得情報として、開始時刻、終了時刻、場所名、複数の待ち合わせ候補、活動予定、空き時間、カレンダー形式での表示可否を追加し、利用目的として日程調整、カレンダー表示、合流、安全確保及びトラブル対応を明確化した。
- 公開前No-Goとして、MegrumがiOSカレンダー、連絡先又は端末上の全予定を読み取るように説明しない。反対に、候補日時、活動予定、空き時間、場所名、緯度経度、カレンダー表示フラグを扱うのに、Privacy、FAQ、App Privacy、Review Notesで日程/位置/行動予定の取扱いを説明しない状態で提出しない。

参照コード:
- `ios-native/Sources/MegrumCore/ProposalCreateModels.swift`
- `ios-native/Sources/MegrumData/SupabaseProposalPayloads.swift`

---

## 2026-06-29 追記：TestFlight・ベータ機能・段階公開の責任境界を追加

- Apple公式のTestFlight説明では、TestFlightはベータビルド配布、テスター管理、フィードバック収集のための仕組みであり、外部テスター配布ではベータApp Reviewが必要になる場合がある。TestFlight tester informationでは、テスターの招待状態、アプリバージョン、端末、OS、session数、crash数、screenshot feedback数等が扱われる。Beta tester feedbackでは、フィードバック詳細としてテスター名又はメール、アプリバージョン、起動時間、端末、iOS version、battery、carrier、time zone、CPU architecture、connection type、disk free、screen resolution等が確認対象になり得る。
- Megrumは、取引、会員間支払い、郵送先、位置情報、写真、通知、AI、広告、StoreKit等を含むため、TestFlight、開発版、検証版、ベータ版、プレビュー版、段階公開又は実験機能で、実在の取引、実在の支払い、郵送先、精密な現在地、機密情報又は不要な個人情報が混入すると、正式リリース前でもトラブル、漏えい、誤請求、審査資料混入、外部サービス送信のリスクがある。
- 利用規約第6条へ、TestFlight等の限定提供中機能では、仕様、画面、データ構造、表示範囲、提供地域、対象者、料金、広告、通知、AI機能、有料サービス、データ保存期間又はサポート範囲が予告なく変更、中断、非表示、削除、リセット又は終了され得ること、正式提供、継続提供、互換性、データ保存、取引成立、収益、広告表示、権限反映、不具合がないことを保証しないことを追加した。
- プライバシーポリシーでは、TestFlight等において、クラッシュログ、診断ログ、端末/OS情報、アプリバージョン、ビルド番号、インストール又は起動状況、操作履歴、テスター情報、フィードバック本文、スクリーンショット、画面録画、問い合わせ内容、添付ファイル等を取得し、Apple、App Store Connect、TestFlight、アプリストア、外部テスト配布サービス、クラウド基盤又は外部SDKを通じて処理し得ることを追加した。
- 公開前No-Goとして、TestFlight案内、外部テスター募集文、FAQ、Review Notes、サポート返信で、ベータ版のデータが必ず正式版へ引き継がれる、仕様が固定済み、テスト中の取引/支払い/郵送先/位置情報が安全に本番同等で扱われる、診断ログやスクリーンショットに個人情報が入らない、TestFlight feedbackやApp Store Connectにテスター/端末/利用状況情報が表示されない、という説明をしない。

参照:
- Apple TestFlight Overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Apple TestFlight tester information: https://developer.apple.com/help/app-store-connect/reference/testflight/testflight-tester-information
- Apple Beta tester feedback: https://developer.apple.com/help/app-store-connect/reference/testflight/beta-tester-feedback

---

## 2026-06-29 追記：会員間支払いの税務責任を追加

- 現行規約は、会員間支払いについて、運営者が資金の受領、保管、送金、収納代行、立替、精算、返金、チャージバック対応、本人確認、信用審査、支払能力確認又はエスクローを行わないこと、税務処理その他支払い事項を保証しないことを定めていた。
- ただし、銀行振込、PayPay、現金交換、差額精算、送料負担、金額指定が見える場合、ユーザーがMegrumを税務・会計・法律上の助言者、領収書発行者、支払証跡管理者、又は申告支援者と誤解するリスクがある。
- 利用規約第14条へ、会員間支払い、差額精算、送料負担、現金交換、グッズの譲渡又は交換その他会員間取引に関連する税務申告、所得区分、収支記録、領収書又は支払証跡の管理、手数料、消費税その他租税公課の取扱いは会員自身の責任で確認することを追加した。
- 運営者は、会員間取引に関する税務、会計又は法律上の助言、申告書類の作成、領収書発行、支払調書その他税務書類の発行を行わないことを明記した。
- 公開前No-Goとして、FAQ、サポート返信、アプリ内コピー、Review Notesで、Megrumが会員間取引の税務処理、領収書発行、支払調書発行、収支記録管理又は税務相談を行うように説明しない。

参照:
- 国税庁 ネットオークション等の副収入を得た場合: https://www.nta.go.jp/taxes/shiraberu/taxanswer/shotoku/1906.htm

---

## 2026-06-29 追記：UGC削除後の証跡・共有済み利用を明確化

- 既存規約では、ユーザーコンテンツの無償・非独占・再許諾可能・譲渡可能な利用許諾、非公開コンテンツの署名URL/端末キャッシュ/通報対応/法令対応での保存可能性、著作者人格権不行使、第三者権利侵害時の責任分界を定めていた。
- ただし、会員がコンテンツを削除し、又は退会した後に、削除前に表示、通知、共有、送信、保存、生成又は外部サービス連携されたコンテンツ、サムネイル、共有用画像、共有用文面、通報、異議申し立て、証跡、監査ログ、バックアップ、キャッシュ、検索/表示履歴、統計化又は匿名化された情報がどう扱われるかは、明示を強めた方がよい。
- 利用規約第25条へ、削除又は退会後であっても、法令遵守、安全確保、不正利用防止、紛争対応、権利侵害対応、監査、障害対応又は本アプリの運営に必要な範囲で、上記記録が引き続き利用、保存又は表示される場合があることを追加した。
- 公開前No-Goとして、ユーザーコンテンツ削除又は退会により、外部SNS共有、相手会員側保存、スクリーンショット、端末キャッシュ、署名URL、通報/証跡/監査ログ、統計化又は匿名化済み情報まで即時完全削除されるように説明しない。

---

## 2026-06-29 追記：退会後・終了後の存続条項を追加

- 現行規約は、退会後又は削除申請中の情報保存、アカウント制限、知的財産権、責任制限、損害賠償、準拠法及び管轄を個別に定めていたが、退会、アカウント抹消、規約終了又はサービス終了後もどの条項が残るかをまとめていなかった。
- Megrumでは、退会後も取引、評価、通報、異議申し立て、郵送先又は支払い情報のスナップショット、Storage画像、通知履歴、ログ、監査記録、AI入力/出力、削除申出対応、権利侵害申立て、課金履歴等を法令遵守、不正利用防止、紛争対応、監査、会計、問い合わせ対応等のために一定期間保持し得る。そのため、退会により責任制限、補償、秘密情報取扱い、知財、準拠法、管轄等が当然に消えるように読まれるのは開発者側リスクになる。
- 利用規約へ第43条（存続条項）を追加し、会員の退会、アカウント制限、停止、抹消、本規約終了又は本アプリ提供終了後も、会員間取引及び第三者との関係に関する責任分界、個人情報及び秘密情報の取扱い、情報の保存及び削除、知的財産権、ユーザーコンテンツの権利許諾、禁止事項、非保証、免責及び責任制限、損害賠償及び利用者補償、譲渡、事業譲渡、通知、分離可能性、準拠法及び管轄等が存続することを明記した。
- 公開前No-Goとして、退会又はアカウント削除により、過去取引、相手会員側表示、通報/異議/証跡、補償義務、知的財産権、免責/責任制限、準拠法/管轄が全て消えるようにFAQ、サポート返信、アプリ内コピーで説明しない。

---

## 2026-06-29 追記：運営者情報の非公表方針と法令開示を両立

- 原典方針では、代表者名、所在地、電話番号は代表者のプライバシー及び安全に関わるため公開ページ上では非公表とし、請求があれば遅滞なく回答する整理だった。この方針は維持する。
- ただし、個人情報保護法上の保有個人データに関する事項、開示等請求、苦情相談、特定商取引法上の販売事業者表示その他法令上必要な運営者情報について、公開ページ上で単に「非公表」とだけ書くと、本人が権利行使に必要な情報へ到達できないように読まれるリスクがある。
- プライバシーポリシーの問い合わせ窓口では、運営者の氏名又は名称、住所、法人の場合の代表者氏名、特定商取引法上の販売事業者表示その他法令上必要な運営者情報に関する問い合わせを受け付けることを明確化した。
- 代表者名、住所、電話番号その他常時掲示が代表者のプライバシー又は安全に関わる情報は公開ページ上では非公表とする場合があるが、個人情報保護法、特定商取引法その他法令に基づき開示が必要な場合、又は正当な請求がある場合は、本人確認、請求内容確認、安全確保のうえ法令に従い遅滞なく回答する文言へ修正した。
- 公開前No-Goとして、App Store Connect、特商法ページ、Privacy、Support、サポート返信テンプレートの間で、代表者情報を「一切回答しない」「理由がないと法令上必要な開示もしない」と読ませない。反対に、公開ページや証跡ファイルへ実住所、個人電話番号、代表者個人情報を不要に掲載しない。

参照:
- e-Gov 個人情報の保護に関する法律: https://laws.e-gov.go.jp/law/415AC0000000057
- e-Gov 特定商取引に関する法律: https://laws.e-gov.go.jp/law/351AC0000000057

---

## 2026-06-29 追記：責任上限・利用者補償を強行法規前提で補強

- 消費者契約法上、事業者の損害賠償責任を全面的に免除する条項や、故意又は重過失による責任を免除する条項は無効となり得る。そのため、Megrum利用規約では「故意又は重過失を除く」「消費者契約法、個人情報保護法その他の法令により無効又は制限される範囲では適用しない」という留保を維持する。
- 一方で、Megrumは無料利用が中心になり得るユーザー間取引プラットフォームであり、会員間支払い、郵送交換、現地交換、UGC、外部AI、広告、権利侵害、通報、削除申出等により、運営者側に調査費、削除対応費、外部サービス対応、弁護士費用、和解金等が発生し得る。無料利用者について責任上限がないままだと、軽過失レベルの事故でも開発者側の予見可能性が低い。
- 利用規約では、運営者が責任を負う場合の範囲を通常かつ直接の損害に限定し、有料サービスでは過去6か月の支払総額、無料利用又は支払額がない場合は1万円を上限とする条項を追加した。ただし、運営者又はその代表者若しくは使用者の故意又は重過失、及び強行法規で制限される範囲には適用しない。
- 利用者側の補償条項では、利用者の規約違反又は帰責事由により第三者請求、削除申出、権利侵害申立て、通報、捜査又は行政対応、アプリストア/外部サービス/決済事業者対応、調査、証跡保全、削除、復旧、再発防止、合理的な弁護士費用その他専門家費用、和解金又は賠償金が発生した場合に、利用者が自己の責任と費用で解決し運営者に協力することを明確化した。
- 弁護士レビューでは、責任上限額、有料サービスの上限算定期間、無料利用者の1万円上限、利用者補償の範囲、消費者契約法・個人情報保護法・特定商取引法・プラットフォーム規約との整合を重点確認対象にする。

参照:
- e-Gov 消費者契約法: https://laws.e-gov.go.jp/law/412AC0000000061

---

## 2026-06-29 追記：Keychain session保存・refresh tokenを公開前No-Goへ追加

- 現行Swift Nativeでは、live auth factoryが `KeychainAuthSessionStore` を使い、`AuthSession` の `accessToken`、`refreshToken`、`expiresIn`、`expiresAt`、`tokenType`、`AuthUser` をJSON化してKeychainへ保存・復元・削除する。`KeychainAuthSessionStore` は `kSecClassGenericPassword`、service `jp.megrum.auth`、account `primary` を使うが、2026-06-29時点のコード確認では `kSecAttrAccessible` やThisDeviceOnly方針の明示は未確認。
- 起動時又はrepository同期前に `MegrumAuthState.refreshSessionIfNeeded()` が期限切れ/期限間近/legacy expiryなしsessionをrefresh対象にし、`SupabaseAuthClient` は `grant_type=refresh_token` で新しいsessionを取得して保存し直す。refresh tokenはSupabase Authへ送信される機微情報としてPrivacy、App Privacy、ログ最小化、問い合わせテンプレートで扱う。
- ログアウト時は、先に端末内保存sessionを `sessionStore.clear()` で削除し、その後に `/auth/v1/logout` をaccess tokenで呼ぶ。リモートlogoutが失敗又はtimeoutしてもauthenticated shellに閉じ込めない設計だが、他端末、ブラウザ、メール、OSバックアップ、Keychain復元、認証事業者側sessionが即時かつ完全に消えるとは説明しない。
- 公開前No-Goとして、Keychain accessibility/backups/端末移行時挙動、tokenのログ混入、サポート証跡へのtoken貼付、紛失端末時の案内、logout/API失敗時の説明、アカウント削除時のAuth削除/無効化/外部連携解除の運用が未確認の状態で「ログアウト又は退会ですべてのsession/tokenが即時完全削除される」と説明しない。

参照:
- Apple Keychain Services: https://developer.apple.com/documentation/security/keychain-services
- Supabase Auth Sessions: https://supabase.com/docs/guides/auth/sessions

---

## 2026-06-29 追記：カスタムURL scheme・認証リダイレクト・ディープリンクを公開前No-Goへ追加

- 現行Swift Nativeでは、`ios-native/App/Info.plist` が `CFBundleURLTypes` / `CFBundleURLSchemes=$(MEGRUM_URL_SCHEME)` を宣言し、`MegrumRootView.onOpenURL` が受け取ったURLを `MegrumAuthState.handleOpenURL` へ渡す。`SupabaseAuthRedirectParser` はquery又はfragment内の `access_token`、`refresh_token`、`expires_in`、`expires_at`、`token_type` を読み、`SupabaseAuthClient.session(fromRedirectURL:)` はaccess tokenで `/auth/v1/user` を呼んでsessionを復元する。
- Google OAuthは `ASWebAuthenticationSession` で `https://megrum.jp/auth/oauth/authorize` を開き、callback schemeは `MEGRUM_AUTH_EMAIL_REDIRECT_URL` の `scheme` queryから導出する。Web側 `auth/oauth/authorize` Routeは `provider=google` と `megrum://auth/callback` / `megrum-preview://auth/callback` を許可し、Supabase `/auth/v1/authorize` へ転送する。
- メール認証/パスワードリセット系のWeb callbackは `next=mobile` の場合、Supabase codeをsessionへ交換したうえで、`megrum://auth/callback#...` 又は `megrum-preview://auth/callback#...` へaccess token等をfragmentで返す。`supabase/config.toml` のredirect allowlistには `https://megrum.jp/auth/callback?...` とnative callback schemeが併記されている。
- 通知 `linkPath` と `NotificationRouteIntent` は `/trades/...`、`/disputes/...`、`/meguri-board-thread?...`、`/users/...` 等を画面遷移へ変換し、未知のpathはfallback tabへ落とす。これらは利便性のための画面遷移であり、リンクに含まれるID、path、query、通知ID又はエラー情報が通知、ログ、ブラウザ履歴、共有又は外部サービスに残る可能性がある。
- 公開前No-Goとして、`MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth設定、Web中継Route、App Store提出メモが不一致の状態では提出しない。メール認証リンク、パスワードリセットリンク、認証callback、access token、refresh token、通知 `linkPath`、deep linkを公開・転送してよいように説明しない。
- カスタムURL schemeはOS/端末/インストール済みアプリ/外部ブラウザ/認証事業者に依存するため、Universal Links相当のドメイン所有確認済みリンクと同等の保証をする説明をしない。ユーザー向けには公式ドメイン確認、不審な認証画面に秘密情報を入力しないこと、リンク/認証コードを共有しないことをFAQとアプリ内コピーで案内する。

参照:
- Apple Defining a custom URL scheme for your app: https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app
- Apple ASWebAuthenticationSession: https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession

---

## 2026-06-29 追記：カメラ・写真ライブラリ・共有シートを公開前No-Goへ追加

- 現行Swift Nativeでは、`NativeCameraCaptureView` が `UIImagePickerController` のcameraで撮影し、`UIImage.jpegData(compressionQuality: 0.88)` によりJPEGへ再生成する。これは撮影時の元メタデータを落としやすい経路だが、全ての端末、OS、画像処理、外部共有先でメタデータ削除を保証できるものではない。
- `PhotosPickerItem.loadTransferable(type: Data.self)` で読み込んだ写真は、`normalizedPhotoUpload` / `normalizedChatPhotoUpload` がJPEG/PNG/GIF/WebP等の対応形式かつサイズ上限内なら元データのまま `GoodsPhotoUpload` として保存し得る。したがって、写真ライブラリ由来のEXIF、GPS位置情報、撮影日時、端末情報その他画像メタデータが残る可能性をPrivacy、FAQ、App Privacy、権限前コピーで説明する。
- カメラ/写真ライブラリ用途は、Info.plist文言上の証跡写真・グルーム投稿だけでなく、現行コード上はグッズ写真、プロフィール画像、取引チャット写真、服装写真、証跡写真、グルーム画像、スポット掲示板サムネイル、一括登録/顔候補付け等にも広がる。公開前No-Goとして、`NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` が実用途より狭く、審査又はユーザーに誤解を与える状態では提出しない。
- `GoodsShareActivitySheet` は `UIActivityViewController` で共有用テキストと生成画像を外部アプリへ渡す。`GoodsSharePostRenderer` / `GoodsSharePostTextBuilder` は、会員の表示名、登録グッズ画像、グッズ名、グループ名、メンバー名、タグ、グッズ種別、ハッシュタグ等を共有物に反映し得る。共有先を選択した後の保存、公開、再共有、削除、アクセス解析、広告利用、メタデータ利用は外部サービスの規約/ポリシーに従う。
- 公開前No-Goとして、写真ライブラリ画像のメタデータが常に削除される、外部共有先で保存又は再共有されない、Megrumが外部SNSへ自動投稿する、又は共有後もMegrumが削除/公開範囲を管理できるように説明しない。

参照:
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Review Guidelines 5.1.1: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：ホーム候補・検索・レコメンド・Product Personalizationを公開前No-Goへ追加

- 現行Swift Nativeのホーム候補は、閲覧者と相手会員の在庫、wish、個別条件、タグ、推し、交換方法、活動エリア、都道府県、日程、支払い方法要約、評価、完了取引数、未読通知、ブロック関係、テストアカウント除外、メグルムプラス有効ユーザー等を組み合わせて生成される。検索結果は、検索語、推し、グッズ種別、タグ、交換方法、支払い方法、wish一致、個別条件一致、閲覧者条件等で絞り込み、表示順ではメグルムプラス優先表示が入る経路がある。
- 「マッチしてるよ！」「交換できるかも？」「全一致」等のラベルやチップは、登録情報とルールに基づく参考表示であり、所有権、真贋、在庫確保、支払い、発送、現地合流、日程、場所、本人性、安全性、信用、支払能力、取引意思、取引成立又は履行の保証ではない。候補表示を「運営者による推薦」「安全確認済み」「信用保証」と読ませない。
- `search_query_logs`、`record_search_query`、`get_popular_search_terms` のDB/RPC基盤では、検索語、`normalized_term`、`result_count`、30日人気検索集計を扱う。ただし2026-06-29時点のSwift読み取りでは `record_search_query` の呼び出しは未確認。実ビルドで検索ログ又は人気検索を有効化する場合は、Privacy、App Privacy、FAQ、提出メモへSearch History / Usage Data / Product Personalizationとして反映する。
- 利用規約とプライバシーポリシーでは、候補表示、検索結果、表示順、レコメンド、検索候補、人気検索、Product Personalization、有料サービスによる優先表示、広告挿入が自動処理又は運営上の表示制御により変動すること、重大な法的効果を自動的に発生させる決定ではなく、取引条件は会員が打診、チャット、実物確認等で自ら確認することを補強した。
- 公開前No-Goとして、候補表示や検索結果が取引成立保証、安全確認済み、本人確認済み、信用保証、支払能力確認済み、真贋確認済み、公式推薦又は「広告/有料優先なし」のように見える状態では提出しない。Plus優先表示、広告挿入、検索ログ、人気検索、候補表示の根拠データをApp Privacyと公開説明に反映しない状態でも提出しない。

参照:
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Review Guidelines 5.1.1: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：APNs通知本文・端末プレビュー・Push通知4.5.4を公開前No-Goへ追加

- 現行Swift Nativeでは、ログイン後に `UNUserNotificationCenter` で通知許可を確認し、許可済み又は許可された場合に `UIApplication.shared.registerForRemoteNotifications()` を呼び、APNs device tokenを受け取る。`SupabaseNotificationClient` は `notification_devices` へ `platform='ios'`、`push_provider='apns'`、`native_device_token`、`app_version`、`last_seen_at` をupsertし、ログアウト時のclient-side revoke経路と、APNs応答が `410` / `BadDeviceToken` / `Unregistered` の場合にEdge Function側で `revoked_at` を入れる経路がある。
- `send-apns-notification` Edge Functionは、`notifications` 行の `title`、`body`、`link_path` と未読数を読み、APNs alert payloadとして `title`、`body`、`badge`、`sound`、`notificationId`、`linkPath` を送信する。取引チャットのテキスト本文は短縮プレビューとして通知bodyに入り得る。写真、服装写真、現在地共有、到着状況、証跡、評価、キャンセル要請は出来事の概要が通知bodyに入り得る。
- めぐりメッセージ、グルーム、スポット掲示板系は現行migration上、本文を入れずタイトル又は概要のみとする経路が多いが、タイトルだけでも相手、行動又は文脈が推測される。通知はロック画面、通知センター、連携端末、OS通知プレビュー、APNs/Expo Push等の外部サービス仕様により表示、保存又は転送され得る。
- Apple App Review Guidelines 4.5.4の観点として、Push通知をアプリ利用の必須条件にしない、機微な個人情報又は秘密情報をPush通知で送らない、プロモーション又は直接マーケティング目的のPush通知は明示的同意とオプトアウト手段を用意する、という前提をReview Notes、FAQ、アプリ内文言、Privacy、App Privacy回答に反映する。
- 公開前No-Goとして、Push通知を許可しないと登録又は主要機能を使えない、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文などを通知本文へ出す、通知本文/未読バッジ/APNs token/linkPathをApp Privacyへ反映しない、又は販促Pushを同意・停止手段なしで送る状態では提出しない。

参照:
- Apple Registering your app with APNs: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns
- Apple App Review Guidelines 4.5.4 / 5.1.1: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：古物営業・チケット不正転売・盗品リスクを公開前No-Goへ追加

- e-Gov法令データで、古物営業法は盗品等の売買防止、速やかな発見等を目的とし、古物商、古物市場主、古物競りあっせん業者の規制があることを確認した。チケット不正転売禁止法は、特定興行入場券の不正転売及び不正転売目的の譲受けを禁止している。
- 現行Swift Nativeには、在庫、wish、打診、個別募集、現金差額、定価交換、支払い条件、PayPay/銀行振込/現金交換、郵送交換、評価、証跡、異議申し立ての導線がある。ユーザー同士の交換補助を超えて、売買マーケット、古物商、古物市場、古物競りあっせん、販売代理、委託売買、買取、チケット譲渡の場に見えると、審査・法務・事故時説明リスクが高い。
- 利用規約では、本アプリが古物商、古物市場、古物競りあっせん業者、オークション、競り、販売マーケット、買取、委託売買/委託交換、販売代理又は保管サービスではないこと、会員が古物営業、反復継続的販売、チケット/入場資格/QRコード/抽選権/アカウント等の譲渡、盗品等の登録をしてはならないことを補強した。
- 公開前No-Goとして、App Store説明文、FAQ、スクショ、Review Notes、アプリ内コピーでMegrumが売買、買取、古物営業、オークション、チケット譲渡、決済代行、エスクロー、入場資格保証又は正規/公式流通の確認を行うように見える状態では提出しない。

参照:
- e-Gov 古物営業法（昭和二十四年法律第百八号）: https://laws.e-gov.go.jp/law/324AC0000000108
- e-Gov チケット不正転売禁止法（平成三十年法律第百三号）: https://laws.e-gov.go.jp/law/430AC1000000103

---

## 2026-06-29 追記：精密位置・地図・逆ジオコーディングを公開前No-Goへ追加

- 現行Swift Nativeでは、`MegrumLocationState` が `CLLocationManager` を `kCLLocationAccuracyNearestTenMeters`、`distanceFilter=10` で利用し、`CLGeocoder.reverseGeocodeLocation` により座標を場所名へ変換する。`HomeLocalCoordinateStorageCodec` は緯度経度を小数8桁で保持でき、`TradeDetailScreenActions.sendLocationMessage`、`MegrumAppStateMeguriActions`、`BoardThreadDetailScreen`、`SupabaseGroomPayloads`、`BoardScopeQueryContext` では現在地共有、近くのグルーム、スポット掲示板の閲覧・作成・返信範囲判定へ緯度経度を送信する経路がある。
- 利用規約では、地図表示、現在地、場所名、近接表示、距離表示、逆ジオコーディングが参考情報であり、端末、OS、MapKit、CoreLocation、通信環境、会員操作等に依存し、正確性、継続性、安全性、到達可能性又は現地状況を保証しないことを追記した。現地交換条項では、表示された現在地や場所名だけに依存せず、公共性、安全性、会場又は施設ルールを自ら確認する義務を追記した。
- プライバシーポリシーでは、位置情報を許可した場合に、精密な緯度経度、精度、時刻、場所名を取得、表示、送信、保存又は場所名へ変換し得ること、画面上で「近く」「1km圏内」「3km圏内」等と表示されても内部処理やサーバー送信では精密座標を扱い得ること、MapKit/CoreLocation/CLGeocoder等のOS・地図関連サービスで処理され得ることを追記した。
- 公開前No-Goとして、近くのグルーム、スポット掲示板、現在地共有、位置情報メッセージ、地図表示又は逆ジオコーディングが見えるのに、App PrivacyでPrecise Locationを選ばない、Privacy/FAQ/Review Notesで精密座標・外部地図サービス・保持/削除例外を説明しない、又は「ざっくり地域だけ」「常時共有なしだからLocation回答不要」として提出する状態では提出しない。

参照:
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Review Guidelines 5.1.1 / 5.1.2: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：EU DSA・配信地域・IAP Availabilityを公開前No-Goへ追加

- 初回App Store提出は、日本語UI、日本語Support、現地交換MVP、代表者情報非公表方針、法務/サポート負荷を踏まえ、Japan-only配信候補として扱う。All Countries or Regions又はEU 27 territoriesを含める場合は、EU DSA trader status、App Store商品ページに表示されるProvider/Seller/contact情報、代表者名・住所・電話番号の非公表方針との差分、英語/現地語サポート可否、IAP Availabilityをオーナー確認済みにする。
- EU DSAのtrader該当性はAppleが判断するものではなく、運営者又は弁護士の自己判断が必要。traderとしてEU配信する場合、App Store商品ページに表示される連絡先情報が、特商法の「請求があれば遅滞なく開示」とは別に公開され得るため、提出前に表示内容を確認する。
- DSA用の住所、電話番号、本人確認情報、App Store Connect上の実連絡先はリポジトリ、公開FAQ、Review Notes、証跡ファイル本文へ書かず、App Store Connect画面又はオーナー管理の安全な保管場所に限定する。
- 公開前No-Goとして、初回Japan-only方針なのにEU又はAll Countries or Regionsを含むAvailabilityで提出する、EU配信するのにtrader status又は公開連絡先が未確認、アプリ本体はJapan-onlyなのにIAPだけ広域販売される、又はApp Store商品ページ表示連絡先を把握しないまま提出する状態では提出しない。

参照:
- Apple Manage availability for your app on the App Store: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store
- Apple Manage European Union Digital Services Act trader requirements: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/
- Apple Set availability for In-App Purchases: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases/

---

## 2026-06-29 追記：公式非提携・権利物を公開前No-Goへ追加

- 現行実装とDB seedには、グループ、メンバー、キャラクター、作品、商品分類、シリーズ候補、検索補助などの文脈で実在の名称や権利物を扱い得る導線がある。AIシリーズ候補や外部検索候補も、公式ページ、EC、二次流通、SNS等の外部情報を参照し得るため、名称表示や候補表示が、公式、公認、提携、代理、権利者承認、権利許諾、真贋確認又は取引可能性を意味するように見えるリスクがある。
- 利用規約では、Megrumがアーティスト、タレント、キャラクター、作品、芸能事務所、レーベル、出版社、制作会社、イベント主催者、興行主、販売者、権利者、公式ファンクラブ等の公式サービス、公認サービス、提携サービス又は代理サービスではないこと、名称や標章は検索、分類、識別又は説明の便宜であり、承認、協賛、権利許諾、真贋確認又は取引可能性を意味しないことを追記した。
- 公開FAQ、公開サポート、App Store提出素材、Content Rights回答、Review Notes、審査ガイドライン表、初回提出スコープ監査、アプリ内安全文言では、実在IP、商標、公式名称、AI/検索候補、外部画像URLが見える場合に、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証を揃える方針へ更新した。
- 公開前No-Goとして、スクショ、初期データ、App Storeメタデータ、Review Notes、FAQ、アプリ内コピーで、Megrumが権利者、所属事務所、興行主、販売者又は公式ファンクラブの公式、公認、提携又は代理サービスであるように見える状態、又は名称、AI/検索候補、外部画像URLが権利確認済み、公式推奨、真贋確認済み、取引可能確認済みであるように見える状態では提出しない。

参照:
- Apple App Review Guidelines 5.2 Intellectual Property: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：外部AIシリーズ候補・顔特徴量を公開前No-Goへ追加

- `supabase/functions/suggest-goods-series/index.ts` は、認証済みユーザー確認後、最大3件の画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補名をOpenAI Responses APIへ送信し、`tools: [{ type: "web_search" }]` を必須実行する。Swift側の `GoodsBulkTagSheet` は「画像からシリーズ名称の候補を出す」ボタンと「登録した画像と選択中のグループ情報を使って候補を検索します。」の説明に留まり、2026-06-29時点の読み取りでは、送信前にOpenAI、外部AI、Web検索、保持、学習利用、第三者/未成年/権利未処理画像禁止を明示する画面文言は未確認。
- 利用規約とプライバシーポリシーでは、画像シリーズ候補機能について、画像データ又は画像URL、推し文脈、既存候補名が外部AIへ送信され得ること、Web検索その他外部情報参照が行われ得ること、AI出力や検索候補は公式情報・権利処理済み素材・正確な商品情報を保証しないこと、第三者の顔、未成年者、住所、チケット、注文履歴、QRコード、秘密情報、未公開情報、権利未処理画像を送信しないことを追記した。
- `VisionFaceDetectionService` はApple Visionで顔矩形を検出するが、Face ID又は生体認証APIではない。`UnifiedMemberTaggingService()` の既定実装では本番用顔特徴量モデルは未設定で、エラー文言上も「顔特徴量モデルが未設定です。」とされる。一方、`member_face_profiles`、`face_uploaded_images`、`detected_faces`、`face_match_candidates`、`face_match_corrections` のDB基盤と `SupabaseFaceRecognitionClient` は存在し、補正履歴の `should_add_training_data` / `shouldAddTrainingData` は既定trueの経路がある。
- `member_face_profiles` のRLSは `authenticated can read active member face profiles` であり、現行selectには `embedding`、`embedding_model`、`source_image_url`、`consent_recorded_at` が含まれる。実在人物の顔特徴量又はsource image URLが格納される場合、全認証済みユーザーが読み得る設計はSensitive Info / biometric data相当として高リスクであり、アクセス最小化、同意証跡、削除/利用停止、管理バックエンド限定化、App Privacy回答、公開説明が揃うまで公開前No-Goとする。
- 現行 `GoodsEditorSheetInventoryPhotoActions.applyFaceTaggingCorrections` は、選択された候補メンバーをdraft又は一括登録メタデータへ反映するだけで、`createUploadedImage`、`createDetectedFaces`、`createMatchCandidates`、`createCorrection` の保存呼び出しは未確認。ただしUI上の顔候補確認が見える場合、候補提示だけでも本人確認/Face ID/真贋鑑定ではない説明、第三者画像禁止、Sensitive Info回答、外部送信有無、保存の有無、削除又は利用停止方法を公開前に同期する。
- 公開前No-Goとして、「画像からシリーズ名称の候補を出す」等の外部AI導線が見えるのにOpenAI/外部AI、画像又は画像URL送信、Web検索、保持、学習不使用、濫用監視ログ、削除可否、第三者/未成年/権利未処理画像禁止を説明していない状態では提出しない。顔候補付けが見えるのに、`member_face_profiles` のembedding/source image URLが広く読める、補正/学習データ追加が既定trueのまま説明・任意性・削除手段がない、又はFace ID/本人確認のように読める状態でも提出しない。

参照:
- OpenAI Data controls: https://platform.openai.com/docs/guides/your-data
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

---

## 2026-06-29 追記：会員間支払い・外部決済サービス非関与を公開前No-Goへ追加

- 現行Swift Native実装では、支払い方法設定に銀行振込、PayPay、現金交換、その他の対応可否があり、銀行振込を選ぶ場合は銀行名、支店名、口座種別、口座番号、口座名義を本人専用の `user_payment_settings` に保存する。
- 現行migration上、ホーム候補や公開交換条件へ出すのは `users.payment_methods` / `payment_note` の要約であり、口座詳細は本人専用テーブルに分離される。一方、金額指定を含む取引が合意済みになると、`proposals.sender_payment_settings` / `receiver_payment_settings` へ成立時スナップショットを固定し、成立後の当事者向け画面で相手の銀行口座情報等が表示される経路がある。
- `PaymentSettingsMethodViews` では、PayPayは「リンク登録なし。対応可否だけを表示します」とされており、現行コード上PayPayアカウント、送金リンク、QRコード、残高、送金可否、本人確認をMegrumが扱う経路は確認していない。
- 利用規約とプライバシーポリシーでは、銀行振込、PayPay、現金交換その他外部決済サービスへの対応可否が表示される場合でも、運営者は資金の受領、保管、送金、収納代行、決済代行、返金、チャージバック対応、本人確認、信用審査、支払能力確認、エスクロー、外部決済アカウント/リンク/QRコード/残高/送金可否/受領可否の確認又は保証を行わないことを追記した。
- 公開前No-Goとして、公開FAQ、Review Notes、アプリ内コピー、スクショ、App Privacy説明で、Megrumが資金移動業者、収納代行業者、決済代行業者、エスクロー事業者、金融機関、本人確認事業者、支払能力確認者又はPayPay等外部決済サービスの安全確認者であるように説明しない。支払い設定又は口座番号入力が見える場合は、Financial Info / Payment InfoをApp Privacy回答候補へ上げる。

参照:
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- e-Gov 資金決済に関する法律: https://laws.e-gov.go.jp/law/421AC0000000059

---

## 2026-06-29 追記：Storage公開範囲・署名URL・外部AI画像送信を公開前No-Goへ追加

- 現行migration上、`goods-photos` と `avatars` はpublic bucketで、グッズ写真及びプロフィール画像の公開表示用途として作られている。利用規約とプライバシーポリシーでは、公開画像、公開URL、端末キャッシュ、スクリーンショット、外部共有、再転載のリスクと、会員が第三者の顔・住所・チケット・注文履歴・QR/バーコード・EXIF/GPS等を含む画像を登録しない責任を追記した。
- `chat-photos` はprivate bucketかつproposal参加者限定policyだが、現行Swift Nativeでは取引チャット写真、服装写真、証跡写真のsigned URLを365日で生成する経路がある。非公開設計であっても、署名URL、閲覧相手、端末キャッシュ、スクリーンショット、通報/証跡コピー、バックアップにより完全秘匿又は即時削除を保証しない文言を追記した。
- `groom-posts` は後続migrationでprivate化し、`meguri-message-media` は送受信者限定policy。一方、`meguri-board-media` はprivate bucketだがStorage policy上はauthenticated user全体selectで、アプリ側が表示可能thread/replyのpathだけsigned URL化する設計。公開前No-Goとして、path推測、一覧、閲覧範囲、block、非表示、削除、通報時保持の妥当性を確認する。
- `suggest-goods-series` Edge Functionは、認証済みユーザー確認後、最大3件の画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補をOpenAI Responses APIへ送信し、`web_search` を必須実行する。導線を出す場合、送信先、送信情報、web search利用、学習利用、保持、削除可否、同意又は任意性、第三者画像禁止をPrivacy/App Privacy/Review Notes/アプリ内説明へ同期する。
- 公開前No-Goとして、参加者限定画像がpublic bucketにある、private mediaの長期signed URLを説明できない、`meguri-board-media` のauthenticated selectが表示範囲と矛盾する、OpenAIへ画像を送る導線があるのに送信・保持・学習利用・web search利用を説明していない、又は画像base64/API key/service role keyをログや公開証跡へ出している状態では提出しない。

## 2026-07-03 追記：meguri-board-media の authenticated-wide select を縮小

- `supabase/migrations/20260703120000_harden_meguri_board_media_storage_policy.sql` で、`meguri-board-media` の旧 `authenticated` 全体select policyを削除し、表示可能な掲示板thread/replyの `image_paths` に紐づくobjectだけをselect可能にするStorage policyへ変更した。
- これにより、path推測だけで任意の掲示板画像を署名URL化できる範囲は縮小した。ただし、本番適用後の `pg_policies` 確認、近距離scopeとStorage policyの境界、削除/通報/保持時のobject cleanup、signed URL期間の説明は引き続き公開前確認に残る。

## 2026-07-03 追記：退会申請時の通知device失効を追加

- `supabase/migrations/20260703123000_revoke_notification_devices_on_account_deletion.sql` で、`request_account_deletion_for_viewer()` の退会申請成功時に、そのユーザーの未失効 `notification_devices` へ `revoked_at` を設定するようにした。
- これにより、退会申請後に通常の通知配送対象へ残り続けるリスクは縮小した。ただし、30日後の削除完了ジョブ、Authユーザー削除又は無効化、Apple/Google連携解除、外部provider側の完全削除、削除完了通知又は問い合わせ回答運用は引き続き公開前確認に残る。

---

## 2026-06-29 追記：管理者権限・監査ログ・運営担当者アクセスを公開前No-Goへ追加

- 現行Web管理画面では、`web/src/lib/admin/permissions.ts` が `owner`、`support`、`trust_safety`、`billing`、`viewer` ロールと、`users.read`、`users.update_status`、`reports.read`、`reports.moderate`、`notifications.send`、`billing.read`、`entitlements.manage`、`audit.read` 等の権限を扱う。`owner` 又は `*` は広い権限を持つ。
- 管理者権限の確認、ユーザー一覧、通報/異議申し立て一覧、推し追加リクエスト、有料権限、監査ログ、運営通知は、Webサーバー側の service role client を通じて読み書きされる。service role はRLSを迂回し得るため、サーバー側限定、権限確認、MFA、監査ログ、secret管理の説明が必要。
- 管理者操作は `admin_audit_logs` に、actor、action、target、reason、before_state、after_state、metadata、request_ip、user_agent等を保存する。変更前後の状態やmetadataにはユーザー情報、通報内容、課金/権限情報、運営通知情報等が含まれ得る。
- 利用規約では、通報対応、削除申出、問い合わせ、課金、権限付与、アカウント状態変更、運営通知、セキュリティ、法令対応、監査等のため、権限を付与された運営担当者が必要な範囲で情報を確認・更新・保存し、監査ログへ記録することを追記した。
- プライバシーポリシーでは、管理者ロール、権限、MFA要求、管理者操作、手動有料権限、運営通知、Webhook/決済同期、IPアドレス、User-Agent、変更前後の状態を取得情報・利用目的・安全管理措置・保存期間へ追加した。
- 公開前No-Goとして、管理者画面を使うのに、運営担当者アクセス、service roleのRLS迂回、MFA要求、権限分離、監査ログ保存、監査ログ内の個人情報、secret管理、退会後の監査ログ保持をPrivacy/App Privacy/セキュリティ監査で説明できない状態で提出しない。

---

## 2026-06-29 追記：公開Web・アプリ内法務表示同期リスクを公開前No-Goへ追加

- 2026-06-29時点のコード読み取りでは、現行Webの法務ページは `web/src/app/terms/page.tsx` の `/terms`、`web/src/app/privacy/page.tsx` の `/privacy`、`web/src/app/support/page.tsx` の `/support` が実装済みであり、ページ内更新日は `2026年6月26日` だった。
- 一方、公開文書群では `https://megrum.jp/legal/terms`、`https://megrum.jp/legal/privacy`、`https://megrum.jp/support/account-deletion`、`https://megrum.jp/support/privacy-request`、`https://megrum.jp/support/report`、`https://megrum.jp/support/ai`、`https://megrum.jp/support/faq` を初回提出前の公開候補としている。現行コード読み取りでは、これらの個別サポートURLや `/legal/*` routeの実装は未確認。
- `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift` の登録同意リンクは `https://megrum.jp/terms` と `https://megrum.jp/privacy` を指す。`ios-native/Sources/MegrumApp/LegalDocumentContent.swift` / `SettingsLegalViews.swift` のアプリ内法務表示は要約であり、正式な法的本文ではない旨を表示している。
- 現行Webの短縮Terms/Privacyには、2026-06-29版ドラフトで追加した郵送交換、会員間支払い情報、顔候補付け、通知本文、広告、公開プロフィール、年齢/性別/活動エリア、評価/通報/ブロック、削除申出・送信防止措置等の詳細が未反映である可能性が高い。
- 公開前No-Goとして、App Store ConnectのPrivacy Policy URL、Support URL、Review Notes、アプリ内登録同意リンク、Settingsの法務導線、公開Web本文、Markdown/DOCXドラフトを同じURLと同じ本文へ同期する。404でない旧短縮ページを「公開済み」と扱わない。
- `ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false` とUserDefaults Required Reason APIのみの最小構成であり、App Store ConnectのApp Privacy回答、公開Privacy本文、外部サービス台帳、SDK/通信監査と別途照合する。Privacy Manifestが最小であることを、収集データがない根拠として扱わない。

---

## 2026-06-29 追記：削除申出・送信防止措置・プラットフォーム透明性リスクを公開前No-Goへ追加

- 現行Swift Native実装では、プロフィール、グッズ画像、グルーム、スポット掲示板、取引チャット、証跡写真、評価コメント等のUGCがあり、ユーザー通報、グッズ通報、掲示板通報、取引異議申し立て、問い合わせ経由の権利侵害申出を受け得る。
- 2025-04-01施行の情報流通プラットフォーム対処法は、特定電気通信による権利侵害対応の枠組みに加え、大規模特定電気通信役務提供者には削除対応の迅速化・運用状況の透明化等の追加義務を置く。Megrumは現時点で大規模指定事業者である前提にはできないが、UGCを扱う以上、削除申出、送信防止措置、発信者への確認又は通知、対応記録の運用を提出前に説明可能にする。
- 利用規約では、権利侵害、名誉毀損、プライバシー侵害その他違法又は不適切な情報に関する削除申出、送信防止措置の申出、発信者への確認又は通知について、適用法令、ガイドライン及び運営基準に従って対応する一方、法令上必要な場合を除き、一定期間内の回答、削除、非表示、発信者情報開示又は個別理由開示を保証しないことを追記した。
- プライバシーポリシーでは、削除申出、送信防止措置申出、発信者確認又は通知、法令上必要な照会、回答、判断、対応履歴を取得情報・利用目的・関係者提供可能性へ追加した。
- 公開前No-Goとして、公開FAQ、サポートページ、Review Notes、問い合わせ返信で、Megrumが大規模指定事業者である、全件を7日以内に削除/回答する、発信者情報を必ず開示する、申出どおり必ず削除する、常時監視している、と誤認させない。実際に削除申出窓口を公開する場合は、受付情報、本人/権利者確認、対象URL/画面/ID、発信者確認要否、保存記録、通知テンプレートを運用SOPに沿って準備する。

参照:
- e-Gov 法令検索「特定電気通信による情報の流通によって発生する権利侵害等への対処に関する法律」: https://laws.e-gov.go.jp/law/413AC0000000137

---

## 2026-06-29 追記：評価・通報・ブロック・モデレーションリスクを公開前No-Goへ追加

- 現行Swift Native実装では、取引完了後に `user_evaluations` へ1-5 starsと任意コメントを保存し、公開プロフィールの評価一覧では評価者公開情報、星、コメント、評価日をログイン済みユーザーへ表示する経路がある。取引チャット内でも両者評価完了後に評価コメントを表示する経路がある。
- 現行コード上、ユーザー通報は `reports`、グッズ通報は `goods_reports`、グルーム通報は `groom_reports`、スポット掲示板通報は `meguri_board_reports`、取引異常時の異議申し立ては `disputes` に保存される。理由、補足本文、証跡URL、status、運営対応情報は安全対応、監査、法令対応、虚偽通報対策のため保持され得る。
- 現行コード上、ブロック関係は `groom_user_blocks` に保存され、検索結果、ホーム候補、公開プロフィール、グルーム、めぐりメッセージ、掲示板、通知等の表示/送信抑制に使われる。一方、過去の取引、取引チャット、証跡、評価、通報、異議申し立て、監査記録を当然に削除するものではない。
- 利用規約では、評価コメントの公開範囲、個人情報・名誉毀損・虚偽又は報復目的の評価禁止、通報/異議申し立て濫用禁止、モデレーションの非保証、常時監視義務なし、緊急時は警察・消防・医療機関等へ連絡すべきことを追記した。
- プライバシーポリシーでは、評価、通報、異議申し立て、ブロック、モデレーション記録の取得情報、利用目的、第三者/関係者/外部機関への提供可能性、通報者秘匿の限界、退会後又は削除後の例外保持を追記した。
- 公開前No-Goとして、App Privacy、FAQ、Review Notes、アプリ内コピーで、評価を本人確認・安全確認・信用保証・支払能力確認・商品品質保証・運営推薦のように説明しない。通報/ブロック/モデレーションを緊急通報、法的判断、削除/解決保証、通報者絶対秘匿として説明しない。

---

## 2026-06-29 追記：公開プロフィール・性別・活動エリア・候補表示リスクを公開前No-Goへ追加

- 現行Swift Native実装では、アカウント設定で性別と活動エリアを扱い、公開プロフィールでは表示名、ハンドル、プロフィール画像、自己紹介、活動エリア、性別、推し情報、評価、完了取引数等が表示され得る。
- 現行コード上、ホーム候補用RPC `list_home_user_summaries_for_viewer()` は `gender`、`age`、`payment_methods`、`payment_note`、評価サマリ、完了取引数を返す。公開プロフィールRPCは `primary_area`、`gender`、`age`、評価サマリを返す。
- 利用規約では、公開プロフィール、検索結果、ホーム候補、めぐり、評価、交換条件、支払い方法要約その他の表示は参考情報であり、本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済み又は運営推薦を意味しないことを追記した。
- プライバシーポリシーでは、活動エリア、性別、年齢又は年代等がプロフィール、ホーム、検索、めぐり、交換条件等で表示され得ること、相手情報を目的外利用、差別、嫌がらせ、外部照合、データセット化に使ってはならないことを追記した。
- 公開前No-Goとして、App StoreのApp Privacy、公開FAQ、Review Notes、アプリ内コピーで「本人確認済み」「安全確認済み」「法的性別確認済み」「支払能力確認済み」「運営が推薦」と誤認させない。性別入力は表示・機能提供のための自己入力情報であり、性自認、性的指向、法的性別又は本人確認を証明するものと説明しない。

---

## 2026-06-29 追記：未成年・生年月日・年齢表示リスクを公開前No-Goへ追加

- 現行Swift Native実装では、アカウント設定フローで生年月日入力が必須であり、未来日を拒否する検証はある一方、最低年齢制限、公的年齢確認、身分証確認、保護者同意確認、保護者管理機能は未確認。
- 現行コード上、入力された生年月日から年齢を算出して保存・表示する経路があり、プロフィール、ホーム、検索、めぐり等で年齢又は年齢に基づく派生情報が表示され得る。
- 利用規約では、未成年者は親権者その他法定代理人の同意を得ること、生年月日・年齢・性別・活動エリアを正確に登録すること、生年月日又は年齢表示は公的本人確認、年齢認証、法定代理人同意確認又は身分証確認を意味しないことを追記した。
- プライバシーポリシーでは、生年月日はそのまま相手会員に表示しない方針だが、年齢又は年代等の派生情報が表示される場合があること、自己申告年齢を安全上の制限・確認・保護者相談案内に使う場合があることを追記した。
- 公開前No-Goとして、App StoreのAge Rating、App Privacy、FAQ、Review Notes、公開サポート、アプリ内コピーで、「年齢確認済み」「保護者同意確認済み」「本人確認済み」と誤認させない。未成年の現地交換、位置情報、服装写真、郵送先情報、会員間支払い情報、取引チャットについては、保護者相談・同伴推奨と安全上の制限可能性を説明する。

---

## 2026-06-29 追記：退会申請・削除予定日と完了処理未確認リスクを公開前No-Goへ追加

- 現行Swift Native実装では、設定画面の退会導線から、注意表示、退会理由選択、任意メモ、最終確認を経て `request_account_deletion_for_viewer()` RPCを呼び出す。
- Supabase RPCは、進行中取引（`sent` / `negotiating` / `agreement_one_side` / `agreed`）がある場合に退会申請を拒否し、申請成功時に `users.account_status='deletion_requested'`、`users.deletion_requested_at=now()` を更新し、`account_deletion_requests` に理由、任意メモ、申請日時、30日後の `deletion_scheduled_at`、`status='requested'` を保存する。
- 申請成功後のSwiftUI側は `viewer.accountStatus = .deletionRequested` へ更新し設定画面を閉じるが、2026-06-29時点の読み取りでは、全画面を強制ログアウト又は全機能ブロックへ切り替える処理までは未確認。そのため、公開文面では「通常利用を必ず停止済み」と断定せず、削除申請中状態と利用制限の可能性として扱う。
- 2026-06-29時点のコード確認では、30日後に実削除又は匿名化を行うジョブ、`status='completed'` 更新処理、削除申請キャンセルAPI、ログインで `active` に復旧する処理、Sign in with Apple token revoke、Google連携解除、削除完了通知は未確認。APNs tokenはログアウト時のclient-side revokeとAPNs失効応答時のEdge Function revoke経路があるが、退会申請又は削除完了に連動して全端末tokenを無効化する処理は未確認。
- 利用規約では、削除申請中状態として取り扱われ、通常の会員向け機能や表示、検索、打診、取引、投稿、通知等を制限することがあること、削除予定日は処理予定の目安であり、削除、匿名化、外部連携解除、バックアップ又はログからの消去が当日に完了する保証ではないこと、申請後の取消や復旧を保証しないこと、任意メモに不要な個人情報を書かないことを追記した。
- プライバシーポリシーでは、退会申請理由、任意メモ、申請日時、削除予定日、申請状態、取消又は完了日時を取得情報へ追加し、退会申請処理、問い合わせ、不正利用防止、監査、法令対応のため保存する可能性を追記した。
- 公開前No-Goとして、公開ページ、FAQ、App Review Notes、状態遷移メモで「30日後に必ず削除」「ログインで復旧可能」「Apple/Google連携解除済み」「退会申請時に全通知token無効化済み」と断定しない。完成ビルド提出前に、実削除ジョブ又は手動処理手順、外部認証token revoke、APNs / Expo token無効化、削除完了通知又は問い合わせ回答運用を確認する。

---

## 2026-06-29 追記：通知本文・ロック画面表示リスクを公開前No-Goへ追加

- 現行Swift Native実装では、ログイン後に `UNUserNotificationCenter` で通知許可を求め、許可済みの場合はAPNs tokenを `notification_devices` へ保存する。通知設定では全体、グルーム活動、チャットルーム活動のプッシュ通知ON/OFFを持つ一方、通知行自体はアプリ内通知センターのために保存される。
- Supabase Edge Function `send-apns-notification` は `notifications` の `title`、`body`、`link_path`、未読数をAPNs alert payloadとして送信する。取引チャットのテキスト本文、写真共有、現在地共有、到着状況、打診、証跡、グルーム、めぐりメッセージ、スポット掲示板等の概要が通知タイトル又は本文に含まれ得る。
- 利用規約では、通知がOSのロック画面、通知センター、連携端末、APNs/Expo Push等の外部通知サービスにより表示、保存又は転送される可能性、会員が通知プレビュー等を管理する責任、通知の到達・秘匿性を保証しないことを追記した。
- プライバシーポリシーでは、通知ID、タイトル、本文、リンク先、未読数/バッジ、配信結果、開封履歴、APNs device tokenを取得情報・外部送信・保持/削除へ追加した。
- 今回はコード変更禁止のため、通知本文のマスキング、ロック画面プレビュー制御、アプリ内許可前コピー、通知payloadの実機監査、公開Web反映、App Store Connect入力は未更新。初回提出でプッシュ通知を出す場合、通知本文が必要最小限で、正確な位置、住所、銀行口座、内部ID、不要な個人情報を含まないことを実機で確認する。

---

## 2026-06-29 追記：写真メタデータ残存リスクを公開前No-Goへ追加

- 現行コード上、写真ライブラリから選択したJPEG/PNG/GIF/WebPは、対応形式かつサイズ上限内であれば元データのまま `GoodsPhotoUpload` 又はチャット/証跡用アップロードへ渡される経路がある。カメラ撮影やサイズ超過時の再エンコード経路ではメタデータが落ちる可能性がある一方、元データ保存経路ではEXIF、撮影日時、GPS位置情報、端末情報等が残り得る。
- 利用規約では、外部共有・投稿時に画像メタデータ確認責任を明記し、投稿/画像にEXIF、GPS位置情報、撮影日時、端末情報などプライバシー又は安全を害する情報を含めない注意を追加した。
- プライバシーポリシーでは、取得情報に画像ファイル内メタデータを追加し、処理経路によって削除されず保存又は相手会員に表示される可能性があることを追記した。
- App Store公開前のNo-Goとして、写真アップロードが見える場合、EXIF/GPS/撮影日時/端末情報の残存経路、削除可否、ユーザー向け注意、App Privacy上のPhotos or Videos / Location / Device Info回答要否を確認する。
- 今回はコード変更禁止のため、メタデータ除去処理、画像再エンコード統一、アップロード前警告UI、実機メタデータ検査は未実装/未実行。完成ビルド提出前に、元データ保存経路と再エンコード経路の差分を実機で確認する。

---

## 2026-06-29 追記：外部画像URLとContent Rightsリスクを公開前No-Goへ追加

- 現行コード上、グッズ画像はSupabase Storageの公開URLに正規化される一方、ユーザーが保持又はコピーした絶対URLもグッズ画像URLとして保存・表示され得る。`GoodsRemoteImageDataLoader` はURLSessionで当該URLを読み込むため、外部画像ホストへIPアドレス、端末/アプリの通信情報、アクセス時刻等が送信される可能性がある。
- 画像URL、AI検索候補、外部情報参照で表示される画像や名称は、公式情報、権利者承認、権利処理済み素材又は正確な商品情報を保証しない。利用規約では、会員の権利確認責任、無許諾画像禁止、外部画像/リンク先の非保証を追記した。
- プライバシーポリシーでは、Storage path、公開URL、署名URL、外部画像URLを取得情報へ追加し、外部画像ホスト/CDNへの通信と保存/削除が当該外部サービスの規約・ポリシーに従うことを追記した。
- App Store公開前のNo-Goとして、Content Rights回答、スクショ、デモデータ、App Privacy、公開FAQ、アプリ内注意文が「公式画像や権利未確認素材を運営が提供していない」「AI候補画像は権利確認済みとは限らない」「外部画像URLの表示がある場合は外部ホスト通信がある」前提と一致していることを確認する。
- 今回はコード変更禁止のため、外部画像URLの制限、画像プロキシ、許可ドメイン制御、アプリ内同意UI、公開Web反映、App Store Connect入力は未更新。初回提出で外部画像URL表示又はAI画像候補を出す場合、実機通信ログと公開説明を照合する。

---

## 2026-06-29 追記：Apple標準EULA方針と広告通報を公開前No-Goへ追加

- 初回提出では、代表者情報の公開リスクと独自EULAの最低条項照合漏れを避けるため、App Store ConnectのLicense AgreementはApple標準EULAを推奨する。
- 独自EULAを選ぶ場合は、Apple Minimum Terms、Megrum利用規約、弁護士レビュー、公開URL、App Store Connect入力値を提出前に照合する。最低条項、第三者受益者、保守/サポート、製品請求、知的財産権侵害、法令遵守、連絡先表示が未確認ならNo-Goとする。
- AdMob等の広告を初回提出ビルドで表示する場合、不適切又は年齢に合わない広告をユーザーが報告できる導線、サポート説明、広告通報データの取扱い、広告配信事業者への報告手順、App Privacy回答を揃える。
- 今回はコード変更禁止のため、実際の広告通報UI、公開Web反映、App Store Connect入力、Privacy Manifest/SDK設定は未更新。公開前No-Goとして、広告露出有無、広告通報導線、App Privacy、公開FAQ、Review Notesを一致させる。

---

## 2026-06-29 追記：顔検出・顔候補付けデータをSensitive Info候補として反映

- 現行コード及び `ios-native/README.md` では、`VisionFaceDetectionService` がApple Visionの顔矩形検出を使い、Face ID又は生体認証APIは使わない設計である。
- 現行コード上、`member_face_profiles` は顔特徴量 `embedding`、モデル識別子、source image、同意記録を持ち、`face_uploaded_images` / `detected_faces` / `face_match_candidates` / `face_match_corrections` はユーザー画像、検出矩形、候補、補正履歴を保存する。
- 顔候補付けはグッズ登録補助であり、本人確認、年齢確認、Face ID認証、出入場管理、信用判断、真贋鑑定ではないことを、利用規約、プライバシーポリシー、公開サポート文面へ追記した。
- 実在人物の顔特徴量又は画像特徴量を生成・保存・照合する導線が初回提出ビルドで到達可能な場合、App PrivacyではSensitive Info / biometric data相当を回答候補へ上げる。単なるPhotos or Videosだけで済ませる判断はNo-Go寄りとして扱う。
- 今回はコード変更禁止のため、`ios-native/App/PrivacyInfo.xcprivacy`、`web/src/app/terms/page.tsx`、`web/src/app/privacy/page.tsx`、`ios-native/Sources/MegrumApp/LegalDocumentContent.swift` は未更新。公開前No-Goとして、顔候補付けの露出有無、外部送信有無、削除/同意/保持、App Privacy回答、公開Web本文、アプリ内法務表示を一致させる。
- 読み取り確認では、`web/src/app/terms/page.tsx` は現地交換中心の短縮Terms、`web/src/app/privacy/page.tsx` は外部AI説明ありだが顔候補付け・郵送交換・会員間支払い情報・AdMobの詳細反映前、`ios-native/Sources/MegrumApp/LegalDocumentContent.swift` はアプリ内の要約表示、`ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false` とUserDefaults Required Reasonのみで収集データ型未記載だった。今回のドラフトを公開・提出に使う前に、この4箇所とApp Store Connect回答を同時に同期する。

---

## 2026-06-29 追記：会員間支払い情報・銀行口座情報を現行コード前提として反映

- 現行コード及び `notes/05_data_model.md` では、`user_payment_settings` に支払い方法、銀行名、支店名、口座種別、口座番号、口座名義、その他メモを保存する。
- 現行コード上、金額指定を含む取引では、合意時に `proposals.sender_payment_settings` / `receiver_payment_settings` へ支払い情報スナップショットを保存し、成立後の当事者向け画面で銀行口座情報を含む支払い情報を表示する。
- Apple IAPのカード情報とは別に、アプリ側が銀行口座番号等を保存・表示するため、App PrivacyではFinancial Info / Payment Infoを条件付き回答候補へ上げる。支払い設定、銀行振込、口座番号入力、金額指定取引、合意後の支払い情報表示へ到達できるビルドでは、Payment Infoを選ばない回答はNo-Goとする。
- 会員間支払いについて、運営者が資金の受領、保管、送金、収納代行、決済代行、返金又はエスクローを行わないこと、ユーザー間で表示された支払い情報の目的外利用を禁止すること、金融/資金移動スキームとしての利用を禁止することを、利用規約、プライバシーポリシー、App Privacy台帳、委託先台帳へ反映した。
- 今回はコード変更禁止のため、`web/src/app/terms/page.tsx`、`web/src/app/privacy/page.tsx`、`ios-native/Sources/MegrumApp/LegalDocumentContent.swift` は未更新。公開前No-Goとして、Markdown/docx改訂案、公開Web本文、アプリ内法務表示、App Store ConnectのApp Privacy回答を一致させる。

---

## 2026-06-28 追記：郵送交換・住所開示を現行コード前提として再反映

- 現行コード及び `notes/05_data_model.md` / `notes/09_state_machines.md` では、Proposal が `exchange_method='hand'` / `mail` / `both` を持ち、郵送交換では `user_mailing_addresses` に宛名、郵便番号、住所、電話番号を保存する。
- 現行コード上、郵送交換又は `both` の打診では送信前に住所登録が必要で、合意後に `proposals.sender_mailing_address` / `receiver_mailing_address` のスナップショットが当事者へ表示される。
- 現行コード上、`PostalCodeAddressClient` が `https://zipcloud.ibsnet.co.jp/api/search` へ郵便番号を送信し、住所候補を取得する。
- 2026-05-31追記の「初回提出は現地交換MVP」「住所・電話番号はApp Privacyで選択しない」は、現行Swift Native実装とは矛盾するため、公開前判断としては本追記を優先する。郵送交換を初回提出から隠す場合は、住所設定、郵便番号検索、郵送先表示、`mail` / `both` 導線へ到達できないことを実機で確認する。
- 上記を踏まえ、利用規約とプライバシーポリシーへ、郵送交換、合意後の郵送先表示、郵送先情報の目的外利用禁止、配送事故・紛失・破損・誤配送の責任分界、ZipCloud外部送信、App Privacy上のPhysical Address / Phone Number回答方針を反映した。
- 今回はコード変更禁止のため、`web/src/app/terms/page.tsx`、`web/src/app/privacy/page.tsx`、`ios-native/Sources/MegrumApp/LegalDocumentContent.swift` は未更新。公開前No-Goとして、Markdown/docx改訂案、公開Web本文、アプリ内法務表示、App Store ConnectのApp Privacy回答を一致させる。

---

## 2026-06-29 追記：AdMob実設定・ATT・テスト広告を公開前No-Goへ追加

- 2026-06-29時点のコード確認では、`ios-native/Package.swift` は `GoogleMobileAds` 13.6.0以降に依存し、`MegrumNativeApp.init()` は `AdRuntimeConfiguration.current().shouldStartAdMobSDK` がtrueの場合に `MobileAds.shared.start()` を呼ぶ設計だった。
- 2026-06-29時点の `ios-native/Config/MegrumNative.xcconfig` は、チェックイン既定値として `MEGRUM_ADS_ENABLED=YES`、`MEGRUM_AD_PROVIDER=admob`、実AdMob app id、`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、Googleデモのbanner/native test unit id、`MEGRUM_ADMOB_SEARCH_NATIVE_UNIT_ID`、`MEGRUM_ADMOB_TRADES_BANNER_UNIT_ID` を持っていた。2026-07-03時点の現在値は上記「AdMobチェックイン既定を提出安全側へ変更」を正とする。
- `AdRuntimeConfiguration.unitID(for:)` は `usesGoogleTestAdUnits` がtrueで、formatがbanner又はnativeの場合、設定済みのproduction unit idではなくtest banner/native unit idへ差し替える。したがって2026-06-29時点の設定では、検索結果native広告、やりとり一覧上部banner、preview viewer向けhome banner fallbackはGoogleデモ広告ユニットへリクエストされ得た。
- `AdBannerSlot` と `AdMobNativeCardView` は `Request()` をそのまま使い、現行検索では `AppTrackingTransparency`、`ATTrackingManager.requestTrackingAuthorization`、`NSUserTrackingUsageDescription`、`UserMessagingPlatform` / UMP、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御、child-directed treatment、test device id指定は未確認。
- `AdInterstitialPresenterModifier` は現行コード上、placeholder表示以外でGoogle interstitial SDKロードへ接続していない。home/wish/meguri/searchのinterstitial request経路はあるが、production interstitial unit idも空であり、現時点の主な外部広告通信リスクはbanner/native表示面にある。
- `ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false`、`ios-native/App/Info.plist` には `NSUserTrackingUsageDescription` がない。IDFA又はApple定義のTrackingに該当する広告設定、パーソナライズ広告、Publisher First-Party ID、広告メディエーション、第三者広告目的の横断利用を有効にする場合、このまま提出することはNo-Goとする。
- 公開前No-Goとして、(1) `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` 又はGoogleデモ広告unit idのまま一般公開しない、(2) AdMobが初期化又は広告リクエストを行うビルドではGoogle公式データ開示、SDK Privacy Manifest、App Privacy回答、ATT/IDFA/Tracking回答、SKAdNetworkItems、広告通報導線を一致させる、(3) UMP等の同意管理が必要な地域又は広告設定では、同意管理未実装のまま広告を有効化しない。

参照:
- Google Mobile Ads SDK data disclosure: https://developers.google.com/admob/ios/privacy/data-disclosure
- Google Mobile Ads iOS privacy strategies: https://developers.google.com/admob/ios/privacy/strategies
- Apple App Tracking Transparency: https://developer.apple.com/documentation/apptrackingtransparency
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/

---

## 2026-06-28 追記：AdMob / StoreKit / 外部AI送信を公開前ドラフトへ反映

- 現行コード上、Swift Native iOSは `ios-native/Package.swift` で `GoogleMobileAds` に依存し、`ios-native/App/Info.plist` に AdMob app id / ad unit id / SKAdNetworkItems が入っている。
- メグルムプラス購入経路は `StoreKitMegrumPlusPurchaseClient` が `Product.products`、`Product.purchase()`、`Transaction.currentEntitlements`、`AppStore.sync()` を使い、購入後は `sync_megrum_plus_purchase_for_viewer` 系の境界へ同期する。ただし2026-07-03時点のチェックイン既定では `MEGRUM_PLUS_IAP_ENABLED=NO` により購入/復元/商品照会を停止する。購入導線を有効化した場合、購入直後のサーバー同期失敗時にはローカルで有効表示へ倒すフォールバックがあるため、公開文面ではローカル表示を永続的な権限付与として扱わない。
- `sync_megrum_plus_purchase_for_viewer` は `megrum.plus.monthly`、transaction id、original transaction id、expiration dateを保存して `user_entitlements` を更新するが、migrationコメント上、App Store Server APIによるサーバー検証は本番前追加。App Store Server Notificationsによる更新、返金、取消、期限切れ、請求失敗、猶予期間同期も現行検索では未確認。
- IAPを有効化した場合、`SubscriptionSettingsContent` はStoreKitの商品価格をボタンへ表示する一方、フッターに「価格は月額500円です」と固定表示する。App Store Connect価格、アプリ内固定文言、特商法、FAQ、Review Notesが一致しない状態で有料導線を出すことはNo-Goとする。
- 現行コード上、`suggest-goods-series` Edge Function はログイン済みJWTを検証したうえで OpenAI Responses API へ最大3件の画像、画像URL、グループ名、メンバー名、グッズ種別、既存候補名を送る。Function側では `web_search` を必須実行する。
- 現行コード上、マイグッズ作成後のX共有導線はOS共有画面へ投稿文と画像を渡す形で、アプリが外部SNSへ自動投稿するものではない。
- 上記を踏まえ、`notes/legal/01_terms_of_service_draft.md` と `notes/legal/02_privacy_policy_draft.md` を、メグルムプラス、StoreKit自動更新/復元、権限反映遅延、一時表示、返金/取消/期限切れ/請求失敗時の権限停止、AdMob/SKAdNetwork/ATT、外部AI送信、外部SNS共有後の責任分界、ステマ表示、第三者権利侵害、消費者契約法上の免責制限に合わせて更新した。
- App Store公開前のNo-Goとして、`PrivacyInfo.xcprivacy` の `NSPrivacyTracking=false`、AdMob実設定、ATT/IDFA/Publisher First-Party IDの利用有無、Google Mobile Ads SDKのデータ収集、App Privacy回答、公開Webページ本文、特商法表記が相互に矛盾していないことを再確認する。
- 同じ前提を、App Privacyインベントリ、App Store Connect回答シート、Privacy Manifest/SDK監査台帳、外部サービス・委託先台帳、公開法務・サポートページ文面、IAP商品設定ワークシートにも反映した。
- 特に、Google Mobile Ads SDKは組み込み済みなので、「広告を初回で出さない」前提の古い提出メモや台帳は、実ビルドの設定値と照合して更新する必要がある。

---

## 2026-06-29 追記：通報・ブロック・UGC安全導線の実装差分を整理

- 参照した外部情報は、Apple App Review Guidelines 1.2 User-Generated Content（不適切コンテンツのフィルタ、通報、対応、ブロック、連絡先）と、e-Gov法令検索の特定電気通信による情報の流通によって発生する権利侵害等への対処に関する法律（送信防止措置、発信者情報開示等）を前提とした。
- 現行コード上、`reports`、`goods_reports`、`groom_reports`、`meguri_board_reports` が存在し、ユーザー/取引/メッセージ、グッズ、グルーム、掲示板の通報を別テーブルで受ける設計になっている。各通報は本人insert/selectを基本とし、管理画面はservice roleと `reports.read` / `reports.moderate` 権限で横断確認、status更新、監査ログ記録を行う。
- 現行Swift Nativeでは、プロフィール通報、グッズ通報、グルーム通報、ユーザーブロック、ブロック一覧/解除、検索/ホーム/プロフィール等のブロック相手除外が実装されている。
- 掲示板はDB側に `report_meguri_board_thread` / `report_meguri_board_reply` RPCがあるが、現行検索ではSwift Native画面からこれらを呼ぶ通報導線は未確認。掲示板を初回提出で露出する場合は、スレッド/返信の画面内通報導線を実機確認するか、少なくともsupport@フォールバックをFAQ/Review Notes/サポートページへ明記する。
- 上記を踏まえ、利用規約、FAQ、Trust & Safety SOP、App Review Guideline表、Go/No-Go、提出証跡チェックを、画面内通報ボタンを全対象で保証しない表現へ調整した。

---

## 2026-06-27 追記：現行課金名称をメグルムプラスへ変更

- iter1223で、Swift Native iOSの現行サブスク表示名を **メグルムプラス**、価格を **月額500円** とする方針に変更した。
- メグルムプラスの対象機能は、個別募集の作成数無制限、ホーム/検索でのグッズ優先表示、グルームアーカイブ無制限の3点。無料プランは個別募集3件まで、グルームアーカイブ最新10件まで。
- 旧Premium/めぐりPlusは履歴・互換キーとして残すが、公開導線と課金訴求はメグルムプラスを正とする。
- `web/src/app/terms/page.tsx` と Swift Native内の法務表示は、旧 `Premium会員、めぐりPlus` 表記を `メグルムプラス` へ最小変更した。
- 特商法・有料サービス条項は、公開前レビュー時に「メグルムプラス 月額500円」「App Store課金」「自動更新サブスクリプション」の表記へ更新確認する。

## 2026-05-31 追記：初回提出スコープを現地交換MVPへ再固定

> 履歴メモ。2026-06-28時点の現行Swift Nativeでは郵送交換・住所開示経路が復活しているため、公開前判断では本ファイル上部の2026-06-28追記を優先する。

- AGENTS.md と `notes/10_glossary.md` の現行用語ルールに合わせ、初回提出の法務・App Store準備文書は現地交換MVPを前提に統一した。
- 2026-05-29の一時検討で入った現地外の交換手段、住所登録、住所表示に関する記述は、初回提出用の新ドラフトから外した。
- App Store ConnectのApp Privacy回答では、初回MVPで住所・電話番号を収集しない前提とし、Physical Address / Phone Numberは選択しない方針へ戻した。
- 弁護士レビュー依頼メモでは、現地交換の安全導線、現在地共有、服装写真、アカウント削除、UGC、AI、IAP、代表者情報非公表運用を重点論点とする。
- 2026-05-29追記は履歴として残すが、初回提出の正は本追記と `notes/legal/*` / `notes/24`〜`notes/44` の現地交換スコープ版とする。

---

## 2026-05-31 追記：現行仕様ベースの公開前ドラフトを追加

- 現行仕様（Swift Native iOS主線、現地交換、めぐり、グルーム、スポット掲示板、メグルムプラス/ブースト、APNs通知等）を前提に、次の公開前ドラフトを作成した。
  - `notes/legal/01_terms_of_service_draft.md`
  - `notes/legal/02_privacy_policy_draft.md`
- 既存の弁護士納品 docx は引き続き法務原典として保持する。ただし、App Store初回提出では現地交換MVPへ再固定したため、公開前には新ドラフトをベースに法務レビューへ回す。
- 新ドラフトでは、旧提案/旧メッセージ/旧募集/旧投稿機能の用語を使わず、現行 Megrum 用語の「打診」「取引チャット」「在庫情報」「めぐり」等へ統一した。
- 初回提出用ドラフトでは、住所登録や住所表示を前提にしない。身分証明書による本人確認を行わない前提は、現地交換の安全導線と利用者注意喚起の論点として管理する。
- 現在地共有・服装写真は任意共有、取引相手限定表示、取引終了後30日を目安に削除又は非表示化する運用目標として文面化した。ただし、2026-06-29時点の現行コードでは `messages` が追記型で、現在地共有・服装写真の30日後自動削除又は非表示ジョブは未確認。`chat-photos` は365日signed URLで表示する経路があるため、公開文面では即時削除、完全削除、自動削除完了を保証しない。
- AI機能について、利用規約ではAI出力の非保証・ユーザー確認責任・禁止利用・外部AI利用時の明示/同意を追記し、プライバシーポリシーではAI機能で取得する情報、利用目的、外部AIサービスへの送信、汎用モデル学習利用の有無を明記した。
- 代表者情報は、原典方針通り非公表（請求があれば回答）とし、問い合わせ先は `support@megrum.jp` に統一した。

---

## 2026-05-29 追記：現地外交換手段を一時検討した判断（履歴・失効）

- 一時的に、現地交換に加えて現地外の交換手段を初回リリース候補へ戻す判断が入った。
- ただし、2026-05-31追記の通り、この判断は初回提出の正ではない。
- 当時の検討論点は、住所を当事者間へ開示する条項、本人確認を入れない運用での注意書き、受領トラブル時の責任分界、通報・アカウント制限・補償しない範囲の明記だった。
- 初回提出では、現地交換MVPへ再固定し、住所登録や住所表示を前提にしない。

---

## 2026-05-15 追記：サービス表示名の変更

- プロダクトのユーザー向け表示名を **Megrum** から **Megrum** に変更した。
- 公開ドメイン・問い合わせメールは **`megrum.jp` 系**へ移行する。
- 既存の弁護士納品 docx の原典ファイル名や Apple bundle identifier は、配信・署名・法務原典への影響があるため当面 `Megrum` / `megrum` 系を残す。
- 法務原典を正式に改訂するタイミングでは、サービス名・連絡先・課金名称を Megrum 前提で再確認する。

---

## 🎯 重要な方針（iter47 確定）

### 弁護士判断

ユーザーが規約原典 docx を弁護士に再確認したところ：
> **「このまま OK」**

つまり：
- ✅ **規約原典 docx は改訂しない**（弁護士費 $500 不要）
- ✅ **MVP は規約の SUBSET として実装**（docx は旧投稿機能・現地外交換手段を含むが、MVPで実装しない＝法的に問題なし）
- ✅ **将来旧投稿機能・現地外交換手段を追加する際も追加レビュー不要**（docx で既にカバー済）

### この意味

```
規約原典 docx（弁護士承認済）
  ├ 旧投稿機能の規定          ← MVPで実装しない（実装は将来でも可）
  ├ 現地外交換手段の規定      ← MVPで実装しない（実装は将来でも可）
  └ その他全条項              ← MVPで実装

⇒ 「契約上は許される、実装はサブセット」という法的に正常な状態
```

これは **完全に問題ない**。契約が SUPERSET、実装が SUBSET の関係は標準的。
将来、旧投稿機能や現地外交換手段を追加する場合、規約改訂なしで実装可能。

---

## このドキュメントの位置付け

- 弁護士納品の docx 原典（`利用規約など/` ディレクトリ）を**正本**とする
- 現状の Megrum 設計（2026-05-01時点、iter45 まで）との齟齬を文書化
- 規約改訂が必要な箇所を弁護士に渡せる形で整理
- 実装側で修正すべき箇所を明示

## 規約原典の所在

```
利用規約など/                                    （.gitignore 対象、git管理外）
├── 01_Megrum利用規約.docx                       （作業中ドラフト）
├── 01_Megrum利用規約【納品】.docx                  （納品版・原典）
├── 02_Megrumプライバシーポリシー【納品】.docx       （納品版・原典）
└── 03_特定商取引法に基づく表記【納品】.docx       （納品版・原典）
```

## 目次

1. [規約原典の概要](#1-規約原典の概要)
2. [現状 Megrum 設計との齟齬一覧](#2-現状-megrum-設計との齟齬一覧)
3. [削除事項](#3-削除事項)
4. [追加事項](#4-追加事項)
5. [用語統一](#5-用語統一)
6. [価格確定事項](#6-価格確定事項)
7. [代表者情報の方針](#7-代表者情報の方針)
8. [弁護士再依頼の概算費用](#8-弁護士再依頼の概算費用)
9. [変更後の規約構成案](#9-変更後の規約構成案)

---

## 1. 規約原典の概要

### 利用規約（全40条）

主要構造：
- 第1章 基本事項（§1〜10）：定義、会員登録、本人確認、ログイン、広告、無料/有料会員、退会、~~ダイレクトメッセージ~~
- 第2章 物々交換（§11〜21）：~~募集登録~~、登録グッズ制限、実施手順、撤回・キャンセル、評価、終了、遵守事項、古物営業禁止、チケット転売禁止、盗品関与禁止
- 第3章 ~~MyLog~~（§22〜24）：~~MyLog投稿、投稿コンテンツとコメント、運営者の権限~~ ← **iter46 で削除**
- 第4章 一般条項（§25〜40）：禁止行為、アカウント制限、長期未利用、中断、個人情報、譲渡、保存、非保証、免責、反社、損害賠償、改訂、連絡、譲渡、その他、準拠法

### プライバシーポリシー

- 利用目的（取得情報・利用目的）
- 第三者提供（~~郵送時の住所情報提供~~ ← iter46 で削除）
- 安全管理措置（組織的・人的・物理的・技術的）
- AdMob、Firebase、Cookie、Google Analytics、Google Adsense
- 開示請求・訂正・利用停止対応

### 特商法表記

- サービス名 Megrum
- 代表者名・住所・電話番号：**非公表**（請求があれば回答）
- サービス料金：有料会員 ●●●円、ブースト ●●●円
- 支払時期、方法、利用環境、サービス時期、キャンセル
- 取引にあたっての注意事項：「Megrum利用規約」を参照

---

## 2. 現状 Megrum 設計との齟齬一覧

### サマリ

| カテゴリ | 件数 |
|---|---|
| 削除（規約から消す） | 4 |
| 追加（規約に書く） | 5 |
| 用語統一 | 3 |
| 価格確定 | 2 |
| 代表者情報 | 1 |

### 詳細

| # | 項目 | 規約原典 | 現状 Megrum | 対応 |
|---|---|---|---|---|
| 1 | MyLog 機能 | 第3章（§22-24）にあり | **なし** | **規約から削除** |
| 2 | 郵送による交換 | §3、§11、§13、§17 等 | MVP は現地のみ | **規約から削除** |
| 3 | 本人確認（身分証） | 郵送時必須（§3） | 不要（MVP） | **規約から削除** |
| 4 | 発送伝票（保管義務） | §17（取引終了まで） | 不要 | **規約から削除** |
| 5 | 待ち合わせの合意前 fix（iter33） | 規定なし | C-0 で日時・場所fix | **規約に追加** |
| 6 | 服装写真の任意共有（iter34） | 規定なし | C-2 で任意 | **規約に追加** |
| 7 | 現在地共有（iter34） | 規定なし | C-2 で任意 | **規約に追加** |
| 8 | Dispute 詳細フロー（iter12-18） | §16「強制終了」に簡素な記載のみ | D-1〜D-6d の詳細 | **規約 §16 拡張** |
| 9 | 通報機能 | §26 でアカウント停止条件にあり | RPT-form 画面あり | **規約 §26 微修正** |
| 10 | 「ダイレクトメッセージ」用語 | 各所にあり | 「取引チャット」 | **規約全体で置換** |
| 11 | 「交換依頼」用語 | 各所にあり | 「打診」 | **規約全体で置換** |
| 12 | 「交換募集」「募集登録」用語 | 各所にあり | 在庫登録に吸収・概念消滅 | **規約全体で削除 or 置換** |
| 13 | メグルムプラス月額利用料 | ●●●円（未確定） | ¥500/月 | **特商法に確定値** |
| 13.5 | 旧めぐりPlus月額利用料 | 規定なし | ¥1,000/月（iter1223以降は互換・履歴） | **新規訴求はメグルムプラスへ統一** |
| 14 | ブースト価格 | ●●●円（未確定） | 単発¥150 / 5個¥600 / 10個¥1,000 | **特商法に確定値** |
| 15 | 代表者情報 | 非公表方針 | 私が一時 `legal-pages.jsx` に「松尾満天」と記載（iter45） | **原典通り非公表に戻す** |

---

## 3. 削除事項

### 3-1. MyLog 機能関連（規約 第3章 全削除）

削除対象：
- §22（MyLog投稿）
- §23（投稿コンテンツとコメント）
- §24（運営者の権限）

その他、「MyLog」が登場する箇所：
- 第1条 用語定義の「MyLog」「MyLog投稿」「投稿コンテンツ」
- §7-2、§8-1（無料/有料会員のMyLog投稿上限数）
- §22以降全般

→ **第3章全削除＋関連用語の削除＋章立て繰り上げ**

### 3-2. 郵送機能関連（複数箇所削除）

削除対象：
- 第1条「希望交換条件」の「交換方法（対面、郵送、その他）」「郵送の場合の発送目途、送料負担、梱包方法」
- §3 本人確認申請（全削除）
- §13-6（郵送と本人確認、住所通知の規定）
- §17-1-3（発送伝票保管義務）
- §17-2-1（希望交換条件で郵送と対面の差異規定）
- プライバシーポリシー：「希望交換条件が郵送の場合の身分証明書」関連

→ **MVP は現地交換のみ。Post-MVP で復活時に再改訂。**

---

## 4. 追加事項

### 4-1. 待ち合わせの合意前 fix（iter33）

規約に追加（推奨：第13条 物々交換の実施手順 の中に追加）：

> 第13条 第3項追加：
> 会員は、ダイレクトメッセージによる調整に加え、本アプリ所定の方法で、交換取引の日時及び場所を双方の合意により事前に確定するものとする。日時は登録済の活動予定（AW）から選択するか、又は新規にカスタム日時を指定する方法のいずれかによる。

### 4-2. 服装写真・現在地共有（iter34）

規約に追加（推奨：第13条 または新規 第14条として）：

> 新条項：合流支援
> 1. 会員は、合流当日において、自らの服装画像を相手会員に対し任意で共有することができる。
> 2. 会員は、合流当日において、自らの位置情報を相手会員に対し任意で共有することができる。
> 3. 前各項により共有された画像・位置情報は、当該交換取引の合流目的のみに使用するものとし、目的外利用又は第三者開示を禁ずる。
> 4. 共有されたデータは、取引終了から30日経過後に運営者が自動削除する。

現行公開前ドラフトでは、上記4の「自動削除」は採用しない。現行コード上、現在地共有と服装写真は `messages` / `chat-photos` に保存され、30日後の自動削除又は非表示ジョブは未確認であるため、プライバシーポリシーでは「30日を目安に削除又は非表示化する運用を目標」「反映に時間を要する場合あり」としている。

### 4-3. Dispute 詳細フロー（iter12-18）

既存 §16（交換取引の終了）と §26（アカウント抹消）を拡張：

新条項案：
- カテゴリ5種（ドタキャン・遅刻・不一致・破損・その他）
- 反論機会期間（24h）
- 仲裁SLA（同日4h／その他24h）
- 5値 decision（sender_fault / receiver_fault / mutual_fault / no_fault / cant_determine）
- 4段階 penalty（none / warning / temp_suspend / permanent_suspend）
- 申告中の凍結（両者の新規打診不可）
- 受付番号
- 再審査申立て（1取引1回・期限7日）

### 4-4. 通報機能（§26 微修正）

通報フォームから運営にエスカレーション可能。プロフ・取引・メッセージから通報可能。

### 4-5. 公式コラボ・スポンサー対応（Phase δ 以降）

Post-MVP の公式コラボ機能で必要になる規定（規約改訂タイミングで合わせて追加）：
- 運営者によるユーザー作成イベントシリーズの修正・削除権
- スポンサー情報の表示

---

## 5. 用語統一

### 5-1. ダイレクトメッセージ → 取引チャット

該当条項：
- 第1条 用語定義
- §10（ダイレクトメッセージ）→ 「取引チャット」に章タイトル変更
- §13-3（ダイレクトメッセージにより、必要な調整を行う）
- §17-3-2、3、4、5（ダイレクトメッセージ関連の禁止行為）
- §25-1（ダイレクトメッセージ以外での連絡を試みる行為）

→ 全置換：「ダイレクトメッセージ」→「取引チャット」

### 5-2. 交換依頼 → 打診

該当条項：
- 第1条 用語定義
- §13（交換依頼）
- §14（交換依頼の撤回）
- §17、§25 等

→ 全置換：「交換依頼」→「打診」

### 5-3. 交換募集 → 概念消滅・削除 or 在庫公開に置換

該当条項：
- 第1条 用語定義（「交換募集」「募集情報」「募集登録」）
- §11（募集登録）
- §13-1（他の会員が登録した募集情報）
- §17-2-2、3（希望交換条件）

→ 章立て・用語の見直し。「在庫登録（公開）」に置換 or 削除。

---

## 6. 価格確定事項

特商法に記載されている **●●●円** を確定：

| 項目 | 確定価格 |
|---|---|
| 有料会員月額利用料 | **¥500（税込）** |
| 有料会員年額利用料 | **¥4,800（税込）** |
| メグルムプラス月額利用料 | **¥500（税込）** |
| 旧めぐりPlus月額利用料 | **¥1,000（税込・互換/履歴）** |
| ブースト 単発 | **¥150（税込）** |
| ブースト 5個セット | **¥600（税込）** |
| ブースト 10個セット | **¥1,000（税込）** |

---

## 7. 代表者情報の方針

### 規約原典の方針（**正本**）

> 代表者のプライバシーに関わる事項のため、公表しておりません。
> 理由を明示のうえ問い合わせをいただきましたら、遅滞なく回答いたします。

→ **この方針を維持**。`Megrum/legal-pages.jsx` の iter45 で「松尾満天」と表示した変更は **iter46 で原典通りに戻す**。

### 公開する情報

| 項目 | 公開内容 |
|---|---|
| サービス名 | Megrum |
| 代表者氏名 | 非公表（請求があれば回答） |
| 所在地 | 非公表（同上） |
| 電話番号 | 非公表（同上） |
| メールアドレス | **`support@megrum.jp`**（メイン、個人情報保護関係も含む）／**`info@megrum.jp`**（通知用） |
| 受付時間 | 平日 10:00〜18:00（土日祝・年末年始を除く） |

---

## 8. 弁護士再依頼の概算費用

### 改訂規模

- 削除：約 30箇所（MyLog全章・郵送関連）
- 追加：約 5新条項（待ち合わせ・服装写真・現在地・dispute詳細・通報）
- 用語置換：約 50箇所（DM→取引チャット、交換依頼→打診、交換募集→在庫登録）
- 価格確定：特商法 2箇所
- 章立て見直し：第3章削除に伴う繰り上げ

### 概算費用

- **小規模改訂レベル**：$500〜$800（USDで $500、JPYで ¥75K〜¥120K）
- **依頼元の弁護士に再依頼**が前提（既存案件の継続なので安め）
- 新規弁護士に依頼するなら $1,000〜 を想定

ユーザーの予算 **「規約・プライバシーポリシーの確認だけ $500前後」** に概ね収まる見込み。

### 提出資料

このドキュメント（17_legal_alignment.md）+ 既存docx を弁護士に共有：
- 「ここを削除、ここを追加、用語をこう置換、価格はこう」と具体指示
- 弁護士の修正版を受領後、改訂版docx を `利用規約など/` に保管

---

## 9. 変更後の規約構成案

### 新章立て

```
第1章 基本事項（§1〜9）
  §1 本規約 ← 用語定義から MyLog・郵送関連削除、用語置換
  §2 会員登録
  ~~§3 本人確認申請~~ ← 削除（郵送関連）
  §3 ログイン情報管理（旧§4 を繰り上げ）
  §4 会員情報の変更（旧§5）
  §5 広告の配信（旧§6）
  §6 無料会員（旧§7）
  §7 有料会員、会員によるブーストの購入（旧§8）
  §8 退会等（旧§9）
  §9 取引チャット ← 旧§10「ダイレクトメッセージ」を改題

第2章 物々交換（§10〜21）
  §10 在庫登録 ← 旧§11「募集登録」を改題、概念再定義
  §11 登録アイテムの制限（旧§12）
  §12 物々交換の実施手順 ← 旧§13、待ち合わせ事前fix を追加、郵送削除
  §13 合流支援 ← 新規（服装写真・現在地共有）
  §14 打診の撤回、交換取引のキャンセル（旧§14、用語置換）
  §15 評価（旧§15）
  §16 交換取引の終了（旧§16）
  §17 異議申し立て ← 新規（dispute フロー詳細）
  §18 取引の遵守事項、禁止事項（旧§17、用語置換）
  §19 古物営業の禁止（旧§18）
  §20 チケット不正転売等の禁止（旧§19）
  §21 盗品関与の禁止（旧§20）

~~第3章 MyLog（§22〜24）~~ ← 全削除

第3章 一般条項（§22〜37）← 章番号繰り上げ
  §22 禁止行為（旧§25）
  §23 アカウントの制限、停止、凍結、抹消（旧§26）
  §24 長期未利用者への対応（旧§27）
  §25 通報（新規）
  §26 本アプリの中断、停止等（旧§28）
  §27 個人情報の取扱い（旧§29）
  §28 権利義務の譲渡（旧§30）
  §29 情報の保存（旧§31）
  §30 非保証等（旧§32）
  §31 免責（旧§33）
  §32 反社会的勢力排除（旧§34）
  §33 損害賠償（旧§35）
  §34 本規約の改訂（旧§36）
  §35 連絡及び通知（旧§37）
  §36 本アプリの譲渡（旧§38）
  §37 その他（旧§39）
  §38 準拠法及び管轄合意（旧§40）

合計：38条（旧40条 - MyLog 3条 + 通報 1条）
```

---

## ⚠️ 重要な認識：`legal-pages.jsx` は UI モックアップ

`Megrum/legal-pages.jsx` は **画面のレイアウト確認用モックアップ**であり、規約原典 docx の本文を忠実には再現していない。

| 項目 | 規約原典 docx（**正本**） | legal-pages.jsx（モックアップ） |
|---|---|---|
| 主体表現 | 「運営者」 | 「運営者」（iter47 で統一） |
| サービス | 「本アプリ」 | 「本サービス」（要修正） |
| 条文番号・章立て | 全40条 | 簡略化された第1〜13条程度（要修正） |
| MyLog 第3章 | あり | なし（モックアップは MVP の見た目を反映） |
| 郵送関連条項 | あり（§3、§13、§17 等） | なし（同上） |

### 運用方針（iter47 確定）

1. **規約原典 docx を法的正本**とする（弁護士承認済、改訂不要）
2. **legal-pages.jsx は MVP UI 確認用のモックアップ**として割り切る
3. **Phase 0+ 実装時の必須要件**：
   - **legal-pages.jsx を docx の内容で完全置き換える**
   - 利用規約全40条、プライバシーポリシー全章、特商法の正式表記をそのまま反映
   - 実装時は `<Markdown>` で docx をレンダリング or 全条文をハードコード
   - **MyLog・郵送関連も docx 通り表示**（MVPで機能未実装でも、規約上は将来実装可能性として記載）
   - 主体表現を「運営者」、サービス名を「本アプリ」に統一

### 実装フェーズの TODO

```
[ ] Phase 0 で legal-pages.jsx を docx の本文で完全リプレース
    - 利用規約：572 行 → そのまま反映
    - プライバシーポリシー：218 行 → そのまま反映
    - 特商法：70 行 → そのまま反映 + 価格 ¥500 等を確定値で埋める
[ ] 価格部分（特商法の ●●● 円）：MVP リリース前に確定値で埋める
    - 有料会員月額：¥500
    - 有料会員年額：¥4,800
    - メグルムプラス月額：¥500
    - ブースト単発：¥150
    - ブースト 5個：¥600
    - ブースト 10個：¥1,000
[ ] 特商法ページの「メールアドレス」を `support@megrum.jp` に
[ ] 特商法ページの「代表者名・所在地・電話番号」は **非公表**（規約原典通り）
[ ] プライバシーポリシーの「個人情報保護管理者の連絡先」も `support@megrum.jp` に統一（privacy@ は使わない）
```

---

## 関連 docs

- [`notes/10_glossary.md`](10_glossary.md) §M 規約原典マッピング
- [`notes/15_non_functional.md`](15_non_functional.md) §11-2 特商法
- [`notes/16_monetization.md`](16_monetization.md) §1 運営者情報、§5 広告、§6 ブースト、§7 Premium
- [`Megrum/legal-pages.jsx`](../Megrum/legal-pages.jsx) — 現在の UI モックアップ（本文は docx が正本）
- `利用規約など/`（.gitignore 対象、規約原典）

---

## 更新ログ

- v1.0 (2026-05-01, iter46): 初版。規約原典との齟齬を整理、弁護士再依頼用の改訂方針を策定。
