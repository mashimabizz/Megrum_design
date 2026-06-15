import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BoardThreadComposerSheet: View {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var fallbackCoordinate: MegrumLocationCoordinate?
    var selectedPrefecture: String?
    var onCreated: (BoardThread) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var thumbnailItem: PhotosPickerItem?
    @State private var thumbnailUpload: GoodsPhotoUpload?
    @State private var thumbnailErrorMessage: String?
    #if canImport(UIKit)
    @State private var thumbnailPreviewImage: UIImage?
    #endif

    init(
        appState: MegrumAppState,
        locationState: MegrumLocationState,
        fallbackCoordinate: MegrumLocationCoordinate? = nil,
        selectedPrefecture: String?,
        onCreated: @escaping (BoardThread) -> Void = { _ in }
    ) {
        self.appState = appState
        self.locationState = locationState
        self.fallbackCoordinate = fallbackCoordinate
        self.selectedPrefecture = selectedPrefecture
        self.onCreated = onCreated
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && missingContextMessage == nil
            && !appState.isCreatingBoardThread
    }

    private var missingContextMessage: String? {
        if submitScope == .samePrefecture && submitPrefecture == nil {
            return "プロフィールの都道府県を設定してください"
        }
        return thumbnailErrorMessage
    }

    private var submitLatitude: Double? {
        submitScope == .nearby3km ? submitCoordinate?.latitude : nil
    }

    private var submitLongitude: Double? {
        submitScope == .nearby3km ? submitCoordinate?.longitude : nil
    }

    private var submitScope: BoardThread.Audience {
        submitCoordinate == nil ? .samePrefecture : .nearby3km
    }

    private var submitCoordinate: MegrumLocationCoordinate? {
        locationState.coordinate ?? fallbackCoordinate
    }

    private var submitPrefecture: String? {
        selectedPrefecture.nilIfBlank
            ?? (appState.viewer?.prefecture).nilIfBlank
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

                if let missingContextMessage {
                    MeguriNoticeBanner(message: missingContextMessage)
                }

                thumbnailPickerSection

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
                    let created = await appState.createBoardThreadRecord(
                        title: title,
                        body: bodyText,
                        scope: submitScope,
                        latitude: submitLatitude,
                        longitude: submitLongitude,
                        prefecture: submitPrefecture,
                        thumbnailUpload: thumbnailUpload
                    )
                    if let created {
                        onCreated(created)
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
        .onChange(of: thumbnailItem) { _, item in
            loadThumbnail(item)
        }
        .task {
            if submitCoordinate == nil {
                locationState.requestCurrentLocation()
            }
        }
    }

    private var thumbnailPickerSection: some View {
        let hasThumbnail = thumbnailUpload != nil
        return VStack(alignment: .leading, spacing: 8) {
            Text("サムネイル")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 12) {
                thumbnailPreview

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $thumbnailItem, matching: .images) {
                        BoardThreadThumbnailPickerLabel(hasThumbnail: hasThumbnail)
                    }
                    .buttonStyle(.plain)

                    if thumbnailUpload != nil {
                        Button {
                            thumbnailItem = nil
                            thumbnailUpload = nil
                            thumbnailErrorMessage = nil
                            #if canImport(UIKit)
                            thumbnailPreviewImage = nil
                            #endif
                        } label: {
                            Label("削除", systemImage: "xmark.circle")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var thumbnailPreview: some View {
        ZStack {
            #if canImport(UIKit)
            if let thumbnailPreviewImage {
                Image(uiImage: thumbnailPreviewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                thumbnailFallback
            }
            #else
            thumbnailFallback
            #endif
        }
        .frame(width: 78, height: 78)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var thumbnailFallback: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.12))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }

    private func loadThumbnail(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    thumbnailErrorMessage = "サムネイルを読み込めませんでした"
                }
                return
            }
            let upload = normalizedPhotoUpload(from: data)
            await MainActor.run {
                if upload.data.count > goodsEditorMaxPhotoUploadBytes {
                    thumbnailErrorMessage = "サムネイルは10MB以下にしてください"
                    thumbnailUpload = nil
                    #if canImport(UIKit)
                    thumbnailPreviewImage = nil
                    #endif
                    return
                }
                thumbnailUpload = upload
                thumbnailErrorMessage = nil
                #if canImport(UIKit)
                thumbnailPreviewImage = UIImage(data: upload.data)
                #endif
            }
        }
    }
}

private struct BoardThreadThumbnailPickerLabel: View {
    var hasThumbnail: Bool

    var body: some View {
        Label(hasThumbnail ? "写真を変更" : "写真を選ぶ", systemImage: "photo")
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(.white.opacity(0.9), in: Capsule())
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
