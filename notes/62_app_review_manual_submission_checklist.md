# 62. App Review手動提出チェックリスト

最終更新: 2026-06-29

ステータス: Draft v1.6（提出直前・手動操作用、近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / UGC・App Review 1.2 / Keychain・session保存・refresh token / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 古物営業・チケット不正転売 / 精密位置・MapKit・CoreLocation・逆ジオコーディング / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / 郵送先・会員間支払い照合を追加）

## 目的

App Store ConnectでMegrumの完成ビルドを審査提出する直前に、提出者が画面を見ながら最終確認できるチェックリスト。

この文書は提出操作の照合表であり、コード、App Store Connect設定、Apple Developer設定、DNS、公開URLは変更しない。

## 1. 使うタイミング

使うタイミング:
- 完成候補ビルドがApp Store Connectで処理完了している。
- TestFlight内部確認が終わっている。
- `notes/42_p0_smoke_test_script.md` のP0確認結果が記録されている。
- `notes/36_submission_evidence_checklist.md` に提出証跡を残す準備ができている。
- `notes/64_release_evidence_folder_index.md` に従って証跡保存先とmanifest方針が決まっている。
- `notes/70_app_store_product_page_asset_qa.md` でApp icon、スクショ、App Preview、poster frame、Product Page Previewを確認している。
- `notes/71_app_store_connect_final_input_reconciliation.md` でApp Store Connectの実入力値と提出docs/buildを照合している。
- `notes/75_apple_developer_signing_capabilities_preflight.md` でBundle ID、App ID、Capabilities、署名、profile/certificateを照合している。
- 公開URL、App Privacy、Review Notes、デモアカウント、スクショが提出候補になっている。

使わないタイミング:
- ビルドが未アップロード。
- デモアカウントでログインできない。
- プライバシーポリシーURL又はサポートURLが未公開。
- 初回提出で出す/隠す機能が未確定。
- App Store Connectの提出権限が未確認。

## 2. 公式前提の要点

Apple公式ヘルプ上、App Store審査提出では、アプリバージョンに必要なメタデータを入力し、正しいビルドを選択したうえでAdd for Review、Draft Submission、Submit for Reviewの流れに進む。

提出に必要な権限は、Account Holder、Admin、又はApp Manager相当の確認が必要。App Privacyの入力・更新はApp Store Connect上で公開前に実装実態と一致させる。

この文書では、Apple公式の画面名を参照しつつ、Megrumで確認すべき項目へ分解する。

## 3. 提出者・環境

| 項目 | 値 |
|---|---|
| 提出予定日 | TODO |
| 提出者 | TODO |
| Apple Developer Team | TODO |
| App Store Connect権限 | Account Holder / Admin / App Manager / Other |
| 2FA確認 | Pass / Fail |
| 対象App Record | Megrum |
| 対象Bundle ID | TODO |
| Version | TODO |
| Build Number | TODO |
| 確認端末 | TODO |
| 証跡保存先 | TODO |

No-Go:
- 提出者が提出権限を持たない。
- 2FAを完了できない。
- 対象App Record又はBundle IDが不明。
- 完成候補ではないBuild Numberを選びそうな状態。

## 4. 提出前フリーズ確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| FR-001 | 開発セッションから、提出候補のVersion/Build Numberが共有されている | TODO | TODO |
| FR-002 | 提出候補ビルド以降にP0コード修正が入っていない | TODO | TODO |
| FR-003 | 初回提出スコープ露出監査がPass又は提出判断済み | TODO | `notes/59` |
| FR-004 | Go / No-Go判定がGo又はConditional Go | TODO | `notes/50` |
| FR-005 | 公開URLが200応答、ログイン不要、HTTPS | TODO | `notes/37` |
| FR-006 | サポートメール又は問い合わせ導線が受信確認済み | TODO | `notes/47` |
| FR-007 | 権限・運用アカウント台帳のP0が埋まっている | TODO | `notes/61` |
| FR-008 | App Store Connect最終入力差分QAがPass又は提出判断済み | TODO | `notes/71` |
| FR-009 | Apple Developer署名・Capabilities事前確認がPass又は提出判断済み | TODO | `notes/75` |

No-Go:
- 提出候補ビルドとテスト済みビルドが違う。
- P0修正が入ったのに新ビルドで再確認していない。
- 公開URLが404又はログイン必須。

## 5. App Information確認

