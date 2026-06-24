import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BoardThreadTitleField: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タイトル")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            TextField("例：物販列どのくらい？", text: $title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .padding(15)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct BoardThreadBodyEditor: View {
    @Binding var bodyText: String

    var body: some View {
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
    }
}

struct BoardThreadThumbnailSection: View {
    @Binding var thumbnailItem: PhotosPickerItem?
    var hasThumbnail: Bool
    #if canImport(UIKit)
    var previewImage: UIImage?
    #endif
    var onRemoveThumbnail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("サムネイル")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 12) {
                #if canImport(UIKit)
                BoardThreadThumbnailPreview(previewImage: previewImage)
                #else
                BoardThreadThumbnailPreview()
                #endif

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $thumbnailItem, matching: .images) {
                        BoardThreadThumbnailPickerLabel(hasThumbnail: hasThumbnail)
                    }
                    .buttonStyle(.plain)

                    if hasThumbnail {
                        Button(action: onRemoveThumbnail) {
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
}

struct BoardThreadThumbnailPreview: View {
    #if canImport(UIKit)
    var previewImage: UIImage?
    #endif

    var body: some View {
        ZStack {
            #if canImport(UIKit)
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
        .frame(width: 78, height: 78)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.12))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}

struct BoardThreadComposerLocationStep: View {
    var title: String
    var summary: String
    var hasThumbnail: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    @Binding var selectedCoordinate: MegrumLocationCoordinate?
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onAppear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("最後に立てる場所を決める")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text("掲示板が地図上に表示される見え方を確認しながら、半径1km以内にピンを立ててください。")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            BoardThreadDraftMapPreview(
                title: title,
                summary: summary,
                hasThumbnail: hasThumbnail
            )

            MeguriCreationLocationPicker(
                title: "地図での表示プレビュー",
                subtitle: "現在地から半径1km以内の地図上をタップして選択",
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                preview: .board(
                    title: title,
                    summary: summary,
                    hasThumbnail: hasThumbnail
                ),
                selectedCoordinate: $selectedCoordinate,
                onRequestLocation: onRequestLocation,
                onOutOfRange: onOutOfRange
            )
        }
        .padding(14)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear(perform: onAppear)
    }
}
