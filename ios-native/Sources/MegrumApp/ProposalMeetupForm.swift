import Foundation
import MegrumDesign
import SwiftUI

struct ProposalMeetupForm: View {
    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("待ち合わせ候補")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                if isRequestingLocation {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            VStack(spacing: 0) {
                DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalMeetupRow()
                Divider()
                DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalMeetupRow()
                Divider()
                TextField("場所名", text: $placeName)
                    .proposalMeetupRow()
                Divider()
                HStack(spacing: 12) {
                    TextField("緯度", text: $latitudeText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("経度", text: $longitudeText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .proposalMeetupRow()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.68), lineWidth: 1)
            }

            if let locationErrorMessage {
                Text(locationErrorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

private extension View {
    func proposalMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}
