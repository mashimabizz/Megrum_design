import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriScreen: View {
    var grooms: [GroomPost]
    var threads: [BoardThread]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                ScreenTitle(title: "グルーム", subtitle: "近くの投稿と掲示板")

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "グルーム", actionTitle: "地図で見る")
                    GroomStrip(grooms: grooms)
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "掲示板", actionTitle: "地図で見る")

                    ForEach(threads) { thread in
                        BoardThreadCard(thread: thread)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button {
            } label: {
                Label("スレッドを立てる", systemImage: "plus")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
        }
    }
}

private struct SectionHeader: View {
    var title: String
    var actionTitle: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button(actionTitle) {
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct GroomStrip: View {
    var grooms: [GroomPost]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(grooms) { groom in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MegrumTheme.sky, MegrumTheme.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        Text("1km圏内")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .id(groom.id)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct BoardThreadCard: View {
    var thread: BoardThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scopeText)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                Spacer()
            }

            Text(thread.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(thread.body)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(16)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 14, y: 7)
    }

    private var scopeText: String {
        switch thread.audience {
        case .nearby3km:
            "3km圏内"
        case .prefecture:
            thread.prefecture ?? "都道府県"
        }
    }
}
