# 18. 需要行（超求！／求！）マッチングロジック仕様

> ホーム候補の「需要行」（超求！/超求めてる？/求！/求めてる？/定価/探し中/相談）がどう決まるかの決定版。
> 実装：`HomeCandidateDemandPolicy.demandLine`（分類）、`HomeCandidateMatchConfidence(Policy)`（軸ごと確度）、
> `HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence` / `wishGoodsConfidence`（1件ずつの確度）、
> `HomeCandidateListingWantedOptionFactory`（選択肢→WantedOption）、`HomeDiscoveryCandidateSummaryRow`（表示）。
> 関連 iter：1226.361（満たせない選択肢は数えない）、1226.362（個別募集=超求/ほしいもの=求）、1226.363（無記載は不確定「？」＋超求リネーム）。

---

## 0. 用語

- **候補**：ホームに出る相手ユーザーの塊。中に相手の「求められているグッズ（=あなたが譲れそうな相手のグッズ）」が複数入る。
- **需要行**：各候補に付く1行のラベル。**8段階**。判定の向きは「相手があなたのグッズをどれだけ求めているか」。
- **確度**：一致の確からしさ。**確定（confirmed）／不確定（tentative「？」）／非マッチ**の3値（`HomeCandidateMatchConfidence`）。

---

## 1. 判定に使う5軸と性質

| 軸 | 性質 |
|---|---|
| **グループ** | 相手が指定していれば一致必須（自分のグッズは必ず登録あり）。相手が未指定なら問わない。 |
| **メンバー** | 無記載があり得る → 軸ごと判定（無記載=不確定）。 |
| **種別** | 無記載があり得る → 軸ごと判定。 |
| **シリーズ** | 無記載があり得る → 軸ごと判定。 |
| **数量** | 満たせるか（手持ち数 ≥ 要求数）のハード条件。満たせなければ非マッチ。「？」対象外。 |

`logic`（数量の考え方）は内部 `.all/.one/.atLeast` の3種。UIで選べる範囲は文脈依存：
- ほしいもの指定：複数時「すべて希望／◯個以上」の2択（`.one`は出ない。単数選択は内部的に`.one`）。
- 条件：「どれか1つだけ(.one)／全部ほしい(.all)」＋別枠で数量。
- 譲：「すべて譲る(.all)／◯個以上(.atLeast)」。

---

## 2. 軸ごとの判定（相手が指定している軸）

- ✅ **ok**：相手が指定なし（問わない）、または 自分も登録あり＆一致。
- ❓ **tentative**：相手が指定あり＆自分が**無記載**。
- ❌ **mismatch**：相手が指定あり＆自分も登録あり＆**別値**。

統合（`combine`）：❌ が1つでも→**非マッチ**／❌なし＆❓が1つ以上→**不確定**／全部ok→**確定**。
（グループ不一致・数量未達は先に非マッチ確定）

これを、相手の選択肢/ほしいものの各パターンに適用：
1. **現物IDを直接指名** → 確定。
2. **指名グッズ（ほしいもの1件）** → そのグッズのグループ・メンバー・種別・シリーズと軸判定。
3. **条件指定** → グループ・種別＋メンバー（指定/除外）・シリーズ・数量で軸判定。

合致（確度≠非マッチ）したグッズ＝ `matchingGoodsIDs`、うち不確定＝ `tentativeGoodsIDs`。

---

## 3. 選択肢を満たせるか（必要提示数）

`requiredOfferCount`：すべて＝指定グッズ数／どれか1つ＝1／n個以上＝n。
- **確定で満たせる**：確定一致（matchingGoodsIDs − tentativeGoodsIDs）の数 ≥ 必要数。
- **満たせる（不確定含む）**：matchingGoodsIDs の数 ≥ 必要数。
満たせない選択肢は需要に数えない（iter1226.361）。

---

## 4. 需要行の決定（上から順に、最初に当たったもの）

1. **超求！**：個別募集の選択肢（指名 or 条件）を**確定で満たせる**。
2. **超求めてる？**：個別募集を満たせるが、無記載を含み**確定できない**。
3. **求！**：相手のほしいもの（単独リスト）に**確定一致**。
4. **求めてる？**：ほしいものに当たるが**確定できない**。
5. **定価**：cash選択肢。
6. **探し中**：相手の探し物が分かる。
7. **相談**：何も分からない。

意味の切り分け：
- **超求＝相手の“個別募集”にヒット／求＝相手の“ほしいもの”にヒット**（iter1226.362）。
- **確定（！）＝相手指定の全軸が一致確認できた／不確定（？）＝メンバー・種別・シリーズのどれかが自分側で無記載**（iter1226.363）。

ランク：超求！=6 / 超求めてる？=5 / 求！=4 / 求めてる？=3 / 定価=2 / 探し中=1 / 相談=0。

---

## 5. 並び順（`sortKey`）

- 候補どうし：①塊内の最高需要ランクの高い順 → ②確定需要（求！＝rank4 以上）のグッズ数が多い順 → ③元順。
- 塊の中：需要ランクの高い順（先頭が代表グッズ）。

---

## 6. 表示（`HomeCandidateDemandLineView`）

- **超求！**：「あなたの〈画像〉を超求！」／ピンクのグラデ（濃）。
- **超求めてる？**：「あなたの〈画像〉を超求めてる？」／ピンクの淡いトーン＋末尾「？」。
- **求！**：「あなたの〈画像〉を求！」／ラベンダー。
- **求めてる？**：「あなたの〈画像〉を求めてる？」／ラベンダーの淡いトーン＋末尾「？」。
- 定価「定価（¥◯）と交換OK」／探し中「◯◯を探し中」／相談「求めているものは打診で相談」。

複数点は「他N点」を挟む。物流行・支払行は需要行と独立。

---

## 7. 「求められているグッズ」タップ後との連動

詳細シートで「譲るものを選ぶ」時の必要選択数も同じ `requiredOfferCount`。
バッジ側と揃えているため（iter1226.361〜363）、表示と打診の可否が食い違わない。

---

## 関連ファイル

- `ios-native/Sources/MegrumApp/HomeCandidateDemandPolicy.swift`（需要行の決定・並び順・確度別の集計）
- `ios-native/Sources/MegrumApp/HomeCandidateMatchConfidence.swift`（軸ごと確度）
- `ios-native/Sources/MegrumApp/HomeMutualMatchListingEvaluation.swift`（1件ずつの確度：条件/指名）
- `ios-native/Sources/MegrumApp/HomeCandidateViewerOfferDemandSummary.swift`（ほしいもの確度）
- `ios-native/Sources/MegrumApp/HomeCandidateListingWantedOptionFactory.swift`（WantedOption：matchingGoodsIDs / tentativeGoodsIDs）
- `ios-native/Sources/MegrumApp/HomeDiscoveryCandidateSummaryRow.swift`（需要行の表示）
