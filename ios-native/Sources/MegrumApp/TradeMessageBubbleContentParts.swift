import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct TradePhotoMessageBubble: View {
    var message: TradeMessage
    var photoURL: URL?
    var onOpenImage: (URL) -> Void

    private var thumbnailSize: CGSize {
        TradePhotoMessageLayout.thumbnailSize(for: message.messageType)
    }

    var body: some View {
        Group {
            if let photoURL {
                Button {
                    onOpenImage(photoURL)
                } label: {
                    thumbnailContent(photoURL: photoURL)
                }
                .buttonStyle(.plain)
            } else {
                unavailableThumbnail
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func thumbnailContent(photoURL: URL) -> some View {
        Group {
            if photoURL.isFileURL {
                LocalURLImage(url: photoURL, contentMode: .fill) {
                    photoPlaceholderContent
                }
            } else {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        photoPlaceholderContent
                    case .empty:
                        MegrumTheme.sky.opacity(0.12)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        Color.clear
                    }
                }
            }
        }
        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let label = photoLabel {
                Label(label, systemImage: "photo.fill")
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.46), in: Capsule())
                    .padding(7)
            }
        }
    }

    private var unavailableThumbnail: some View {
        photoPlaceholderContent
            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
    }

    private var photoPlaceholderContent: some View {
        MegrumTheme.sky.opacity(0.16)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .bold))
                    Text("写真")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.muted)
            }
    }

    private var photoLabel: String? {
        TradePhotoMessageLayout.label(for: message.messageType)
    }

    private var accessibilityLabel: String {
        let label = photoLabel ?? "取引チャットの写真"
        return photoURL == nil ? "\(label)を表示できません" : "\(label)を拡大表示"
    }
}

struct TradeRichOperationalMessageBubble: View {
    var title: String
    var systemImage: String
    var messageBody: String
    var detail: String?
    var isMine: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isMine ? .white.opacity(0.86) : MegrumTheme.lavender)
            Text(messageBody)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMine ? .white.opacity(0.78) : MegrumTheme.muted)
            }
        }
        .foregroundStyle(isMine ? .white : MegrumTheme.ink)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

struct TradeLocationPreviewBubble: View {
    var presentation: TradeOperationalMessagePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let coordinate {
                    Map(initialPosition: .region(mapRegion(for: coordinate))) {
                        Marker(presentation.title, systemImage: "location.fill", coordinate: coordinate)
                            .tint(MegrumTheme.lavender)
                    }
                    .allowsHitTesting(false)
                    .mapControlVisibility(.hidden)
                    .overlay {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.16)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.91, blue: 0.82),
                            Color(red: 0.8, green: 0.88, blue: 0.96),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    TradeLocationMapGrid()

                    Circle()
                        .fill(MegrumTheme.lavender)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Text("!")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 8, y: 3)
                }
            }
            .frame(height: 132)

            VStack(alignment: .leading, spacing: 5) {
                Label(presentation.title, systemImage: presentation.systemImage)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text(presentation.body)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text("地図アプリで開く →")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.94))
        }
        .frame(width: 262)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.05), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.title)。\(presentation.body)")
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude = presentation.latitude,
              let longitude = presentation.longitude,
              latitude.isFinite,
              longitude.isFinite
        else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func mapRegion(for coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    }
}

private struct TradeLocationMapGrid: View {
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.56))
                    .frame(width: 230, height: 5)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -14 : 16))
                    .offset(y: CGFloat(index - 2) * 22)
            }
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(MegrumTheme.sky.opacity(0.36))
                    .frame(width: 5, height: 150)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? 32 : -28))
                    .offset(x: CGFloat(index - 1) * 44)
            }
        }
    }
}

struct TradeTextMessageBubble: View {
    var text: String
    var isMine: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            compactBubble
            wrappedBubble
        }
    }

    private var compactBubble: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(isMine ? .white : MegrumTheme.ink)
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private var wrappedBubble: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(isMine ? .white : MegrumTheme.ink)
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 272, alignment: isMine ? .trailing : .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}
