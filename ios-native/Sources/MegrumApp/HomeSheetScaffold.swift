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
                // iter1226.424：最上部からさらに下へは動かさない（バウンスで
                // シートを閉じるドラッグが奪われないように）。
                .megrumDisablesEnclosingScrollBounce()
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
                        Button {
                            MegrumHaptics.performButtonTap(wishCopyButtonAction)
                        } label: {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(MegrumTheme.lavender.opacity(wishCopyButtonDisabled ? 0.46 : 0.92), in: Circle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(wishCopyButtonDisabled)
                        .accessibilityLabel("ほしいものに追加")
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
                    Button {
                        MegrumHaptics.performButtonTap(bottomButtonAction)
                    } label: {
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
