import MegrumDesign
import SwiftUI

struct HomeSheetScaffold<Content: View>: View {
    var bottomButton: String?
    var secondaryButton: String?
    var showsWishCopyButton: Bool = false
    var wishCopyButtonDisabled: Bool = false
    var wishCopyButtonAction: () -> Void = {}
    var bottomButtonDisabled: Bool = false
    var bottomButtonAction: () -> Void = {}
    var dismissAction: (() -> Void)?
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content
                }
                .frame(width: max(proxy.size.width - 44, 0), alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, bottomBarBottomPadding)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button {
                        if let dismissAction {
                            dismissAction()
                        } else {
                            dismiss()
                        }
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
                        Button(action: wishCopyButtonAction) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(MegrumTheme.lavender.opacity(wishCopyButtonDisabled ? 0.46 : 0.92), in: Circle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(wishCopyButtonDisabled)
                        .accessibilityLabel("Wishに追加")
                    }
                }
                .padding(.top, 18)
                .padding(.trailing, 18)
            }
        }
        .background(MegrumTheme.canvas)
    }

    private var bottomBarBottomPadding: CGFloat {
        bottomButton == nil && secondaryButton == nil ? 24 : 132
    }

    @ViewBuilder
    private var bottomBar: some View {
        if bottomButton != nil || secondaryButton != nil {
            VStack(spacing: 10) {
                if let bottomButton {
                    Button(action: bottomButtonAction) {
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
                    .disabled(bottomButtonDisabled)
                    .opacity(bottomButtonDisabled ? 0.48 : 1)
                    .accessibilityLabel(bottomButton)
                }

                if let secondaryButton {
                    Button(action: {}) {
                        Text(secondaryButton)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(secondaryButton)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}

struct HomeSelectedGoodsHeader: View {
    var title: String = "選んだグッズ"
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet
    var exchangeSummary: HomeDiscoveryOwnerExchangeSummary?
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }

    private let ownerColumnCloseButtonAlignmentOffset: CGFloat = -42

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                    .frame(width: 136, height: 162)

                VStack(alignment: .leading, spacing: 10) {
                    if let ownerSummary = goods.ownerSummary {
                        HomeOwnerAvatarButton(
                            owner: ownerSummary,
                            size: 46,
                            onOpenProfile: onOpenOwnerProfile
                        )
                        HomeUserSummary(owner: ownerSummary, onOpenProfile: onOpenOwnerProfile)
                    }

                    if let exchangeSummary {
                        HomeExchangeMethodBlock(summary: exchangeSummary)
                    }

                    HomePaymentBox(summaryText: goods.ownerPaymentSummaryText)
                }
                .padding(.top, 4)
                .offset(y: goods.ownerSummary == nil ? 0 : ownerColumnCloseButtonAlignmentOffset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct HomeSelectedGoodsSingleCard: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: goods,
            goodsCondition: conditionTags.goods,
            exchangeCondition: conditionTags.exchange,
            paymentCondition: conditionTags.payment,
            prominence: 1,
            showsConditionOverlay: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選んだグッズ")
    }
}

struct HomeOwnerAvatarButton: View {
    var owner: HomeDiscoveryGoodsOwnerSummary
    var size: CGFloat = 42
    var onOpenProfile: (UUID) -> Void

    var body: some View {
        Button {
            onOpenProfile(owner.id)
        } label: {
            HomeOwnerAvatar(owner: owner)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(owner.displayName)のプロフィールを開く")
    }
}

struct HomeOwnerAvatar: View {
    var owner: HomeDiscoveryGoodsOwnerSummary

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender.opacity(0.86), MegrumTheme.pink.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if let avatarURL = owner.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackInitial
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackInitial
                }
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.86), lineWidth: 1.2)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.16), radius: 8, y: 4)
    }

    private var fallbackInitial: some View {
        Text(owner.initial)
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
    }
}

struct HomeUserSummary: View {
    var owner: HomeDiscoveryGoodsOwnerSummary
    var onOpenProfile: (UUID) -> Void

    var body: some View {
        Button {
            onOpenProfile(owner.id)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(owner.displayName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                if !owner.genderAgeText.isEmpty {
                    Text(owner.genderAgeText)
                        .font(.system(size: 12.8, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                HStack(spacing: 6) {
                    Text(owner.evaluationText)
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("｜")
                        .foregroundStyle(MegrumTheme.muted.opacity(0.6))
                    Text(owner.tradeText)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .font(.system(size: 12.2, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(owner.displayName)のプロフィールを開く。\(owner.evaluationText)、\(owner.tradeText)")
    }
}

struct HomeExchangeMethodBlock: View {
    var summary: HomeDiscoveryOwnerExchangeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                Text(summary.methodTitle)
            }
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let detailText = summary.detailText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.top, 1)
                    Text(detailText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct HomePaymentBox: View {
    var summaryText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "yensign.circle")
                Text("支払い条件")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(summaryText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ok)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
