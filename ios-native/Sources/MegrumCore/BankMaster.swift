import Foundation

/// 受け取り口座の銀行名を選ぶマスタ。表記ゆれを無くし、マッチング判定（同じ銀行なら太字）と
/// 相手可視の銀行名表示の両方で使う正規名を提供する。
/// - 収録は主要行・ネット銀行・ゆうちょ・主要地銀。未収録は設定画面の「その他（自由入力）」で補う。
/// - `id` はマッチング用の安定キー（実際の銀行コードではなく内部slug）。送金には使わない。
public struct BankMasterEntry: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kana: String
    public let aliases: [String]

    public init(id: String, name: String, kana: String, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.kana = kana
        self.aliases = aliases
    }
}

public enum BankMaster {
    public static let entries: [BankMasterEntry] = [
        // メガバンク・準大手
        BankMasterEntry(id: "mizuho", name: "みずほ銀行", kana: "みずほぎんこう", aliases: ["みずほ"]),
        BankMasterEntry(id: "mufg", name: "三菱UFJ銀行", kana: "みつびしゆーえふじぇいぎんこう", aliases: ["三菱UFJ", "UFJ", "三菱東京UFJ", "MUFG"]),
        BankMasterEntry(id: "smbc", name: "三井住友銀行", kana: "みついすみともぎんこう", aliases: ["三井住友", "SMBC"]),
        BankMasterEntry(id: "resona", name: "りそな銀行", kana: "りそなぎんこう", aliases: ["りそな"]),
        BankMasterEntry(id: "saitama_resona", name: "埼玉りそな銀行", kana: "さいたまりそなぎんこう", aliases: ["埼玉りそな"]),
        // ゆうちょ
        BankMasterEntry(id: "yucho", name: "ゆうちょ銀行", kana: "ゆうちょぎんこう", aliases: ["ゆうちょ", "郵貯", "郵便局"]),
        // ネット銀行（若年層に多い）
        BankMasterEntry(id: "rakuten", name: "楽天銀行", kana: "らくてんぎんこう", aliases: ["楽天"]),
        BankMasterEntry(id: "sbi_sumishin", name: "住信SBIネット銀行", kana: "すみしんえすびーあいねっとぎんこう", aliases: ["住信SBI", "SBIネット", "SBI", "ネット銀行"]),
        BankMasterEntry(id: "paypay_bank", name: "PayPay銀行", kana: "ぺいぺいぎんこう", aliases: ["PayPay銀行", "ジャパンネット銀行", "ジャパンネット", "JNB"]),
        BankMasterEntry(id: "sony", name: "ソニー銀行", kana: "そにーぎんこう", aliases: ["ソニー"]),
        BankMasterEntry(id: "au_jibun", name: "auじぶん銀行", kana: "えーゆーじぶんぎんこう", aliases: ["じぶん銀行", "auじぶん", "じぶん"]),
        BankMasterEntry(id: "gmo_aozora", name: "GMOあおぞらネット銀行", kana: "じーえむおーあおぞらねっとぎんこう", aliases: ["GMOあおぞら", "あおぞらネット"]),
        BankMasterEntry(id: "aeon", name: "イオン銀行", kana: "いおんぎんこう", aliases: ["イオン"]),
        BankMasterEntry(id: "seven", name: "セブン銀行", kana: "せぶんぎんこう", aliases: ["セブン", "7銀行"]),
        BankMasterEntry(id: "lawson", name: "ローソン銀行", kana: "ろーそんぎんこう", aliases: ["ローソン"]),
        BankMasterEntry(id: "daiwa_next", name: "大和ネクスト銀行", kana: "だいわねくすとぎんこう", aliases: ["大和ネクスト", "大和"]),
        BankMasterEntry(id: "minna", name: "みんなの銀行", kana: "みんなのぎんこう", aliases: ["みんな"]),
        BankMasterEntry(id: "ui", name: "UI銀行", kana: "ゆーあいぎんこう", aliases: ["UI"]),
        BankMasterEntry(id: "tokyo_star", name: "東京スター銀行", kana: "とうきょうすたーぎんこう", aliases: ["東京スター"]),
        BankMasterEntry(id: "sbi_shinsei", name: "SBI新生銀行", kana: "えすびーあいしんせいぎんこう", aliases: ["新生銀行", "新生", "SBI新生"]),
        BankMasterEntry(id: "aozora", name: "あおぞら銀行", kana: "あおぞらぎんこう", aliases: ["あおぞら"]),
        // 主要地方銀行
        BankMasterEntry(id: "yokohama", name: "横浜銀行", kana: "よこはまぎんこう", aliases: ["横浜", "浜銀"]),
        BankMasterEntry(id: "chiba", name: "千葉銀行", kana: "ちばぎんこう", aliases: ["千葉", "ちばぎん"]),
        BankMasterEntry(id: "fukuoka", name: "福岡銀行", kana: "ふくおかぎんこう", aliases: ["福岡", "ふくぎん"]),
        BankMasterEntry(id: "shizuoka", name: "静岡銀行", kana: "しずおかぎんこう", aliases: ["静岡", "しずぎん"]),
        BankMasterEntry(id: "joyo", name: "常陽銀行", kana: "じょうようぎんこう", aliases: ["常陽"]),
        BankMasterEntry(id: "gunma", name: "群馬銀行", kana: "ぐんまぎんこう", aliases: ["群馬"]),
        BankMasterEntry(id: "kyoto", name: "京都銀行", kana: "きょうとぎんこう", aliases: ["京都", "京銀"]),
        BankMasterEntry(id: "hiroshima", name: "広島銀行", kana: "ひろしまぎんこう", aliases: ["広島", "ひろぎん"]),
        BankMasterEntry(id: "nishinihon_city", name: "西日本シティ銀行", kana: "にしにほんしてぃぎんこう", aliases: ["西日本シティ", "西日本", "NCB"]),
        BankMasterEntry(id: "hokuyo", name: "北洋銀行", kana: "ほくようぎんこう", aliases: ["北洋"]),
        BankMasterEntry(id: "shichijushichi", name: "七十七銀行", kana: "しちじゅうしちぎんこう", aliases: ["七十七", "77銀行"]),
        BankMasterEntry(id: "hokkaido", name: "北海道銀行", kana: "ほっかいどうぎんこう", aliases: ["道銀", "北海道"]),
        BankMasterEntry(id: "kansai_mirai", name: "関西みらい銀行", kana: "かんさいみらいぎんこう", aliases: ["関西みらい"]),
        BankMasterEntry(id: "ashikaga", name: "足利銀行", kana: "あしかがぎんこう", aliases: ["足利", "あしぎん"]),
        BankMasterEntry(id: "hachijuni", name: "八十二銀行", kana: "はちじゅうにぎんこう", aliases: ["八十二", "82銀行"]),
        BankMasterEntry(id: "iyo", name: "伊予銀行", kana: "いよぎんこう", aliases: ["伊予", "いよぎん"]),
        BankMasterEntry(id: "kagoshima", name: "鹿児島銀行", kana: "かごしまぎんこう", aliases: ["鹿児島", "かぎん"]),
        BankMasterEntry(id: "okinawa", name: "沖縄銀行", kana: "おきなわぎんこう", aliases: ["沖縄", "おきぎん"]),
        BankMasterEntry(id: "daishi_hokuetsu", name: "第四北越銀行", kana: "だいしほくえつぎんこう", aliases: ["第四北越", "第四", "北越"]),
        BankMasterEntry(id: "chugoku", name: "中国銀行", kana: "ちゅうごくぎんこう", aliases: ["中国銀行", "ちゅうぎん"]),
        BankMasterEntry(id: "juroku", name: "十六銀行", kana: "じゅうろくぎんこう", aliases: ["十六", "16銀行"]),
        BankMasterEntry(id: "hokuriku", name: "北陸銀行", kana: "ほくりくぎんこう", aliases: ["北陸", "ほくぎん"]),
        BankMasterEntry(id: "toho", name: "東邦銀行", kana: "とうほうぎんこう", aliases: ["東邦"]),
        BankMasterEntry(id: "nanto", name: "南都銀行", kana: "なんとぎんこう", aliases: ["南都"]),
        BankMasterEntry(id: "kiyo", name: "紀陽銀行", kana: "きようぎんこう", aliases: ["紀陽"]),
        BankMasterEntry(id: "higo", name: "肥後銀行", kana: "ひごぎんこう", aliases: ["肥後"]),
        BankMasterEntry(id: "oita", name: "大分銀行", kana: "おおいたぎんこう", aliases: ["大分", "だいぎん"])
    ]

