import MegrumCore
import MegrumDesign
import SwiftUI

/// ようこそ画面：スワイプできる3枚のスライドで、シンプルに価値を伝える。
struct AccountSetupWelcomeStep: View {
    @State private var slideIndex = 0

    private struct WelcomeSlide: Identifiable {
        let id: Int
        let systemImage: String
        let gradient: [Color]
        let title: String
        let message: String
        let tagline: String
    }

    private static let slides: [WelcomeSlide] = [
        WelcomeSlide(
            id: 0,
            systemImage: "arrow.left.arrow.right",
            gradient: [MegrumTheme.sky, MegrumTheme.lavender],
            title: "推し活グッズを、\nちゃんと交換。",
            message: "譲りたいものと ほしいものを登録するだけ。\nぴったりの交換相手が自動でみつかる。",
            tagline: "「探す」から「めぐりあう」へ"
        ),
        WelcomeSlide(
            id: 1,
            systemImage: "mappin.and.ellipse",
            gradient: [MegrumTheme.lavender, MegrumTheme.pink],
            title: "会って交換、\nだから安心。",
            message: "待ち合わせを決めてから交換成立。\n当日はチャットでスムーズに合流。",
            tagline: "現地交換にぴったりの流れ"
        ),
        WelcomeSlide(
            id: 2,
            systemImage: "heart.fill",
            gradient: [MegrumTheme.pink, MegrumTheme.sky],
            title: "めぐりで、\nゆるくつながる。",
            message: "近くのファンと写真やチャットで交流。\n気軽なひとことから、深いつながりまで。",
            tagline: "推し仲間が、すぐそばに"
        )
    ]

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $slideIndex) {
                ForEach(Self.slides) { slide in
                    slideView(slide)
                        .tag(slide.id)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .frame(height: 380)

            HStack(spacing: 7) {
                ForEach(Self.slides) { slide in
                    Capsule()
                        .fill(slide.id == slideIndex ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.22))
                        .frame(width: slide.id == slideIndex ? 22 : 7, height: 7)
                }
            }
            .animation(.snappy(duration: 0.22), value: slideIndex)
        }
        .padding(.top, 10)
    }

    private func slideView(_ slide: WelcomeSlide) -> some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradient.map { $0.opacity(0.16) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)
                    .shadow(color: slide.gradient[0].opacity(0.35), radius: 18, y: 10)

                Image(systemName: slide.systemImage)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Text(slide.message)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(slide.tagline)
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}

struct AccountSetupCompletionStep: View {
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var isSaving: Bool
    var errorMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                AccountSetupSummaryRow(title: "推し", value: selectedOshiDrafts.map(\.displayName).joined(separator: "、"))
                Divider()
                AccountSetupSummaryRow(title: "活動エリア", value: prefecture)
                Divider()
                AccountSetupSummaryRow(title: "名前", value: displayName)
                Divider()
                AccountSetupSummaryRow(title: "ユーザーID", value: "@\(MegrumAppStateInputNormalizer.profileHandle(handle) ?? handle)")
                Divider()
                AccountSetupSummaryRow(title: "生年月日", value: ProfileBirthDateCodec.string(from: birthDate) ?? "")
                Divider()
                AccountSetupSummaryRow(title: "性別", value: gender?.displayName ?? "")
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }

            if isSaving {
                ProgressView("保存しています")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tint(MegrumTheme.lavender)
            }

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 22)
    }
}

private struct AccountSetupFeatureRow: View {
    var systemImage: String
    var title: String
    var highlights: [AccountSetupFeatureHighlight]

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 68, height: 68)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(highlights) { highlight in
                        AccountSetupFeatureHighlightLabel(highlight: highlight)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AccountSetupFeatureHighlight: Identifiable, Equatable {
    enum Style: Equatable {
        case primary
        case accent
    }

    let id = UUID()
    var text: String
    var style: Style = .primary
}

private struct AccountSetupFeatureHighlightLabel: View {
    var highlight: AccountSetupFeatureHighlight

    var body: some View {
        Text(highlight.text)
            .font(.system(size: highlight.style == .accent ? 15 : 14, weight: .black, design: .rounded))
            .foregroundStyle(highlight.style == .accent ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.86))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
    }

    private var backgroundColor: Color {
        switch highlight.style {
        case .primary:
            Color.white.opacity(0.78)
        case .accent:
            MegrumTheme.lavender.opacity(0.11)
        }
    }

    private var borderColor: Color {
        switch highlight.style {
        case .primary:
            Color.black.opacity(0.05)
        case .accent:
            MegrumTheme.lavender.opacity(0.22)
        }
    }
}

private struct AccountSetupSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 82, alignment: .leading)
            Text(value.isEmpty ? "未設定" : value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