App Store Connect > Apps > Megrum > App Informationで確認する。

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| AI-001 | Name | Megrum | TODO |
| AI-002 | Bundle ID | 提出対象と一致 | TODO |
| AI-003 | SKU | 内部管理値として妥当 | TODO |
| AI-004 | Primary Language | Japanese想定 | TODO |
| AI-005 | Category | ライフスタイル又はソーシャルネットワーキングの最終判断と一致 | TODO |
| AI-006 | Privacy Policy URL | `https://megrum.jp/legal/privacy` 又は採用URL | TODO |
| AI-007 | Support URL | `https://megrum.jp/support` 又は採用URL | TODO |
| AI-008 | Content Rights | 第三者素材、外部画像URL、AI/検索候補画像の扱いと一致 | TODO |
| AI-009 | Age Rating | `notes/46` と一致 | TODO |
| AI-010 | License Agreement | 初回はApple標準EULA推奨。独自EULAならApple Minimum Termsと弁護士レビュー済み | TODO |
| AI-011 | Availability / DSA | 初回Japan-only方針、EU DSA trader status、商品ページ表示連絡先、IAP Availabilityが `notes/68` と一致 | TODO |

No-Go:
- NameやSubtitleが完成ビルド、スクショ、公開URLと食い違う。
- Privacy Policy URLが未入力又は非公開。
- Categoryが`Info.plist`やメタデータ方針と説明不能にズレている。
- Content Rightsで、外部画像URL又はAI/検索候補画像を公式素材、権利確認済み素材又は運営提供素材のように扱っている。
- Age Ratingで、生年月日/年齢表示、UGC、チャット、Age Assuranceなし、Parental Controlsなしの実態と矛盾している。
- 独自EULAを選ぶのに、最低条項、利用規約、公開URL、法務レビューの照合がない。
- 初回Japan-only方針なのに、EU又はAll Countries or Regionsを含むApp Availability、未確認のDSA trader status、又は広すぎるIAP Availabilityで提出する。
- App Information、説明文、スクショ又はReview Notesで、売買マーケット、古物商、オークション、買取、販売代理、チケット譲渡、入場資格保証、決済代行、資金移動、収納代行、回収代行、返金窓口、チャージバック窓口又はエスクローに見える。

## 6. Version Metadata確認

App Store Connect > 対象Versionで確認する。

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| VM-001 | Version string | 開発側が指定したVersion | TODO |
| VM-002 | Promotional Text | 初回提出スコープだけを説明 | TODO |
| VM-003 | Description | `notes/40` の最終候補と一致 | TODO |
| VM-004 | Keywords | 100 bytes以内、権利侵害に見えない | TODO |
| VM-005 | Subtitle | 30文字以内、過剰保証なし | TODO |
| VM-006 | Marketing URL | 空欄又は公開URL | TODO |
| VM-007 | Copyright | オーナー確認済み表記 | TODO |
| VM-008 | Contact URL等 | 必要欄が公開URLと一致 | TODO |

No-Go:
- 初回で隠す有料機能、外部AI、外部画像URL、未完成3Dを訴求している。
- 住所登録や現地外の交換手段を初回スコープのように説明している。
- 実在IPの公式提供アプリに見える表現が残っている。

## 7. Screenshots / App Preview確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| SS-001 | 必須デバイスサイズのスクショが揃っている | TODO | TODO |
| SS-002 | 画像が完成候補ビルド由来である | TODO | TODO |
| SS-003 | 実住所、実在メール、内部ID、debug表示がない | TODO | TODO |
| SS-004 | 未完成機能が写っていない | TODO | TODO |
| SS-005 | スクショの文言がメタデータと矛盾しない | TODO | TODO |
| SS-006 | UGCを出す場合、投稿前/投稿時の不適切コンテンツ対策、通報/ブロック/削除/サポート導線を説明できる。掲示板等で画面内通報ボタンがない対象はsupport@フォールバックを説明できる。評価コメントや通報者情報を保証しすぎる文言がない | TODO | TODO |
| SS-007 | App icon、App Preview、poster frame、Product Page Previewが `notes/70` と一致 | TODO | TODO |

No-Go:
- スクショが古いUI。
- 実ユーザーデータが写っている。
- 審査員が辿れない機能をスクショで見せている。

## 8. Build確認

