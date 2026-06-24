import MegrumCore
import MegrumDesign
import SwiftUI

struct FaceTaggingResultRow: View {
    var result: FaceTaggingResult
    @Binding var draft: FaceTaggingCorrectionDraft
    var memberOptions: [FaceTaggingMemberOption]
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                FaceTaggingStatusChip(status: result.status)
                Spacer()
                Text(confidenceText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.muted)
            }

            if !result.candidates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(result.candidates) { candidate in
                            Button {
                                draft.selectedMemberID = candidate.memberID
                                draft.selectedMemberName = candidate.memberName
                            } label: {
                                Text("\(candidate.memberName) \(Int(candidate.confidence * 100))%")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(draft.selectedMemberID == candidate.memberID ? .white : MegrumTheme.lavender)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        draft.selectedMemberID == candidate.memberID ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.10),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else if let errorMessage = result.errorMessage {
                Text(errorMessage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
            }

            HStack(spacing: 10) {
                Menu {
                    Button("未設定") {
                        draft.selectedMemberID = nil
                        draft.selectedMemberName = nil
                    }
                    ForEach(memberOptions) { member in
                        Button(member.name) {
                            draft.selectedMemberID = member.memberID
                            draft.selectedMemberName = member.name
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(draft.selectedMemberName ?? "手動で選ぶ")
                            .font(.subheadline.weight(.black))
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(.white, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(Color.black.opacity(0.08))
                    }
                }
            }
        }
        .padding(14)
        .background(
            isSelected ? MegrumTheme.lavender.opacity(0.10) : .white,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? MegrumTheme.lavender.opacity(0.72) : Color.black.opacity(0.08))
        }
    }

    private var confidenceText: String {
        guard let confidence = result.confidence ?? result.candidates.first?.confidence else {
            return "候補なし"
        }
        return "\(Int(confidence * 100))%"
    }
}

private struct FaceTaggingStatusChip: View {
    var status: FaceMatchStatus

    var body: some View {
        Text(status.reviewTitle)
            .font(.caption.weight(.black))
            .foregroundStyle(status.reviewColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.reviewColor.opacity(0.12), in: Capsule())
    }
}

struct FaceTaggingEmptyState: View {
    var status: FaceMatchStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status == .noFace ? "顔を検出できませんでした" : "候補がありません")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("画像を変えるか、手動でメンバーを設定してください。")
                .font(.caption.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private extension FaceMatchStatus {
    var reviewTitle: String {
        switch self {
        case .autoMatched:
            "自動一致"
        case .needsReview:
            "確認必要"
        case .unknown:
            "不明"
        case .noFace:
            "顔なし"
        case .noSubject:
            "対象なし"
        case .lowQuality:
            "低品質"
        }
    }

    var reviewColor: Color {
        switch self {
        case .autoMatched:
            MegrumTheme.ok
        case .needsReview:
            MegrumTheme.lavender
        case .unknown, .noFace, .noSubject:
            MegrumTheme.muted
        case .lowQuality:
            MegrumTheme.pink
        }
    }
}
