import Foundation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCardSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 0)
                if let rightText, !rightText.isEmpty {
                    Text(rightText)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            content
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}

struct ProposalConfirmSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 0)
                if let rightText, !rightText.isEmpty {
                    Text(rightText)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            content
        }
    }
}

struct ProposalConfirmStepView: View {
    var requiresMeetupBeforeSubmit: Bool
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var meetupInputs: [ProposalMeetupInput]
    @Binding var message: String
    var messageLimit: Int
    @Binding var shareSchedule: Bool
    var errorMessage: String?
    var onOpenAddressSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(ProposalConfirmSectionKind.visibleOrder(requiresMeetupBeforeSubmit: requiresMeetupBeforeSubmit)) { section in
                confirmSection(section)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func confirmSection(_ section: ProposalConfirmSectionKind) -> some View {
        switch section {
        case .exchangeContent:
            ProposalConfirmSection(title: "交換内容") {
                ProposalExchangePreviewRow(
                    senderGoods: senderGoods,
                    receiverGoods: receiverGoods
                )
            }
        case .method:
            ProposalConfirmMethodCard(
                exchangeMethod: exchangeMethod,
                mailingAddress: mailingAddress,
                isLoadingMailingAddress: isLoadingMailingAddress,
                onOpenAddressSettings: onOpenAddressSettings
            )
        case .meetupCandidates:
            ProposalConfirmMeetupCandidatesCard(candidates: meetupInputs)
        case .message:
            ProposalConfirmSection(title: "メッセージ（任意）", rightText: "\(message.count) / \(messageLimit)") {
                TextField("よろしくお願いします", text: $message, axis: .vertical)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(3...6)
                    .padding(12)
                    .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        case .scheduleShare:
            ProposalScheduleShareCard(shareSchedule: $shareSchedule)
        }
    }
}

struct ProposalScheduleShareCard: View {
    @Binding var shareSchedule: Bool

    var body: some View {
        HStack(spacing: ProposalScheduleShareMetrics.cardGap) {
            VStack(alignment: .leading, spacing: ProposalScheduleShareMetrics.statusTopSpacing) {
                Text("スケジュールを共有する")
                    .font(.system(size: ProposalScheduleShareMetrics.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(shareSchedule ? "ON" : "OFF")
                    .font(.system(size: ProposalScheduleShareMetrics.statusFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(shareSchedule ? MegrumTheme.lavender : MegrumTheme.muted)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $shareSchedule)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(ProposalScheduleShareMetrics.cardPadding)
        .background(
            shareSchedule ? MegrumTheme.lavender.opacity(ProposalScheduleShareMetrics.activeBackgroundOpacity) : Color.white,
            in: RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous)
                .stroke(
                    shareSchedule
                        ? MegrumTheme.lavender.opacity(ProposalScheduleShareMetrics.activeBorderOpacity)
                        : MegrumTheme.ink.opacity(ProposalScheduleShareMetrics.inactiveBorderOpacity),
                    lineWidth: 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: ProposalScheduleShareMetrics.cardCornerRadius, style: .continuous))
        .onTapGesture {
            shareSchedule.toggle()
        }
    }
}

struct ProposalConfirmSummary: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalExchangePreviewRow(
                senderGoods: senderGoods,
                receiverGoods: receiverGoods
            )
            ProposalSummaryRow(title: "交換方法", value: methodTitle)
            ProposalSummaryRow(title: "待ち合わせ", value: meetupSummary)
            if !conditionTags.isEmpty {
                ProposalSummaryRow(title: "条件タグ", value: conditionTags.joined(separator: " / "))
            }
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
        }
    }
}

struct ProposalConfirmMeetupCandidatesCard: View {
    var candidates: [ProposalMeetupInput]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ProposalCardSection(title: ProposalConfirmSectionCopy.meetupCandidatesTitle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("待ち合わせ候補")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(candidates.count)件")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                }

                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { index, candidate in
                        Marker("候補\(index + 1)", coordinate: CLLocationCoordinate2D(latitude: candidate.latitude, longitude: candidate.longitude))
                            .tint(index == 0 ? MegrumTheme.lavender : MegrumTheme.sky)
                    }
                }
                .frame(height: 204)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                }

                VStack(spacing: 10) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { index, candidate in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(index == 0 ? MegrumTheme.lavender : MegrumTheme.sky, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(timeText(for: candidate))
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(1)
                                Text(candidate.normalizedPlaceName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .onAppear {
            syncCameraPosition()
        }
        .onChange(of: candidates) { _, _ in
            syncCameraPosition()
        }
    }

    private func timeText(for candidate: ProposalMeetupInput) -> String {
        let start = candidate.startAt.formatted(.dateTime.locale(Locale(identifier: "ja_JP")).month().day().hour().minute())
        let end = candidate.endAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
    }

    private func syncCameraPosition() {
        guard let region = ProposalMeetupMapRegionBuilder.region(for: candidates) else {
            cameraPosition = .automatic
            return
        }
        cameraPosition = .region(region)
    }
}

struct ProposalExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ProposalPreviewSide(title: "相手の譲", goods: receiverGoods)
            VStack(spacing: 4) {
                ProposalArrowDot(symbolName: "arrow.right", color: MegrumTheme.lavender)
                ProposalArrowDot(symbolName: "arrow.left", color: MegrumTheme.sky)
            }
            .padding(.top, 24)
            ProposalPreviewSide(title: "あなたの譲", goods: senderGoods, alignRight: true, isMine: true)
        }
        .padding(10)
        .background(MegrumTheme.sky.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProposalPreviewSide: View {
    var title: String
    var goods: [GoodsItem]
    var alignRight = false
    var isMine = false

    var body: some View {
        VStack(alignment: alignRight ? .trailing : .leading, spacing: 8) {
            Text("\(title)（\(goods.count)）")
                .font(.system(size: 10.5, weight: .black, design: .rounded))
                .foregroundStyle(isMine ? MegrumTheme.lavender : MegrumTheme.sky)
            LazyVGrid(
                columns: ProposalExchangePreviewMetrics.thumbGridColumns,
                alignment: alignRight ? .trailing : .leading,
                spacing: ProposalExchangePreviewMetrics.thumbSpacing
            ) {
                ForEach(goods.prefix(4)) { item in
                    ProposalPreviewThumb(item: item)
                }
            }
            .frame(maxWidth: .infinity, alignment: alignRight ? .trailing : .leading)
        }
        .padding(9)
        .frame(minHeight: 108, alignment: .top)
        .frame(maxWidth: .infinity)
        .background((isMine ? MegrumTheme.pink : Color.white).opacity(isMine ? 0.08 : 0.9), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct ProposalArrowDot: View {
    var symbolName: String
    var color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            }
    }
}

private struct ProposalPreviewThumb: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: 44, height: 44)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallback
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        @unknown default:
                            fallback
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(.white.opacity(0.8), lineWidth: 1)
            }
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 30, height: 30)
                .offset(x: -11, y: -12)
            Text(ProposalPreviewGlyphResolver.glyph(for: item.title))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
    }
}