Version画面のBuildセクションで確認する。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| BD-001 | 正しいBuild Numberを選択している | TODO | TODO |
| BD-002 | Processing完了済み | TODO | TODO |
| BD-003 | Missing Compliance等の警告がない、又は回答済み | TODO | TODO |
| BD-004 | TestFlightで確認したBuildと一致 | TODO | TODO |
| BD-005 | Export Compliance回答が `notes/46` と一致 | TODO | TODO |
| BD-006 | Privacy Manifest / SDK監査メモと矛盾しない | TODO | `notes/44` |
| BD-007 | Bundle ID、App ID、Capabilities、entitlements、profile/certificateが一致 | TODO | `notes/75` |

No-Go:
- TestFlightで確認していないBuildを選択している。
- Compliance警告を理解しないまま進める。
- Privacy ManifestやSDKの確認が未完了。
- Signing / CapabilitiesのNo-Goが残っている。

## 9. App Privacy確認

App Store Connect > App Privacyで確認する。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| AP-001 | Privacy Policy URLが公開URLと一致 | TODO | TODO |
| AP-002 | 収集データ回答が `notes/27` / `notes/43` と一致。評価コメント、通報補足、異議申し立て本文、ブロック関係、モデレーション状態、写真メタデータの残存経路も確認済み | TODO | TODO |
| AP-003 | Supabase、Apple、Google、地図、決済、AI候補、外部画像URLの扱いが反映済み | TODO | `notes/48` |
| AP-004 | 追跡の有無が実装と一致 | TODO | TODO |
| AP-005 | アカウント削除・個人情報請求の導線が説明可能。削除予定日、保持対象、復旧/取消未保証、外部連携解除の未確認事項が公開文面と一致 | TODO | `notes/45` |
| AP-006 | 外部AIを出す場合、OpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、第三者/未成年/権利未処理画像禁止がPrivacy回答と送信前説明に反映済み | TODO | TODO |
| AP-006.5 | 外部画像URL又はAI/検索候補画像を出す場合、外部ホスト通信、第三者ポリシー、画像URL保存がPrivacy回答と説明に反映済み | TODO | `notes/27`, `notes/43`, `notes/48` |
| AP-006.6 | 写真アップロードを出す場合、EXIF/GPS/撮影日時/端末情報など画像メタデータの残存経路、削除可否、App Privacy影響が確認済み | TODO | `notes/27`, `notes/43`, `notes/52` |
| AP-006.6c | カメラ/写真ライブラリ/共有シートを出す場合、Info.plist権限文言、PhotosPicker元画像データ、共有用生成画像/テキスト、外部共有後の保存/公開/再共有/削除非管理がPrivacy/App Privacy/FAQ/Review Notesで一致 | TODO | `notes/24`, `notes/27`, `notes/36`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| AP-006.6d | メール認証、パスワードリセット、Google OAuth、native callback、通知linkPath又はdeep linkを出す場合、URL scheme、Supabase Redirect URLs、Google OAuth設定、Web中継Route、認証リンク/認証コード共有禁止説明、App Privacy/FAQ/Review Notesが一致 | TODO | `notes/24`, `notes/27`, `notes/36`, `notes/43`, `notes/48`, `notes/54`, `notes/55`, `notes/56`, `notes/75` |
| AP-006.6e | Keychain保存session、access token、refresh token、session更新、logout時local clear、Keychain accessibility方針、端末紛失/バックアップ/他端末session説明がPrivacy/App Privacy/FAQ/Review Notesで一致 | TODO | `notes/17`, `notes/24`, `notes/27`, `notes/36`, `notes/43`, `notes/48`, `notes/52`, `notes/54`, `notes/55`, `notes/75` |
| AP-006.6a | 現在地共有、服装写真、取引チャット写真を出す場合、30日後自動削除ではなく運用目標であること、署名URL/端末キャッシュ/相手保存/通報・法令対応による例外保持をPrivacy、FAQ、Review Notesで一致させている | TODO | `notes/legal/02`, `notes/52`, `notes/55` |
| AP-006.6b | 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示を出す場合、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証がPrivacy/App Privacy/FAQ/Review Notesで一致 | TODO | `notes/27`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| AP-006.7 | Push通知を出す場合、APNs/Expo token、push provider、app version、last seen、revoked状態、通知本文、通知ID、linkPath、sound、未読バッジ、ロック画面/通知センター/連携端末表示、Push任意性、販促Push同意/停止手段、User Content/Usage Data影響がPrivacy回答と説明に反映済み | TODO | `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/56` |
| AP-006.8 | 生年月日/年齢表示を出す場合、Other Data Types候補、自己申告年齢説明、Age Rating、FAQ/Review Notesが一致 | TODO | `notes/25`, `notes/43`, `notes/46`, `notes/55` |
| AP-006.9 | 性別、活動エリア、公開プロフィール、評価、支払い方法要約を出す場合、Other Data Types / Coarse Location / User Content候補、自己申告プロフィール説明、FAQ/Review Notesが一致 | TODO | `notes/25`, `notes/43`, `notes/46`, `notes/55` |
| AP-006.10 | 評価、通報、異議申し立て、ブロック、モデレーションを出す場合、Customer Support / Other User Content / Other Data Types / Product Interaction候補、通報者秘匿の限界、緊急時外部連絡説明が一致 | TODO | `notes/25`, `notes/26`, `notes/43`, `notes/55`, `notes/56` |
| AP-006.11 | 郵送交換、郵送先住所、電話番号、郵便番号検索、支払い設定、銀行振込、PayPay対応可否、現金交換、口座番号入力、口座名義、金額指定、合意後の支払い情報表示又は成立後支払い情報スナップショットを出す場合、Contact Info / Financial Info回答、ZipCloud等外部送信、外部決済サービス非関与、合意後表示、保持、住所確認・本人確認・口座名義確認・支払能力確認・送金/収納代行/回収/返金/チャージバック/エスクロー/外部ID・送金リンク・QR真正性確認の非保証が一致 | TODO | `notes/25`, `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/55` |
| AP-006.12 | ホーム候補、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalizationを出す場合、Search History / Usage Data / Product Personalization回答、非保証説明、検索ログ保存有無、organic/ad区別が一致 | TODO | `notes/24`, `notes/27`, `notes/43`, `notes/55`, `notes/56` |
| AP-007 | 顔候補付けを出す場合、Sensitive Info回答、Face IDではない説明、削除/同意/保持、`member_face_profiles`読み取り範囲、学習データ追加可否が反映済み | TODO | `notes/27`, `notes/43`, `notes/52` |
| AP-008 | 広告を出す場合、不適切/年齢不相応広告の通報導線、広告SDK回答、サポート説明、Google公式データ開示、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、test ads除去、同意管理要否が反映済み | TODO | `notes/25`, `notes/27`, `notes/36`, `notes/43`, `notes/44`, `notes/48`, `notes/53`, `notes/56` |

