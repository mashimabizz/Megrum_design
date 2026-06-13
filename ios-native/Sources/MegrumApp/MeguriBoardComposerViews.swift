import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadComposerSheet: View {
    @ObservedObject var appState: MegrumAppState
    var coordinate: MegrumLocationCoordinate?
    var selectedPrefecture: String?

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var scope: BoardThread.Audience = .nearby3km

    init(
        appState: MegrumAppState,
        coordinate: MegrumLocationCoordinate?,
        selectedPrefecture: String?,
        initialScope: BoardThread.Audience = .nearby3km
    ) {
        self.appState = appState
        self.coordinate = coordinate
        self.selectedPrefecture = selectedPrefecture
        _scope = State(initialValue: initialScope)
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && missingContextMessage == nil
            && !appState.isCreatingBoardThread
    }

    private var missingContextMessage: String? {
        switch scope {
        case .nearby3km:
            if coordinate == nil {
                return "3km圏内のスレッドには現在地が必要です"
            }
            if selectedPrefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil,
               appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil {
                return "3km圏内のスレッドには都道府県設定が必要です"
            }
            return nil
        case .samePrefecture:
            if selectedPrefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil,
               appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil {
                return "都道府県を選択してください"
            }
            return nil
        case .sameSpot, .global:
            return "この公開範囲はまだ作成できません"
        }
    }

    private var submitLatitude: Double? {
        scope == .nearby3km ? coordinate?.latitude : nil
    }

    private var submitLongitude: Double? {
        scope == .nearby3km ? coordinate?.longitude : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("スレッドを立てる")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text("周辺の人と現地情報を共有できます")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Picker("公開範囲", selection: $scope) {
                    Text("3km圏内").tag(BoardThread.Audience.nearby3km)
                    Text(selectedPrefecture ?? appState.viewer?.prefecture ?? "都道府県").tag(BoardThread.Audience.samePrefecture)
                }
                .pickerStyle(.segmented)

                if let missingContextMessage {
                    MeguriNoticeBanner(message: missingContextMessage)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("タイトル")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    TextField("例：物販列どのくらい？", text: $title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(15)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("本文")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    ZStack(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("いま見えている状況や聞きたいことを書いてください")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.72))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                        }

                        TextEditor(text: $bodyText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 170)
                            .background(.clear)
                    }
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    let created = await appState.createBoardThread(
                        title: title,
                        body: bodyText,
                        scope: scope,
                        latitude: submitLatitude,
                        longitude: submitLongitude,
                        prefecture: selectedPrefecture
                    )
                    if created {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if appState.isCreatingBoardThread {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("作成する")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.48)
        }
        .navigationTitle("掲示板")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

struct BoardPrefecturePickerSheet: View {
    var selectedPrefecture: String?
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(japanesePrefectures, id: \.self) { prefecture in
            Button {
                onSelect(prefecture)
                dismiss()
            } label: {
                HStack {
                    Text(prefecture)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    if selectedPrefecture == prefecture {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(prefecture)を掲示板の都道府県に設定")
        }
        .navigationTitle("都道府県を選択")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}

private let japanesePrefectures = [
    "北海道",
    "青森県",
    "岩手県",
    "宮城県",
    "秋田県",
    "山形県",
    "福島県",
    "茨城県",
    "栃木県",
    "群馬県",
    "埼玉県",
    "千葉県",
    "東京都",
    "神奈川県",
    "新潟県",
    "富山県",
    "石川県",
    "福井県",
    "山梨県",
    "長野県",
    "岐阜県",
    "静岡県",
    "愛知県",
    "三重県",
    "滋賀県",
    "京都府",
    "大阪府",
    "兵庫県",
    "奈良県",
    "和歌山県",
    "鳥取県",
    "島根県",
    "岡山県",
    "広島県",
    "山口県",
    "徳島県",
    "香川県",
    "愛媛県",
    "高知県",
    "福岡県",
    "佐賀県",
    "長崎県",
    "熊本県",
    "大分県",
    "宮崎県",
    "鹿児島県",
    "沖縄県"
]
