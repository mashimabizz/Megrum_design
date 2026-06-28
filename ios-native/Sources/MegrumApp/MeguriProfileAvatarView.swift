import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriProfileAvatarView: View {
    var avatarID: String?
    var avatarURL: URL?
    var fallback: String
    var size: CGFloat

    var body: some View {
        if let avatarID, !avatarID.isBlank {
            BoardAnonymousAvatar(
                option: BoardAnonymousAvatarOption.option(id: avatarID),
                size: size
            )
        } else {
            ProfileVisualAvatar(url: avatarURL, fallback: fallback, size: size)
        }
    }
}