No-Go:
- 実装で収集しているデータが未申告。
- ホーム候補、検索結果、「マッチしてるよ！」「交換できるかも？」「全一致」等が見えるのに、参考表示であり本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明を確認していない。
- 検索語、`normalized_term`、`result_count`、検索時刻、人気検索、検索候補、表示順、Plus優先表示、広告挿入又はProduct Personalizationが有効なのに、App Privacy、Privacy、FAQ、Review Notesの一致を確認していない。
- 外部SDKの収集データを確認していない。
- 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証を確認していない。
- 外部AIが見えるのにOpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、Privacy回答と規約/ポリシーに説明がない。
- Push通知が見えるのにAPNs/Expo token、通知本文、未読バッジ、ロック画面表示、App Privacy回答を確認していない。
- Push通知を許可しないと登録又は主要機能を使えない、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をPush本文へ出す、又は販促Pushに同意・停止手段がない。
- 生年月日又は年齢表示が見えるのにApp Privacy、Age Rating、FAQ、Review Notesで自己申告年齢として一致していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- 性別、活動エリア、評価、支払い方法要約が見えるのに、本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済み、運営推薦ではない説明がない。
- 評価コメント、通報、異議申し立て、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- UGCが見えるのに、投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先、運用SOPが実ビルドとReview Notesで説明できない。又はランダム/匿名チャット、出会い、外見評価、脅迫、いじめ用途に見える。
- 通報者情報を絶対非開示と保証している、又はブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- 郵送先住所、電話番号、郵便番号検索、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定、合意後の支払い情報表示又は成立後支払い情報スナップショットが見えるのに、Contact Info / Financial Info回答、参加者限定表示、目的外利用禁止、外部送信、外部決済サービス非関与、スナップショット保持の説明がない。
- Megrumが住所確認、本人確認、配送保証、送金、収納代行、回収、返金、チャージバック、決済代行、エスクロー、口座名義確認、支払能力確認、外部アカウント/外部ID/送金リンク/QRコード/残高/送金可否/受領可否の確認を行うように説明している。
- 退会申請の30日後実削除、申請取消/復旧、Apple/Google連携解除、APNs token無効化が未確認なのに、公開ページやReview Notesで完了又は復旧を保証している。
- 現在地共有又は服装写真の30日後自動削除、完全削除、即時反映が未確認なのに、公開ページやReview Notesで保証している。
- 外部画像URL又はAI/検索候補画像が見えるのに外部ホスト通信、第三者ポリシー、画像URL保存、Content Rights説明がない。
- 写真アップロードが見えるのにEXIF/GPS/撮影日時/端末情報など画像メタデータの残存経路とApp Privacy影響を確認していない。
- カメラ/写真ライブラリの権限文言が実用途より狭い、又は共有シート/外部SNS共有が見えるのに共有用画像/テキストに含まれる情報と外部共有後の保存・公開・再共有・削除非管理を確認していない。
- 認証リンク、callback URL、access token、refresh token、認証コード、通知linkPath、ID付きdeep linkを第三者へ共有してよいように説明している、又はURL scheme / Supabase Redirect URLs / Google OAuth設定 / Web中継Route / Review Notesが不一致。
- Keychain保存session、refresh token更新、logout時local clear、Keychain accessibility/backups/復元/他端末sessionの説明がPrivacy、FAQ、Review Notesと不一致、又はlogout/退会で全session/tokenが即時完全削除されると説明している。
- 顔候補付け、顔特徴量又は画像特徴量保存が見えるのにSensitive Info回答、Face ID非利用、`member_face_profiles`読み取り範囲、学習データ追加可否、削除/利用停止の説明がない。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、App Privacy回答、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否がない。