    private static let entryByID: [String: BankMasterEntry] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.id, $0) }
    )

    public static func entry(id: String?) -> BankMasterEntry? {
        guard let id, !id.isEmpty else {
            return nil
        }
        return entryByID[id]
    }

    /// 銀行名の候補を検索する。前方一致を優先し、次に部分一致。
    public static func search(_ query: String) -> [BankMasterEntry] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return entries
        }
        let prefixMatches = entries.filter { entry in
            haystacks(for: entry).contains { $0.hasPrefix(normalizedQuery) }
        }
        let containsMatches = entries.filter { entry in
            !prefixMatches.contains(entry)
                && haystacks(for: entry).contains { $0.contains(normalizedQuery) }
        }
        return prefixMatches + containsMatches
    }

    /// マッチング用の安定キー。マスタに一致すれば `id:<slug>`、未収録の自由入力は `free:<正規化名>`。
    /// 自分と相手のキーが一致したら「同じ銀行」とみなす。
    public static func matchKey(displayName: String?, bankID: String? = nil) -> String? {
        if let entry = entry(id: bankID) {
            return "id:\(entry.id)"
        }
        guard let displayName else {
            return nil
        }
        let normalized = normalize(displayName)
        guard !normalized.isEmpty else {
            return nil
        }
        if let entry = entries.first(where: { haystacks(for: $0).contains(normalized) }) {
            return "id:\(entry.id)"
        }
        return "free:\(normalized)"
    }

    /// 表示名を正規化（マスタに一致すれば正規表示名へ寄せる）。
    public static func canonicalDisplayName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalize(trimmed)
        if let entry = entries.first(where: { haystacks(for: $0).contains(normalized) }) {
            return entry.name
        }
        return trimmed
    }

    private static func haystacks(for entry: BankMasterEntry) -> [String] {
        ([entry.name, entry.kana, entry.id] + entry.aliases).map(normalize)
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .lowercased()
    }
}
