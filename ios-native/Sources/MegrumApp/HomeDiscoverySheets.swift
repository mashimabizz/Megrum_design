import MegrumDesign
import SwiftUI

struct HomeDiscoverySheetView: View {
    var sheet: HomeDiscoverySheet
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        switch sheet {
        case .goodsHit(let selectedGoods):
            HomeGoodsHitDetailSheet(selectedGoods: selectedGoods, onOpenNestedSheet: onOpenNestedSheet)
        case .wishHit(let selectedGoods):
            HomeWishHitDetailSheet(selectedGoods: selectedGoods, onOpenNestedSheet: onOpenNestedSheet)
        case .havesLookup:
            HomeHavesLookupSheet()
        case .extraListingHit:
            HomeExtraListingHitSheet()
        case .extraWishHit:
            HomeExtraWishHitSheet()
        }
    }
}

private struct HomeGoodsHitDetailSheet: View {
    var selectedGoods: HomeMockGoods
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        HomeSheetScaffold(bottomButton: "この内容で打診する", showsWishCopyButton: true) {
            HomeSelectedGoodsHeader(goods: selectedGoods)

            Divider().opacity(0.55)

            HomeSheetSectionTitle(systemName: "person", title: "相手が求める候補")
            HomeCandidateMiniRail(
                goods: HomeDiscoveryFixtures.wantedGoods,
                selectedIndex: 0,
                cardStyle: .condition(HomeGoodsCondition.direct.shortTitle)
            )

            HomeSheetSectionTitle(systemName: "gift", title: "あなたが出せる候補", trailing: "4件の候補")
            HomeCandidateMiniRail(
                goods: HomeDiscoveryFixtures.offerGoods,
                selectedIndex: 0,
                cardStyle: .chips(["同タグ", "提示OK", "状態良"])
            )

            HomeOtherExchangeRows(onOpenNestedSheet: onOpenNestedSheet)
        }
    }
}

private struct HomeWishHitDetailSheet: View {
    var selectedGoods: HomeMockGoods
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        HomeSheetScaffold(bottomButton: "この内容で打診する", showsWishCopyButton: true) {
            HomeSelectedGoodsHeader(goods: selectedGoods)

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "gift",
                title: "あなたが譲れる候補",
                subtitle: "相手のWishに合う、あなたの譲れるもの",
                trailing: "4件の候補"
            )

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(HomeDiscoveryFixtures.offerGoods.enumerated()), id: \.element.id) { index, goods in
                    HomeSelectableGoodsCard(
                        goods: goods,
                        selected: index == 0,
                        style: .chips(["メンバー一致", "タグ一致", "グッズ条件○"])
                    )
                }
            }

            HomeOtherExchangeRows(onOpenNestedSheet: onOpenNestedSheet)
        }
    }
}

private struct HomeHavesLookupSheet: View {
    var body: some View {
        HomeSheetScaffold(bottomButton: "選んだ人に打診する", secondaryButton: "条件を変更する") {
            HomeSheetTitle(icon: "heart", title: "譲るものから見る", subtitle: "このグッズをWishに入れている人")

            HStack(alignment: .center, spacing: 22) {
                HomeDiscoveryRotaryCard(
                    goods: [HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaStand],
                    goodsCondition: .direct,
                    exchangeCondition: .exact,
                    showsConditionOverlay: false
                )
                .frame(width: 112, height: 132)

                VStack(alignment: .leading, spacing: 12) {
                    Text("サナ×2026 LIVE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    HomeConditionPill(title: "12人", color: MegrumTheme.lavender)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                HomeFilterChip(title: "近い順", systemName: "arrow.up.arrow.down", selected: true)
                HomeFilterChip(title: "評価高め", systemName: "star", selected: false)
                HomeFilterChip(title: "候補あり", systemName: "gift", selected: false)
            }

            Text("Wish登録しているユーザー")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 8) {
                ForEach(HomeWishUserRow.sampleRows) { row in
                    HomeWishUserRowView(row: row)
                }
            }
        }
    }
}

private struct HomeExtraListingHitSheet: View {
    var body: some View {
        HomeSheetScaffold(bottomButton: "このグッズも交換候補に追加する", secondaryButton: "別の求める候補を選ぶ") {
            HomeSheetTitle(icon: "tag", title: "追加で交換依頼をする", subtitle: "相手の条件に合わせて、追加する候補を選ぶ")

            Text("選んだ相手の譲るグッズ")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 22) {
                HomeDiscoveryRotaryCard(
                    goods: [HomeDiscoveryFixtures.selectedYellow, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaStand],
                    goodsCondition: .wish,
                    exchangeCondition: .possible,
                    showsConditionOverlay: false
                )
                .frame(width: 120, height: 134)

                VStack(alignment: .leading, spacing: 12) {
                    HomeConditionPill(title: "交換条件○", color: MegrumTheme.lavender)
                    HomeConditionPill(title: "支払い相談可", color: MegrumTheme.ok)
                }
                Spacer()
            }

            HomeSheetSectionTitle(systemName: "person", title: "相手が求める候補")
            HomeCandidateMiniRail(
                goods: HomeDiscoveryFixtures.wantedGoods,
                selectedIndex: 0,
                labels: ["2025 LIVE", "ファンミ", "トレカ"],
                cardStyle: .condition(HomeGoodsCondition.direct.shortTitle)
            )

            HomeSheetSectionTitle(systemName: "gift", title: "あなたが出せる候補", trailing: "4件の候補")
            HomeCandidateMiniRail(
                goods: HomeDiscoveryFixtures.offerGoods,
                selectedIndex: 0,
                cardStyle: .chips(["提示OK", "同タグ", "状態良"])
            )

            HomeExchangeSummaryBox(left: HomeDiscoveryFixtures.selectedYellow, right: HomeDiscoveryFixtures.sanaLavender)
        }
    }
}

