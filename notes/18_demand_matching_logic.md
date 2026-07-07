# 18. 需要行（激求！／求！）マッチングロジック仕様

> ホーム候補の「需要行」（激求！/求！/定価/探し中/相談）がどう決まるかの決定版。
> 実装：`HomeCandidateDemandPolicy.demandLine` を中心に、
> `HomeMutualMatchListingEvaluation`（1件ずつの合致判定）、
> `HomeListingSelectionPolicy.requiredOfferCount`（必要提示数）、
> `HomeCandidateListingWantedOptionFactory`（選択肢→WantedOption 変換）で構成。
> 直近の関連 iter：1226.338（シリーズ/数量もマッチ必須）、1226.339（提示数を必須化）、1226.361（満たせない選択肢は需要に数えない）。

---

## 0. 用語

- **候補（candidate）**：ホームに出る相手ユーザーの塊。中に相手の「求められているグッズ（=あなたが譲れそうな相手のグッズ）」が複数入る。
- **需要行**：各候補に付く1行のラベル。**5段階**。優先度は
  **激求！(hotDemand) ＞ 求！(demand) ＞ 定価(cash) ＞ 探し中(lookingFor) ＞ 相談(discuss)**。
- 判定の向きは常に「**相手があなたのグッズをどれだけ求めているか**」。相手の**個別募集の選択肢**と**ほしいもの**を、**あなたの在庫**に突き合わせて決まる。

---

## 1. 判定の材料（相手側データ）

相手の個別募集は「**選択肢（option）**」の集合。各選択肢：

- **kind**：`goodsIDs`（ほしいものに具体グッズを指定）があれば **goods（指名）**、空なら **condition（条件）**、金額なら **cash（定価）**。
  - コード：`kind = option.wishIds.isEmpty ? .condition : .goods`（cashは別フラグ）。
- **logic**：内部enumは `.all(すべて)` / `.one(どれか1つ)` / `.atLeast(n個以上)` の3種だが、**UIで選べる範囲は文脈で異なる**：
  - **ほしいもの指定（goods）**：複数選択時は「**すべて希望**／**◯個以上**」の2択のみ（`.one`ボタンは出ない）。1件だけ選んだ選択肢は内部的に `.one` で保存される（＝その1点）。
  - **条件（condition）**：「**どれか1つだけ(.one)**／**全部ほしい(.all)**」＋別枠で数量（conditionQuantity）。
  - **譲（have）**：「すべて譲る(.all)／◯個以上(.atLeast)」。
- **minimumCount**：「n個以上」の n。
- **条件フィールド**：グループ / 種別 / メンバー指定・除外 / シリーズ / 数量。

加えて、相手の**ほしいもの（wish）**に自分の譲グッズが当たる分＝`wishMatchedOfferGoodsIDs`。

---

## 2. 「1件のあなたのグッズが、1つの選択肢に合致するか」

`HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods`。上から順に：

1. 選択肢が**そのグッズIDを直接指名**していれば合致。
2. 指名グッズ（wishIds）がある選択肢は、指名グッズと**同一グッズ判定**（`HomeCandidateGoodsMatchPolicy.wishRow`）で合致。
3. 指名なし（=条件選択肢）は、**グループ・種別が両方一致**（未指定=ワイルドカード）した上で：
   - **メンバー**：指定ありなら該当メンバー必須／除外指定ならそのメンバーは対象外。
   - **シリーズ**：指定があれば、あなたのグッズのタグに**そのシリーズが1つ以上含まれる**こと。
   - **数量**：`数量>1` なら、そのグッズ1件の在庫数（`marketAvailableQty ?? quantity ?? 1`）が**要求数以上**であること。

合致したあなたのグッズ群＝その選択肢の **matchingGoodsIDs**。

---

## 3. 「その選択肢を実際に満たせるか」（iter1226.361）

必要提示数 `HomeListingSelectionPolicy.requiredOfferCount`：

- **すべて(all)** → 相手が指名したグッズ数（例：2つ指名なら **2**）
- **どれか1つ(one)** → **1**
- **n個以上(atLeast)** → **n**

**満たせる ⇔ `matchingGoodsIDs.count ≧ requiredOfferCount`**（`HomeCandidateDemandPolicy.isOfferSatisfiable`）。

> 例：相手が2つを「すべて」希望、あなたは1つしか持っていない → 必要2・手持ち一致1 → **満たせない**
> → **激求にも求にも数えない**（打診しても提示物が足りず完結しないため、バッジを出さない）。

---

## 4. 需要行の決定（上から順に、最初に当たったもの）※iter1226.362 で定義変更

1. **激求！(hotDemand)**：`kind=goods`（指名）**または** `kind=condition`（条件）で、**満たせる**個別募集の選択肢が1つでもある。
2. **求！(demand)**：相手の**ほしいもの**（個別募集に紐づかない単独リスト）由来 `wishMatchedOfferGoodsIDs` あり。
3. **定価(cash)**：`kind=cash` の選択肢がある。
4. **探し中(lookingFor)**：上記なしだが相手の探し物テキストが分かる。
5. **相談(discuss)**：何も分からない。

意味の切り分け（iter1226.362 でオーナー確定）：
- **激求！＝相手の“個別募集の選択肢”（指名でも条件でも）を、あなたが手持ちで満たせる**（＝本気の交換募集にヒット）。
- **求！＝相手の“ほしいもの”（ゆるい単独リスト）にあなたのグッズが当たった**。

> 旧仕様（〜iter1226.361）：指名=激求／条件・ほしいもの=求。
> 新仕様（iter1226.362〜）：個別募集（指名・条件）=激求／ほしいもの=求。

---

## 5. 並び順（`sortKey`）

- **候補どうし**：①塊内の最高需要ランク（激求4>求3>定価2>探し中1>相談0）の高い順 → ②その塊で「求以上（ランク≧3）」のグッズ数が多い順 → ③元の順。
- **塊の中のグッズ**：需要ランクの高い順（先頭が代表グッズ）。

---

## 6. 表示（`HomeCandidateDemandLineView`）

- **激求！**：「あなたのグッズが激求！」（複数=「あなたのグッズ他N点が激求！」）／ピンク→濃ピンクのグラデ。
- **求！**：「あなたのグッズが求！」／ラベンダー。
- **定価**：「定価（¥◯）と交換OK」／スカイ→ラベンダーのグラデ。
- **探し中**：「◯◯を探し中」／グレー。
- **相談**：「求めているものは打診で相談」／グレー。

物流行（`logisticsText`）・支払行（`paymentText`）は需要行と独立。

---

## 7. 「求められているグッズ」タップ後との連動

詳細シートで「譲るものを選ぶ」時の**必要選択数**も同じ `requiredOfferCount`。
iter1226.361 でバッジ側と揃えたため、「激求と出たのに提示物が足りず打診に進めない」矛盾は起きない。

---

## 関連ファイル

- `ios-native/Sources/MegrumApp/HomeCandidateDemandPolicy.swift`（需要行の決定・並び順）
- `ios-native/Sources/MegrumApp/HomeMutualMatchListingEvaluation.swift`（1件ずつの合致判定）
- `ios-native/Sources/MegrumApp/HomeListingSelectionPolicy.swift`（requiredOfferCount）
- `ios-native/Sources/MegrumApp/HomeCandidateListingWantedOptionFactory.swift`（選択肢→WantedOption、kind決定・matchingGoodsIDs）
- `ios-native/Sources/MegrumApp/HomeDiscoveryCandidateSummaryRow.swift`（需要行の表示）
