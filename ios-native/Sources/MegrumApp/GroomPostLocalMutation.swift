import Foundation
import MegrumCore

enum GroomPostLocalMutation {
    static func settingLiked(
        postID: UUID,
        isLiked: Bool,
        adjustsCount: Bool,
        in posts: [GroomPost]
    ) -> [GroomPost] {
        posts.map { post in
            guard post.id == postID else {
                return post
            }
            var next = post
            next.liked = isLiked
            if adjustsCount {
                next.likeCount = max(0, next.likeCount + (isLiked ? 1 : -1))
            }
            return next
        }
    }

    static func removing(authorID: UUID, from posts: [GroomPost]) -> [GroomPost] {
        posts.filter { $0.authorID != authorID }
    }

    static func removing(postID: UUID, from posts: [GroomPost]) -> [GroomPost] {
        posts.filter { $0.id != postID }
    }

    static func firstPost(id: UUID, in collections: [GroomPost]...) -> GroomPost? {
        for collection in collections {
            if let post = collection.first(where: { $0.id == id }) {
                return post
            }
        }
        return nil
    }
}