## 10. App Review Information確認

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| AR-001 | Contact first/last name | 対応可能な担当 | TODO |
| AR-002 | Contact phone | 審査対応可能な番号 | TODO |
| AR-003 | Contact email | 審査対応可能なメール | TODO |
| AR-004 | Demo account username | App Store Connectだけに実値入力 | TODO |
| AR-005 | Demo account password | リポジトリに書かずApp Store Connectだけに入力 | TODO |
| AR-006 | Notes | `notes/40` / `notes/60` の最終Review Notesと一致 | TODO |
| AR-007 | Attachment | 必要な補足がある場合だけ添付 | TODO |

Review Notesで必ず触れること:
- Megrumはユーザー同士の現地交換調整アプリである。
- アカウントが必要な理由。
- デモアカウントで確認できる主要経路。
- 通報、ブロック、問い合わせ、アカウント削除の場所。
- UGCを出す場合、投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先、運用SOP。未実装のフィルタや即時監視は書かない。
- 初回で有料機能、外部AI、未完成3Dを隠す場合は、見えないこと。
- 外部AIを出す場合は、OpenAI/web_search/画像又は画像URL送信/保持/学習利用/第三者画像禁止の説明が見えること。
- 生年月日/年齢表示が見える場合は、自己申告情報でありAge Assurance又はID verificationではないこと。
- 性別、活動エリア、評価、支払い方法要約が見える場合は、自己申告又は利用状況ベースの参考情報であり、Legal gender verification、identity verification、safety verification、payment capacity verification、developer endorsementではないこと。
- ホーム候補、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入又はProduct Personalizationが見える場合は、ユーザー登録情報や利用状況に基づく参考表示であり、identity verification、safety verification、credit check、authenticity check、payment/delivery/meeting guarantee、transaction completion guaranteeではないこと。
- カメラ、写真ライブラリ又は共有シートが見える場合は、写真ライブラリ由来の画像メタデータが残る可能性、共有用画像/テキストに含まれる情報、外部共有後のpublication/storage/reshare/deletion/analytics/metadata handlingは共有先サービスのポリシーに従うこと。
- 評価コメント、通報、ブロック、モデレーションが見える場合は、緊急通報、legal judgment、identity verification、safety verification、credit check、deletion guaranteeではないこと。
- 広告を出す場合は、不適切又は年齢に合わない広告を通報できること。AdMobを出す場合は、test adsのまま一般公開していないこと、ATT/Tracking/App Privacy/Google公式データ開示が一致していること。
- 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示を出す場合は、精密座標を扱い得ること、MapKit/CoreLocation/CLGeocoder等を使うこと、1km/3kmが匿名化又は安全保証ではないこと、地図/距離/場所名が安全又は到着を保証しないこと。
- Megrumはユーザー同士のグッズ交換補助であり、売買マーケット、古物商、買取、販売代理、オークション、チケット譲渡又は決済代行ではないこと。チケット、入場用QRコード、抽選権、盗品、不正取得品、権利侵害品、反復継続的販売又は古物営業のおそれがある取引は禁止であること。
- 公開URLがログイン不要であること。