private struct HomeExtraWishHitSheet: View {
    var body: some View {
        HomeSheetScaffold(bottomButton: "このグッズも交換候補に追加する", secondaryButton: "あとで選ぶ") {
            HomeSheetTitle(icon: "sparkles", title: "Wishでヒット！", subtitle: "相手のWishに合う、あなたの譲れるもの")

            HomeSheetSectionTitle(systemName: "person", title: "相手のWish")
            HStack(spacing: 12) {
                ForEach(HomeDiscoveryFixtures.otherWishHit.prefix(5)) { goods in
                    HomeTinyGoodsThumbnail(goods: goods)
                        .frame(width: 61, height: 68)
                }
            }

            Divider().opacity(0.5)

            HomeSheetSectionTitle(systemName: "gift", title: "あなたが譲れる候補", trailing: "4件の候補")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(HomeDiscoveryFixtures.offerGoods.enumerated()), id: \.element.id) { index, goods in
                    HomeSelectableGoodsCard(
                        goods: goods,
                        selected: index == 0,
                        style: .chips(["メンバー一致", "タグ一致", "グッズ条件○"])
                    )
                }
            }

            HomeExchangeSummaryBox(leftTitle: "相手のWish", rightTitle: "あなたが譲るもの", left: HomeDiscoveryFixtures.sanaBadge, right: HomeDiscoveryFixtures.sanaLavender)
        }
    }
}

private struct HomeSheetScaffold<Content: View>: View {
    var bottomButton: String
    var secondaryButton: String?
    var showsWishCopyButton: Bool = false
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content

                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "ellipsis.message.fill")
                            Text(bottomButton)
                        }
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)

                    if let secondaryButton {
                        Button(action: {}) {
                            Text(secondaryButton)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: max(proxy.size.width - 44, 0), alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(MegrumTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.92), in: Circle())
                            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")

                    if showsWishCopyButton {
                        Button(action: {}) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(MegrumTheme.lavender.opacity(0.92), in: Circle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Wishに追加")
                    }
                }
                .padding(.top, 18)
                .padding(.trailing, 18)
            }
        }
        .background(MegrumTheme.canvas)
    }
}

private struct HomeSelectedGoodsHeader: View {
    var goods: HomeMockGoods

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("選んだグッズ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                HomeSelectedGoodsSingleCard(goods: goods)
                .frame(width: 136, height: 162)

                VStack(alignment: .leading, spacing: 10) {
                    HomeUserSummary()

                    HomeExchangeMethodBlock()

                    HomePaymentBox()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct HomeSelectedGoodsSingleCard: View {
    var goods: HomeMockGoods

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: goods,
            goodsCondition: .direct,
            exchangeCondition: .exact,
            prominence: 1,
            showsConditionOverlay: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選んだグッズ")
    }
}

private struct HomeUserSummary: View {
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            HomeAvatar(symbol: "M")
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("mii_交換用 24歳 女")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 6) {
                    Text("★ 4.8")
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("｜")
                        .foregroundStyle(MegrumTheme.muted.opacity(0.6))
                    Text("交換32件")
                        .fontWeight(.regular)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
            }
        }
    }
}

private struct HomeExchangeMethodBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                Text("現地交換")
            }
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.top, 1)
                Text("福岡県 / 博多駅近郊")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HomePaymentBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "yensign.circle")
                Text("支払い条件")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text("差額相談可 / PayPay相談可")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ok)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
