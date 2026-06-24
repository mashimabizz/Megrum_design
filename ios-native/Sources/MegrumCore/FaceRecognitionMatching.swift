import Foundation

public struct FaceRecognitionThresholds: Codable, Hashable, Sendable {
    public static let realPhoto = FaceRecognitionThresholds(autoMatchMinimum: 0.90, reviewMinimum: 0.70)
    public static let animeIllustration = FaceRecognitionThresholds(autoMatchMinimum: 0.95, reviewMinimum: 0.75)
    public static let `default` = realPhoto

    public var autoMatchMinimum: Double
    public var reviewMinimum: Double

    public init(autoMatchMinimum: Double = 0.90, reviewMinimum: Double = 0.70) {
        let review = Self.clamped(reviewMinimum)
        self.reviewMinimum = review
        self.autoMatchMinimum = max(Self.clamped(autoMatchMinimum), review)
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

public struct MemberTaggingThresholds: Codable, Hashable, Sendable {
    public static let `default` = MemberTaggingThresholds()

    public var realPhoto: FaceRecognitionThresholds
    public var animeIllustration: FaceRecognitionThresholds
    public var unknown: FaceRecognitionThresholds

    public init(
        realPhoto: FaceRecognitionThresholds = .realPhoto,
        animeIllustration: FaceRecognitionThresholds = .animeIllustration,
        unknown: FaceRecognitionThresholds = .animeIllustration
    ) {
        self.realPhoto = realPhoto
        self.animeIllustration = animeIllustration
        self.unknown = unknown
    }

    public func thresholds(for imageType: MemberTaggingImageType) -> FaceRecognitionThresholds {
        switch imageType {
        case .realPhoto:
            realPhoto
        case .anime, .illustration, .manga:
            animeIllustration
        case .unknown:
            unknown
        }
    }
}

public enum FaceMatchResolver {
    public static func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double? {
        guard !lhs.isEmpty, lhs.count == rhs.count else {
            return nil
        }

        var dot = 0.0
        var lhsNorm = 0.0
        var rhsNorm = 0.0

        for index in lhs.indices {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }

        guard lhsNorm > 0, rhsNorm > 0 else {
            return nil
        }

        let similarity = dot / (sqrt(lhsNorm) * sqrt(rhsNorm))
        return min(max(similarity, -1), 1)
    }

    public static func candidates(
        for embedding: FaceEmbedding,
        profiles: [MemberFaceProfile],
        limit: Int = 3,
        profileTypes: Set<MemberProfileType>? = nil
    ) -> [FaceMatchCandidate] {
        guard limit > 0 else {
            return []
        }

        var bestByMember: [UUID: (name: String, confidence: Double, profileCount: Int)] = [:]

        for profile in profiles where !profile.isDeleted {
            if let profileTypes, !profileTypes.contains(profile.profileType) {
                continue
            }
            guard let rawSimilarity = cosineSimilarity(embedding.values, profile.embedding.values) else {
                continue
            }
            let confidence = normalizedConfidence(fromCosineSimilarity: rawSimilarity)
            let current = bestByMember[profile.memberID]
            bestByMember[profile.memberID] = (
                name: profile.memberName,
                confidence: max(current?.confidence ?? 0, confidence),
                profileCount: (current?.profileCount ?? 0) + 1
            )
        }

        return bestByMember
            .map { memberID, value in
                FaceMatchCandidate(
                    memberID: memberID,
                    memberName: value.name,
                    confidence: value.confidence,
                    rank: 1,
                    profileCount: value.profileCount
                )
            }
            .sorted { lhs, rhs in
                if lhs.confidence != rhs.confidence {
                    return lhs.confidence > rhs.confidence
                }
                return lhs.memberName.localizedStandardCompare(rhs.memberName) == .orderedAscending
            }
            .prefix(limit)
            .enumerated()
            .map { index, candidate in
                FaceMatchCandidate(
                    id: candidate.id,
                    memberID: candidate.memberID,
                    memberName: candidate.memberName,
                    confidence: candidate.confidence,
                    rank: index + 1,
                    profileCount: candidate.profileCount
                )
            }
    }

    public static func status(
        for face: DetectedFaceObservation,
        candidates: [FaceMatchCandidate],
        thresholds: FaceRecognitionThresholds = .default
    ) -> FaceMatchStatus {
        guard face.qualityStatus.isUsable else {
            return .lowQuality
        }
        guard let best = candidates.first else {
            return .unknown
        }
        if best.confidence >= thresholds.autoMatchMinimum {
            return .autoMatched
        }
        if best.confidence >= thresholds.reviewMinimum {
            return .needsReview
        }
        return .unknown
    }

    private static func normalizedConfidence(fromCosineSimilarity similarity: Double) -> Double {
        min(max((similarity + 1) / 2, 0), 1)
    }
}
