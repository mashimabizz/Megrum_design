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
