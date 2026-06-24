import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationWishBottomSheet: View {
    var target: MatchRelationWishPopupTarget
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void
    var onClose: () -> Void

    private var candidateAccent: Color {
        target.viewpoint == .mine ? MegrumTheme.pink : MegrumTheme.lavender
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.56)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    Text("🎯")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(target.wish.item.title)
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(MatchRelationPopupCopy.subtitle(
                            quantity: target.wish.quantity,
                            candidateCount: target.wish.candidates.count
                        ))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button(action: onClose) {
                        Text("×")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 28, height: 28)
                            .background(MegrumTheme.ink.opacity(0.04), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MatchRelationVisual.background)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(MegrumTheme.ink.opacity(0.04))
                        .frame(height: 1)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .center, spacing: 0) {
                        MatchRelationGoodsThumbnail(item: target.wish.item, size: 104)
                        Text(target.exchangeType.displayName)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MegrumTheme.lavender, in: Capsule())
                            .padding(.top, 7)
                        Text(MatchRelationPopupCopy.fallbackTitle(target.fallbackHave.item.title))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .padding(.top, 5)
                    }
                    .frame(width: 110, alignment: .top)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            MatchRelationMiniAvatar(
                                title: target.viewpoint == .mine ? "@\(partnerHandle)" : "あなた",
                                color: candidateAccent
                            )
                            Text(MatchRelationPopupCopy.candidateOwnerTitle(
                                viewpoint: target.viewpoint,
                                partnerHandle: partnerHandle
                            ))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(candidateAccent)
                                .lineLimit(1)
                            Text("（タップで選択）")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                            alignment: .leading,
                            spacing: 6
                        ) {
                            ForEach(target.wish.candidates) { candidate in
                                MatchRelationPopupCandidateButton(
                                    candidate: candidate,
                                    isSelected: selectedCandidateIDs.contains(candidate.item.id),
                                    isHighlighted: candidate.item.id == highlightedItemID,
                                    onTap: {
                                        onToggleCandidate(candidate.item.id)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(12)

                Button(action: onClose) {
                    Text("戻る")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 40, y: -10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MatchRelationMiniAvatar: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title.prefix(1).uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(color, in: Circle())
    }
}

private struct MatchRelationPopupCandidateButton: View {
    var candidate: MatchRelationCandidate
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .center, spacing: 0) {
                    MatchRelationGoodsThumbnail(item: candidate.item, size: 56)

                    Text(candidate.item.title)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .frame(maxWidth: 64)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if isHighlighted {
                    Text("選択元")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(MegrumTheme.pink, in: Capsule())
                        .offset(x: -8, y: -8)
                }

                if isSelected {
                    Text("✓")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(MegrumTheme.lavender, in: Circle())
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .offset(x: 8, y: -8)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 82, alignment: .top)
            .background(
                isHighlighted
                    ? Color(red: 1, green: 247 / 255, blue: 251 / 255)
                    : (isSelected ? MegrumTheme.lavender.opacity(0.08) : .white),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? MegrumTheme.pink : (isSelected ? MegrumTheme.lavender : .clear),
                        lineWidth: isHighlighted || isSelected ? 2 : 0
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct MatchRelationBottomBar: View {
    var senderCount: Int
    var receiverCount: Int
    var isEnabled: Bool
    var showsReset: Bool
    var onSecondary: () -> Void
    var onStart: () -> Void

    var body: some View {
        let totalSelectionCount = max(senderCount, receiverCount)
        HStack(spacing: 10) {
            Button(action: onSecondary) {
                Text(MatchRelationBottomBarCopy.secondaryTitle(showsReset: showsReset))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 92)
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button(action: onStart) {
                Text(
                    MatchRelationBottomBarCopy.primaryTitle(
                        isEnabled: isEnabled,
                        showsReset: showsReset,
                        totalSelectionCount: totalSelectionCount
                    )
                )
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender.opacity(isEnabled ? 1 : 0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: MegrumTheme.lavender.opacity(isEnabled ? 0.24 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: -4)
    }
}

struct MatchRelationHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 56, height: 56)
                    .background(.white, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Text("関係図")
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.06))
                .frame(height: 1)
        }
    }
}

enum MatchRelationVisual {
    static let background = Color(red: 0.984, green: 0.976, blue: 0.988)
}
