# 50. App Store初回提出 Go / No-Go 判定表

最終更新: 2026-05-31

ステータス: Draft v0.1（完成ビルド到着前）

## 目的

完成候補ビルドが来た後、App Store初回提出へ進むか止めるかを、機能、法務、プライバシー、運用、証跡の観点で判定する。

この文書は判断表であり、コード、DB、ビルド設定、外部サービス設定は変更しない。

## 1. 判定ルール

| 判定 | 意味 | 次の行動 |
|---|---|---|
| Go | 初回提出に進める | App Store Connectで提出する |
| Conditional Go | 露出しない機能又はメタデータ削除で回避できる | 隠す、説明を削る、証跡を残して提出 |
| No-Go | 提出すると審査又は公開後に重大リスク | 修正、非表示、公開URL修正、法務確認後に再判定 |

基本方針:
- 初回の勝ち条件は「一般公開完了」ではなく「App Store審査への初回提出完了」。
- 見えている機能は、実機で動く、説明できる、規約/プライバシー/App Privacyと一致する必要がある。
- 見せない機能は、App Store説明文、スクショ、Review Notes、公開ページからも外す。
- P0は原則Passが必要。P1は提出後対応でもよいものと、提出前に担当/手順だけ決めればよいものに分ける。

## 2. Gate一覧

| Gate | 領域 | Go条件 | No-Go条件 | 参照 |
|---|---|---|---|---|
| G0 | スコープ | 初回提出範囲が現地交換MVPで固定 | 未完成スコープが画面/説明/スクショに残る | `notes/39`, `notes/42` |
| G1 | Auth | 新規登録、ログイン、ログアウト、セッション維持が通る | デモアカウント又は審査員が入れない | `notes/35`, `notes/42` |
| G2 | Core Flow | 在庫、wish、打診、ネゴ、取引チャット、評価までP0が通る | コア交換フローが途中で止まる | `notes/42` |
| G3 | Safety | 通報、ブロック、問い合わせ、モデレーション説明がある | UGCが見えるのに安全導線が説明できない | `notes/26`, `notes/34` |
| G4 | Account | アカウント削除、保持対象、個人情報請求を説明できる | アカウント作成があるのに削除入口がない | `notes/45` |
| G5 | Legal URL | Terms、Privacy、Support、CommerceがHTTPSで開く | URLが404、ログイン必須、実ビルドと矛盾 | `notes/25`, `notes/37`, `notes/47` |
| G6 | App Privacy | App Privacy、Privacy Manifest、実通信/SDKが一致 | 収集データ、位置情報、通知、外部SDK回答に漏れ | `notes/27`, `notes/43`, `notes/44`, `notes/48` |
| G7 | App Store Metadata | 説明文、スクショ、Review Notes、質問票が実ビルドと一致 | 未完成機能や誤ったデータ取扱いを説明している | `notes/31`, `notes/40`, `notes/46` |
| G8 | IAP | 有料機能が見えるならIAP/価格/復元/特商法が一致 | 有料導線が見えるのにIAP未整備 | `notes/33` |
| G9 | AI | 外部AIが見えるなら説明、同意、送信情報、Privacy回答が一致 | 外部AIへ送るのに説明/同意がない | `notes/24`, `notes/27`, `notes/48` |
| G10 | Evidence | Build、URL、App Privacy、スクショ、Review Notesの控えがある | 何を確認したか追えない | `notes/36` |
| G11 | Incident | 事故疑いがない。ある場合は初動記録と法務確認済み | 事故疑いが未処理 | `notes/49` |
| G12 | Security | RLS、Storage、secret、APNs、管理者権限の提出前監査がPass | 他人データ表示、公開bucket、secret露出、任意通知送信の疑い | `notes/54` |
| G13 | Legal Review | 法務レビュー回答が反映済み、又は未反映論点が初回提出に影響しない | 弁護士回答の未反映/要再確認が残っている | `notes/58` |
| G14 | Scope Exposure | 出す/隠す機能が画面、文面、FAQ、App Privacy、スクショで一致 | 隠すはずの機能が画面やメタデータに残る | `notes/59` |
| G15 | RC Handoff | Version、Build、commit SHA、検証結果、出す/隠す機能が開発側から共有済み | 提出候補ビルドの由来やスコープが追えない | `notes/65` |

## 3. P0トラッカー対応

