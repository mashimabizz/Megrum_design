import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct FaceTaggingMemberOption: Identifiable, Equatable, Sendable {
    var id: UUID { memberID }
    var memberID: UUID
    var name: String
    var detail: String?

    init(memberID: UUID, name: String, detail: String? = nil) {
        self.memberID = memberID
        self.name = name
        self.detail = detail
    }
}

struct FaceTaggingCorrectionDraft: Identifiable, Equatable, Sendable {
    var id: UUID
    var resultID: UUID
    var imageType: MemberTaggingImageType
    var subjectType: MemberTaggingSubjectType
    var recognitionMethod: MemberTaggingRecognitionMethod
    var profileType: MemberProfileType?
    var selectedMemberID: UUID?
    var selectedMemberName: String?
    var shouldAddTrainingData: Bool

    init(result: FaceTaggingResult) {
        self.id = UUID()
        self.resultID = result.id
        self.imageType = result.imageType
        self.subjectType = result.subjectType
        self.recognitionMethod = result.recognitionMethod
        self.profileType = result.profileType
        self.selectedMemberID = result.matchedMemberID ?? result.candidates.first?.memberID
        self.selectedMemberName = result.matchedMemberName ?? result.candidates.first?.memberName
        self.shouldAddTrainingData = true
    }
}

struct FaceTaggingReviewSheet: View {
    var imageData: Data
    var analysis: FaceTaggingAnalysis
    var memberOptions: [FaceTaggingMemberOption]
    var onSave: ([FaceTaggingCorrectionDraft]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [FaceTaggingCorrectionDraft]
    @State private var selectedResultID: UUID?

    init(
        imageData: Data,
        analysis: FaceTaggingAnalysis,
        memberOptions: [FaceTaggingMemberOption],
        onSave: @escaping ([FaceTaggingCorrectionDraft]) -> Void
    ) {
        self.imageData = imageData
        self.analysis = analysis
        self.memberOptions = memberOptions
        self.onSave = onSave
        _drafts = State(initialValue: analysis.results.map(FaceTaggingCorrectionDraft.init(result:)))
        _selectedResultID = State(initialValue: analysis.results.first?.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FaceTaggingImagePreview(imageData: imageData)
                        .frame(height: 260)

                    if analysis.results.isEmpty {
                        FaceTaggingEmptyState(status: analysis.status)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("メンバー候補")
                                .font(.headline.weight(.black))
                                .foregroundStyle(MegrumTheme.ink)

                            ForEach(analysis.results) { result in
                                if let draftBinding = binding(forResultID: result.id) {
                                    FaceTaggingResultRow(
                                        result: result,
                                        draft: draftBinding,
                                        memberOptions: memberOptions,
                                        isSelected: selectedResultID == result.id
                                    )
                                    .onTapGesture {
                                        selectedResultID = result.id
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("メンバー候補を確認")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(drafts)
                        dismiss()
                    }
                    .disabled(analysis.results.isEmpty)
                }
            }
        }
    }

    private func binding(forResultID resultID: UUID) -> Binding<FaceTaggingCorrectionDraft>? {
        guard let index = drafts.firstIndex(where: { $0.resultID == resultID }) else {
            return nil
        }
        return Binding(
            get: { drafts[index] },
            set: { drafts[index] = $0 }
        )
    }
}

private struct FaceTaggingImagePreview: View {
    var imageData: Data

    private var imageSize: CGSize? {
        faceReviewPlatformImageSize(from: imageData)
    }

    var body: some View {
        GeometryReader { proxy in
            let displayRect = faceReviewFittedImageRect(
                imageSize: imageSize ?? CGSize(width: 1, height: 1),
                containerSize: proxy.size
            )

            ZStack {
                Color.black.opacity(0.06)

                FaceTaggingSourceImage(data: imageData)
                    .frame(width: displayRect.width, height: displayRect.height)
                    .position(x: displayRect.midX, y: displayRect.midY)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
    }
}

private struct FaceTaggingSourceImage: View {
    var data: Data

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            FaceTaggingImagePlaceholder()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            FaceTaggingImagePlaceholder()
        }
        #else
        FaceTaggingImagePlaceholder()
        #endif
    }
}

private struct FaceTaggingImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.white)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
    }
}

private struct FaceTaggingResultRow: View {
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
        .background(isSelected ? MegrumTheme.lavender.opacity(0.10) : .white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

private struct FaceTaggingEmptyState: View {
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

private func faceReviewPlatformImageSize(from data: Data) -> CGSize? {
    #if canImport(UIKit)
    UIImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #elseif canImport(AppKit)
    NSImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #else
    nil
    #endif
}

private func faceReviewFittedImageRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
        return CGRect(origin: .zero, size: containerSize)
    }
    let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return CGRect(
        x: (containerSize.width - size.width) / 2,
        y: (containerSize.height - size.height) / 2,
        width: size.width,
        height: size.height
    )
}
