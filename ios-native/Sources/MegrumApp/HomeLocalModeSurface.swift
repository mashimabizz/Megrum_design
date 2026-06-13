import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeLocalModeSurface: View {
    var viewer: UserProfile?
    var settings: HomeLocalActivitySettings
    var carryingCandidates: [HomeLocalCarryingCandidate]
    var isLoadingSettings = false
    var isSavingSettings = false
    var onEdit: () -> Void

    var body: some View {
        let now = Date()
        let status = settings.status(now: now)
        let carryingSummary = settings.carryingSummary(from: carryingCandidates)
        let publicPreview = settings.publicPreview(
            now: now,
            fallbackPrefecture: viewer?.prefecture,
            carryingSummary: carryingSummary
        )

        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    HomeLocalStatusBadge(status: status)
                    Spacer(minLength: 12)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("現地交換")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(settings.displayVenue(fallbackPrefecture: viewer?.prefecture))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    HomeLocalMetricChip(systemImage: "clock", text: settings.timeWindowText(now: now))
                    HomeLocalMetricChip(systemImage: "scope", text: settings.radiusText)
                    HomeLocalMetricChip(systemImage: "bag", text: carryingSummary.countText)
                }

                HomeLocalPublicPreviewRow(preview: publicPreview)

                if isLoadingSettings || isSavingSettings {
                    HomeLocalSyncStatusRow(isLoading: isLoadingSettings, isSaving: isSavingSettings)
                }

                if settings.isEnabled {
                    Text(carryingSummary.titleText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        status.isLive ? MegrumTheme.lavender.opacity(0.5) : Color.white.opacity(0.7),
                        lineWidth: 1
                    )
            }
            .shadow(color: MegrumTheme.ink.opacity(status.isLive ? 0.13 : 0.07), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("現地交換モード")
        .accessibilityValue("\(status.label)、\(publicPreview.title)、\(settings.timeWindowText(now: Date()))、\(settings.radiusText)、\(carryingSummary.countText)")
    }
}