| 領域 | P0 ID | 判定に使う文書 | Go条件 |
|---|---|---|---|
| Auth | RL-001, RL-002 | `notes/42` | 登録、ログイン、ログアウト、再起動後復帰がPass |
| 在庫/wish | RL-003, RL-004, RL-005, RL-022 | `notes/42` | 作成、編集、削除、推し追加復帰がPass |
| 個別条件/マッチ | RL-006, RL-007 | `notes/42` | 表示、保存、候補遷移がPass |
| 打診/ネゴ/取引 | RL-008, RL-009, RL-010, RL-011, RL-012 | `notes/42` | 2アカウントで主要フローがPass |
| 法務/URL | RL-013, RL-036, RL-045, RL-056 | `notes/25`, `notes/37`, `notes/47`, `notes/58` | 公開URL、サポートメール、法務回答反映が確認済み |
| App Store提出 | RL-014, RL-015, RL-027, RL-034, RL-038, RL-040 | `notes/31`, `notes/32`, `notes/35`, `notes/40`, `notes/42` | ビルド、デモアカウント、転記文面、P0台本が揃う |
| スコープ | RL-019, RL-020, RL-021, RL-057 | `notes/39`, `notes/42`, `notes/59` | 現地交換MVP、露出範囲、App Privacy回答が一致 |
| 3D/めぐり | RL-017 | `notes/22_release_triage_tracker.csv` | 未完成3Dが露出しない |
| UGC安全 | RL-030 | `notes/26`, `notes/42` | 通報/ブロック/問い合わせが説明できる |
| アカウント | RL-031, RL-043 | `notes/45` | 削除入口、保持対象、請求導線が説明できる |
| IAP | RL-032 | `notes/33` | 出すならIAP完備。未完なら隠す |
| AI | RL-028 | `notes/24`, `notes/27`, `notes/48` | 外部AIを出すなら説明/同意/回答完備。未完なら隠す |
| Privacy/Security | RL-029, RL-041, RL-042, RL-046, RL-052 | `notes/27`, `notes/43`, `notes/44`, `notes/48`, `notes/54` | 実ビルド、回答、RLS/Storage/secret監査が一致 |
| 質問票 | RL-044 | `notes/46` | Age Rating、Content Rights、Export Compliance回答済み |

## 4. Conditional Goの扱い

次は「機能を完全に隠し、説明文・スクショ・Review Notesから削れば」提出可能にできる。

| 条件付き項目 | 隠す場合の確認 | 出す場合の必須 |
|---|---|---|
| 有料機能 | Premium、めぐりPlus、ブーストが画面に出ない | IAP商品、価格、復元、特商法、Purchases回答 |
| 外部AI | AI送信画面、説明、ボタンが出ない | 送信情報、送信先、同意、Privacy回答、規約反映 |
| グルーム/掲示板 | 未完成投稿導線が出ない | 投稿、通報、ブロック、モデレーション |
| 未完成3D | 3D画面、スクショ、説明が出ない | 表示崩れなし、審査説明、Privacy影響確認 |
| Push通知 | 通知許可、通知送信が出ない | APNs token、通知本文、Identifiers回答 |
| 位置情報 | 現在地共有/近くの表示が出ない | 権限文言、Location回答、共有範囲説明 |

Conditional Goにする場合は、`notes/36` に「隠した証跡」と「説明文から削除した箇所」を残す。

## 5. Owner Sign-off

提出直前に、次を1行ずつ埋める。

| 項目 | 判定 | 証跡 | 署名/日付 |
|---|---|---|---|
| G0 Scope | TODO | TODO | TODO |
| G1 Auth | TODO | TODO | TODO |
| G2 Core Flow | TODO | TODO | TODO |
| G3 Safety | TODO | TODO | TODO |
| G4 Account | TODO | TODO | TODO |
| G5 Legal URL | TODO | TODO | TODO |
| G6 App Privacy | TODO | TODO | TODO |
| G7 Metadata | TODO | TODO | TODO |
| G8 IAP | TODO | TODO | TODO |
| G9 AI | TODO | TODO | TODO |
| G10 Evidence | TODO | TODO | TODO |
| G11 Incident | TODO | TODO | TODO |
| G12 Security | TODO | TODO | TODO |
| G13 Legal Review | TODO | TODO | TODO |
| G14 Scope Exposure | TODO | TODO | TODO |
| G15 RC Handoff | TODO | TODO | TODO |

最終判定:

```
Decision: Go / Conditional Go / No-Go
Version:
Build:
Submitted by:
Submitted at:
Known exclusions:
Evidence folder:
```

## 6. No-Go即時停止リスト

- デモアカウントでログインできない。
- コア交換フローが途中で止まる。
- App Privacyと実ビルドが矛盾している。
- RLS、Storage公開範囲、secret、APNs通知の監査でNo-Goが残っている。
- 法務レビュー回答の未反映又は要再確認が残っている。
- 提出候補ビルドのVersion、Build、commit SHA、検証結果、出す/隠す機能が不明。
- 隠すはずの機能が画面、FAQ、App Store文面、スクショ、Review Notesに残っている。
- Privacy Policy URL又はSupport URLが404。
- アカウント削除入口がない。
- UGCが見えるのに通報/ブロック/問い合わせがない。
- 有料導線が見えるのにIAPが未整備。
- 外部AIが見えるのに説明/同意/Privacy回答がない。
- 住所登録又は住所表示の未完成導線が見える。
- 個人情報・セキュリティ事故疑いが未処理。
- スクショに実住所、実在IP、内部ID、デバッグ表示がある。

## 7. 関連文書

- 提出コントロールボード: `notes/39_release_command_center.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Review Guideline適合マトリクス: `notes/53_app_review_guideline_compliance_matrix.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 外部サービス・委託先データ台帳: `notes/48_external_service_vendor_register.md`
- 個人情報・セキュリティ事故初動ランブック: `notes/49_privacy_security_incident_response_runbook.md`
- 法務レビュー回答反映台帳: `notes/58_legal_review_response_tracker.md`
- 初回提出スコープ露出監査表: `notes/59_initial_release_scope_exposure_audit.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- データ保持・削除マトリクス: `notes/52_data_retention_deletion_matrix.md`
