import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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
