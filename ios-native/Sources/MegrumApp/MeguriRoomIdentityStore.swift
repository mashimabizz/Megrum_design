import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// チャットルーム（掲示板スレッド）ごとの自分の名前・アイコンをローカル保存する。
/// 参加時に決めたアイデンティティを次回以降の返信でも使い回すためのもの。
enum MeguriRoomIdentityStore {
    struct Identity: Codable, Equatable {
        var displayName: String
        var avatarID: String
    }

    static func key(threadID: UUID, userID: UUID) -> String {
        "meguri.room.identity.\(userID.uuidString.lowercased()).\(threadID.uuidString.lowercased())"
    }

    static func load(threadID: UUID, userID: UUID, defaults: UserDefaults = .standard) -> Identity? {
        guard let data = defaults.data(forKey: key(threadID: threadID, userID: userID)) else {
            return nil
        }
        return try? JSONDecoder().decode(Identity.self, from: data)
    }

    static func save(_ identity: Identity, threadID: UUID, userID: UUID, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(identity) else {
            return
        }
        defaults.set(data, forKey: key(threadID: threadID, userID: userID))
    }
}

/// チャットルームに初めて参加（返信）する時に、部屋での名前とアイコンを決めるシート。
struct BoardRoomJoinIdentitySheet: View {
    var onConfirm: (String, String) -> Void
    var onCancel: () -> Void

    @State private var displayName = ""
    @State private var selectedAvatarID = BoardAnonymousAvatarOption.options[0].id

    private var canConfirm: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("このチャットルームで使う名前とアイコンを決めてください。ルームごとに変えられます。")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)

                    BoardThreadAnonymousProfileSection(
                        displayName: $displayName,
                        selectedAvatarID: $selectedAvatarID
                    )

                    Button {
                        onConfirm(
                            displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                            selectedAvatarID
                        )
                    } label: {
                        Text("この名前で参加する")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                canConfirm ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.4),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canConfirm)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("ルームに参加")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
            }
        }
    }
}
