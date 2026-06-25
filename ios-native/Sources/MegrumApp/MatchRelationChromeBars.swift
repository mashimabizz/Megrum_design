import MegrumDesign
import SwiftUI

struct MatchRelationBottomBar: View {
    var senderCount: Int
    var receiverCount: Int
    var isEnabled: Bool
    var showsReset: Bool
    var onSecondary: () -> Void
    var onStart: () -> Void

    var body: some View {
        let totalSelectionCount = max(senderCount, receiverCount)
        HStack(spacing: 10) {
            secondaryButton
            primaryButton(totalSelectionCount: totalSelectionCount)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: -4)
    }

    private var secondaryButton: some View {
        Button(action: onSecondary) {
            Text(MatchRelationBottomBarCopy.secondaryTitle(showsReset: showsReset))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 92)
                .frame(height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(totalSelectionCount: Int) -> some View {
        Button(action: onStart) {
            Text(
                MatchRelationBottomBarCopy.primaryTitle(
                    isEnabled: isEnabled,
                    showsReset: showsReset,
                    totalSelectionCount: totalSelectionCount
                )
            )
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(MegrumTheme.lavender.opacity(isEnabled ? 1 : 0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MegrumTheme.lavender.opacity(isEnabled ? 0.24 : 0), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct MatchRelationHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            closeButton

            Text("関係図")
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 56, height: 56)
                .background(.white, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

enum MatchRelationVisual {
    static let background = Color(red: 0.984, green: 0.976, blue: 0.988)
}
