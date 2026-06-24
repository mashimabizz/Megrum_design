import MegrumDesign
import SwiftUI

struct AnchoredDestructiveConfirmationPopover: View {
    var title: String
    var message: String?
    var destructiveTitle: String
    var cancelTitle: String = "キャンセル"
    var onCancel: () -> Void
    var onConfirm: () -> Void
    var isConfirmEnabled: Bool = true
    var showsArrow: Bool = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if showsArrow {
                CalloutArrow()
                    .fill(OshiSettingsConfirmationPalette.surface)
                    .overlay {
                        CalloutArrow()
                            .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.4)
                    }
                    .frame(width: 32, height: 18)
                    .padding(.trailing, 20)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: -1)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let message {
                        Text(message)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(.white.opacity(0.72), in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: onConfirm) {
                        Text(destructiveTitle)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(OshiSettingsConfirmationPalette.warn, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isConfirmEnabled)
                    .opacity(isConfirmEnabled ? 1 : 0.58)
                }
            }
            .padding(14)
            .frame(width: 232)
            .background(OshiSettingsConfirmationPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
        }
        .frame(width: 232)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

private enum OshiSettingsConfirmationPalette {
    static let warn = Color(red: 0.84, green: 0.46, blue: 0.36)
    static let surface = Color.white.opacity(0.94)
}

private struct CalloutArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
