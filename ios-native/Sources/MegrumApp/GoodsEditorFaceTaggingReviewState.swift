import Foundation
import MegrumCore

enum FaceTaggingReviewTarget: Equatable {
    case draft
    case createPhoto(UUID)
}

struct FaceTaggingReviewContext: Identifiable, Equatable {
    var id = UUID()
    var target: FaceTaggingReviewTarget
    var imageData: Data
    var analysis: FaceTaggingAnalysis
}

struct FaceTaggingReviewQueue: Equatable {
    var current: FaceTaggingReviewContext?
    private var pending: [FaceTaggingReviewContext] = []

    var pendingCount: Int {
        pending.count
    }

    mutating func enqueue(_ context: FaceTaggingReviewContext) {
        if current == nil {
            current = context
        } else {
            pending.append(context)
        }
    }

    mutating func presentNextIfNeeded() {
        guard current == nil, !pending.isEmpty else {
            return
        }
        current = pending.removeFirst()
    }
}
