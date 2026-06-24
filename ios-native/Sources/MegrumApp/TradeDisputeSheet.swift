import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDisputeSheet: View {
    @State private var category: TradeDisputeCategory = .wrong
    @State private var factMemo = ""
    var isSubmitting: Bool
    var onSubmit: (TradeDisputeCategory, String) async -> Void

    private var trimmedFactMemo: String {
        factMemo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                Picker("理由", selection: $category) {
                    ForEach(TradeDisputeCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
            } header: {
                Text("申告理由")
            }

            Section {
                TextEditor(text: $factMemo)
                    .frame(minHeight: 140)
                    .overlay(alignment: .topLeading) {
                        if factMemo.isEmpty {
                            Text("何が起きたかを具体的に入力してください")
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("内容")
            } footer: {
                Text("写真や証跡は取引チャット上の共有内容と合わせて運営が確認します。")
            }
        }
        .navigationTitle("通報")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await onSubmit(category, trimmedFactMemo)
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(isSubmitting || trimmedFactMemo.isEmpty)
            }
        }
    }
}