No-Go:
- デモアカウントでログインできない。
- 実パスワードをリポジトリや公開文書に書く。
- Review Notesに完成ビルドで辿れない画面を書く。

## 11. IAP / 同時提出アイテム確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| IA-001 | 初回で有料機能を出すか最終判断済み | TODO | `notes/33` |
| IA-002 | 出す場合、IAP商品がReady to Submit相当 | TODO | TODO |
| IA-003 | 出す場合、価格、表示名、説明、特商法表示が一致 | TODO | TODO |
| IA-004 | 隠す場合、アプリ、スクショ、説明文、Review Notesに露出なし | TODO | `notes/59` |
| IA-005 | 同時提出するIAP/イベント/追加アイテムがDraft Submissionに含まれている | TODO | TODO |

No-Go:
- 有料機能が見えるのにIAP未設定。
- IAPを同時提出する必要があるのにSubmissionへ入れていない。
- 特商法表示や価格説明と矛盾する。

## 12. Add for Review直前チェック

| Check | 確認 | 結果 |
|---|---|---|
| AF-001 | `notes/36` の証跡欄を開いている | TODO |
| AF-002 | `notes/50` の最終判定がGo/Conditional Go | TODO |
| AF-003 | Version/Build/Review Notes/App Privacyのスクショ又は控えを保存した | TODO |
| AF-004 | 開発セッションに「このBuildで提出へ進む」ことを共有した | TODO |
| AF-005 | これ以降のコード修正は次ビルド扱いになることを確認した | TODO |

操作:
1. 対象Version右上のAdd for Reviewを押す。
2. 新規Draft Submission又は既存Draft Submissionを選ぶ。
3. Draft Submissionに対象Versionが入っていることを確認する。
4. 同時提出するIAP等がある場合、同じSubmissionに含める。

No-Go:
- 違うVersion/BuildをAdd for Reviewしている。
- IAP等の同時提出アイテムを入れ忘れている。
- 証跡保存前に進めようとしている。

## 13. Submit for Review直前チェック

| Check | 確認 | 結果 |
|---|---|---|
| SR-001 | Draft SubmissionにMegrumの正しいVersionが入っている | TODO |
| SR-002 | 同時提出アイテムの有無が最終判断と一致 | TODO |
| SR-003 | Submit for Review後のステータス記録欄を用意した | TODO |
| SR-004 | リジェクト時の対応先が決まっている | TODO |
| SR-005 | 承認後の公開方法が手動/自動のどちらか決まり、手動公開なら `notes/72` を使う | TODO |

操作:
1. Draft Submissionを開く。
2. 内容を最終確認する。
3. Submit for Reviewを押す。
4. ステータスがReady for Review、Waiting for Review、又はIn Reviewへ進んだことを記録する。

No-Go:
- 提出後の監視担当がいない。
- 承認後の公開方法が未決。
- リジェクト文の保存先が未決。

## 14. 提出直後に記録すること

| 項目 | 値 |
|---|---|
| Submit日時 | TODO |
| App Store Connect status | TODO |
| Version | TODO |
| Build Number | TODO |
| 提出者 | TODO |
| 同時提出アイテム | TODO |
| Review Notes最終版 | TODO |
| App Privacy回答控え | TODO |
| 公開URL確認結果 | TODO |
| 証跡保存先 | TODO |
| 次の監視担当 | TODO |

提出直後に行うこと:
1. `notes/36_submission_evidence_checklist.md` に証跡を追記する。
2. `notes/51_post_submission_release_day_runbook.md` の提出後監視へ移る。
3. 承認後に `Pending Developer Release` になった場合は `notes/72_app_store_approval_release_control_runbook.md` へ移る。
4. リジェクトが来た場合は `notes/41_app_review_response_templates.md` へ指摘文を転記する。

## 15. 関連文書

- 全体司令塔: `notes/39_release_command_center.md`
- TestFlight / Submit手順: `notes/32_testflight_review_submission_runbook.md`
- App Store Connect入力: `notes/31_app_store_connect_metadata_worksheet.md`
- 転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- ローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- 商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- 提出証跡: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
- 提出後・公開初日運用: `notes/51_post_submission_release_day_runbook.md`
- 承認後・手動公開制御: `notes/72_app_store_approval_release_control_runbook.md`

## 16. 公式参照

- Apple Submit an App: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple Overview of Submitting for Review: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review/
- Apple App information: https://developer.apple.com/help/app-store-connect/reference/app-information
- Apple Manage App Privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Apple App privacy details: https://developer.apple.com/app-store/app-privacy-details/