enum ProposalPreviewGlyphResolver {
    static func glyph(for title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.contains("カリナ") {
            return "K"
        }
        if trimmedTitle.contains("ジョンウ") {
            return "J"
        }
        if trimmedTitle.contains("スア") {
            return "S"
        }
        if trimmedTitle.contains("ニンニン") {
            return "N"
        }
        guard let firstCharacter = trimmedTitle.first else {
            return "?"
        }
        return String(firstCharacter)
    }
}

struct ProposalConfirmMethodCard: View {
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var onOpenAddressSettings: () -> Void

    var body: some View {
        ProposalConfirmSection(title: "受け渡し方法") {
            VStack(alignment: .leading, spacing: 12) {
                Text(exchangeMethod.displayName)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                if exchangeMethod == .mail || exchangeMethod == .both {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("あなたの住所登録")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        if isLoadingMailingAddress {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("確認中")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        } else if let mailingAddress {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(mailingAddress.summary)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button(action: onOpenAddressSettings) {
                                    Label("変更する", systemImage: "pencil")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(MegrumTheme.lavender)
                                        .padding(.horizontal, 12)
                                        .frame(height: 32)
                                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("住所変更画面を開きます")
                            }
                        } else {
                            HStack(spacing: 10) {
                                Text("未登録")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                                Button(action: onOpenAddressSettings) {
                                    Text("登録する")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .frame(height: 32)
                                        .background(MegrumTheme.lavender, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

}

private struct ProposalSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 92, alignment: .leading)
            Text(value.isEmpty ? "未選択" : value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}
