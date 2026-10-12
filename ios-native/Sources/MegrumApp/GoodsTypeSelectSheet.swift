import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// グッズ種別の選択シート（推し設定の「推しを追加」と同構造の共通モジュール）。
/// マイグッズ / ほしいもの登録・編集のグッズ種別選択から呼び出す。
/// カテゴリ絞り込み・追加リクエストは無し。自由入力で検索できる。
struct GoodsTypeSelectSheet: View {
    var goodsTypes: [GoodsType]
    var selectedGoodsTypeID: UUID?
    var onSelect: (GoodsType) -> Void
    var onClose: () -> Void
    /// 複数選択モード（検索フィルター用）。設定時はタップでトグルし、閉じるまで選択を続けられる。
    var multiSelection: Binding<Set<UUID>>?

    @State private var searchText = ""
    /// 最近使ったグッズ種別（最大5件、最近順）。単一選択の登録フローで上部に出す。iter1226.385 / FB8-8。
    @AppStorage(GoodsTypeRecentSelection.storageKey) private var recentGoodsTypeIDsRaw = ""

    init(
        goodsTypes: [GoodsType],
        selectedGoodsTypeID: UUID?,
        onSelect: @escaping (GoodsType) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.goodsTypes = goodsTypes
        self.selectedGoodsTypeID = selectedGoodsTypeID
        self.onSelect = onSelect
        self.onClose = onClose
        self.multiSelection = nil
    }

    init(goodsTypes: [GoodsType], selectedGoodsTypeIDs: Binding<Set<UUID>>) {
        self.goodsTypes = goodsTypes
        self.selectedGoodsTypeID = nil
        self.onSelect = { _ in }
        self.onClose = {}
        self.multiSelection = selectedGoodsTypeIDs
    }

    private var filteredGoodsTypes: [GoodsType] {
        GoodsTypeSelectFilter.filtered(goodsTypes, searchText: searchText)
    }

    /// 最近使った種別（登録フロー＝単一選択かつ未検索のときだけ、上部に最大5件表示）。iter1226.385 / FB8-8。
    private var recentGoodsTypes: [GoodsType] {
        guard multiSelection == nil, searchText.isEmpty else {
            return []
        }
        let byID = Dictionary(goodsTypes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return GoodsTypeRecentSelection.recentIDs(from: recentGoodsTypeIDsRaw).compactMap { byID[$0] }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if filteredGoodsTypes.isEmpty {
                    emptyResult
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        if !recentGoodsTypes.isEmpty {
                            typeSection(title: "最近使った", types: recentGoodsTypes)
                            Divider().opacity(0.4).padding(.horizontal, 18)
                            typeSection(title: "すべて", types: filteredGoodsTypes)
                        } else {
                            typeSection(title: nil, types: filteredGoodsTypes)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            searchFooter
        }
    }

    private func isSelected(_ goodsType: GoodsType) -> Bool {
        if let multiSelection {
            return multiSelection.wrappedValue.contains(goodsType.id)
        }
        return goodsType.id == selectedGoodsTypeID
    }

    @ViewBuilder
    private func typeSection(title: String?, types: [GoodsType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.horizontal, 18)
            }
            WrappingTagFlow(
                spacing: OshiMasterSelectLayoutMetrics.candidateTagSpacing,
                rowSpacing: OshiMasterSelectLayoutMetrics.candidateTagRowSpacing
            ) {
                ForEach(types) { goodsType in
                    OshiMasterCandidateTag(
                        title: goodsType.name,
                        isSelected: isSelected(goodsType),
                        action: { handleTap(goodsType) }
                    )
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func handleTap(_ goodsType: GoodsType) {
        if let multiSelection {
            if multiSelection.wrappedValue.contains(goodsType.id) {
                multiSelection.wrappedValue.remove(goodsType.id)
            } else {
                multiSelection.wrappedValue.insert(goodsType.id)
            }
        } else {
            // 最近使った種別として記録（最大5件、最近順）。iter1226.385 / FB8-8。
            recentGoodsTypeIDsRaw = GoodsTypeRecentSelection.updatedRaw(recording: goodsType.id, into: recentGoodsTypeIDsRaw)
            onSelect(goodsType)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("グッズ種別を選ぶ")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            if multiSelection == nil {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(width: 48, height: 48)
                        .background(.black.opacity(0.04), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 10)
    }

    private var emptyResult: some View {
        VStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted.opacity(0.6))
            Text("「\(searchText)」に一致する種別はありません")
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    private var searchFooter: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                TextField("グッズ種別名で検索", text: $searchText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: OshiMasterSelectLayoutMetrics.searchHeight)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }
            .padding(.horizontal, 18)
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}

/// VisualQA（goods-type-select）用のプレビュー。新マスタ66種を流し込んで表示確認する。
struct GoodsTypeSelectPreview: View {
    @State private var selectedGoodsTypeID: UUID?

    private static let goodsTypes: [GoodsType] = [
        "トレカ", "ピンズ・ピンバッジ・缶バッジ", "アクリルスタンド", "キーホルダー",
        "アクリルキーホルダー", "ストラップ", "ステッカー・シール", "ぬいぐるみ・マスコット",
        "写真・チェキ", "クリアファイル", "アクセサリー・ヘアアクセサリー", "クリップ",
        "フォンタブ", "ポスター", "タペストリー", "セル画", "タオル", "クッション・抱きまくら",
        "Tシャツ・アパレル", "マグカップ・食器", "カチューシャ・被り物", "パワーアップバンド",
        "うちわ", "バッグ・ポーチ", "ペンライト", "メモ用紙・文房具", "ラバーバンド", "切り抜き",
        "カレンダー", "パンフレット", "フォトハンガー", "会報", "写真",
        "ペンライト・リングライト・バングルライト", "ポストカード", "チケット",
        "株主優待券・割引券", "雑誌", "本・雑誌・漫画", "ハンドメイド・手芸", "ファッション",
        "コスメ・美容", "CD・DVD・ブルーレイ", "家具・インテリア", "ゲーム・玩具",
        "フィッシング", "フラワー・ガーデニング", "アート用品", "アマチュア無線",
        "コスチューム・コスプレ", "ラジコン・ドローン", "楽器・機材",
        "美術品・アンティーク・コレクション", "模型・プラモデル", "スマホ・タブレット・パソコン",
        "ベビー・キッズ", "テレビ・オーディオ・カメラ", "アウトドア", "旅行用品",
        "ダイエット・健康", "食品・飲料・酒", "キッチン・日用品・その他", "ペット用品",
        "DIY・工具", "車・バイク・自転車", "その他"
    ].enumerated().map { index, name in
        GoodsType(id: UUID(), name: name, displayOrder: index + 1)
    }

    var body: some View {
        GoodsTypeSelectSheet(
            goodsTypes: Self.goodsTypes,
            selectedGoodsTypeID: selectedGoodsTypeID,
            onSelect: { selectedGoodsTypeID = $0.id },
            onClose: {}
        )
    }
}

enum GoodsTypeSelectFilter {
    static func filtered(_ goodsTypes: [GoodsType], searchText: String) -> [GoodsType] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return goodsTypes
        }
        return goodsTypes.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
