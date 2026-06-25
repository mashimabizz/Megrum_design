import MegrumDesign
import SwiftUI

struct MeguriCreationLocationPickerHeader: View {
    var title: String
    var subtitle: String
    var isRequestingLocation: Bool
    var onRequestLocation: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onRequestLocation) {
                Group {
                    if isRequestingLocation {
                        ProgressView()
                            .controlSize(.small)
                            .tint(MegrumTheme.lavender)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .black))
                    }
                }
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("現在地に戻る")
        }
    }
}

struct MeguriCreationMissingLocationView: View {
    var isRequestingLocation: Bool
    var onRequestLocation: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text("現在地を確認すると作成場所を選べます")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Button(action: onRequestLocation) {
                Text(isRequestingLocation ? "確認中" : "現在地を確認")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 38)
                    .background(MegrumTheme.lavender, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isRequestingLocation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.lavender.opacity(0.08))
    }
}

struct MeguriCreationLocationCaption: View {
    var selectionCaption: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)

            Text(selectionCaption)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))

            Spacer(minLength: 0)
        }
    }
}
