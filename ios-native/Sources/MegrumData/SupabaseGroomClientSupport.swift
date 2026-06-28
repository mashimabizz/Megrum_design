import Foundation
import MegrumCore

actor SupabaseGroomSignedURLCache {
    private struct Entry {
        var url: URL
        var expiresAt: Date
    }

    private var entriesByPath: [String: Entry] = [:]
    private let ttl: TimeInterval = 50 * 60

    func lookup(paths: Set<String>, now: Date = .now) -> (cached: [String: URL], missing: [String]) {
        var cached: [String: URL] = [:]
        var missing: [String] = []

        for path in paths {
            if let entry = entriesByPath[path], entry.expiresAt > now {
                cached[path] = entry.url
            } else {
                entriesByPath.removeValue(forKey: path)
                missing.append(path)
            }
        }

        return (cached, missing.sorted())
    }

    func store(_ url: URL, for path: String, now: Date = .now) {
        entriesByPath[path] = Entry(url: url, expiresAt: now.addingTimeInterval(ttl))
    }
}

extension SupabaseGroomClient {
    func signedURLMap(for rows: [GroomFeedRow]) async -> [String: URL] {
        let paths = Set(rows.compactMap(\.storageImagePath))
        let lookup = await signedURLCache.lookup(paths: paths)
        var signedURLs = lookup.cached

        await withTaskGroup(of: (String, URL?).self) { group in
            for path in lookup.missing {
                group.addTask { [client] in
                    let signedURL = try? await client.createSignedURL(bucket: Self.groomBucket, path: path)
                    return (path, signedURL)
                }
            }

            for await (path, signedURL) in group {
                guard let signedURL else {
                    continue
                }
                signedURLs[path] = signedURL
                await signedURLCache.store(signedURL, for: path)
            }
        }

        return signedURLs
    }

    func ownGroomArchiveQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.published"),
            URLQueryItem(name: "order", value: "published_at.desc.nullslast,created_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 300)))")
        ]
    }

    func engagementQueryItems(postIDs: [UUID], order: String) -> [URLQueryItem] {
        let ids = postIDs
            .map { $0.uuidString.lowercased() }
            .sorted()
            .joined(separator: ",")
        return [
            URLQueryItem(name: "groom_post_id", value: "in.(\(ids))"),
            URLQueryItem(name: "order", value: order)
        ]
    }

    func groomImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }
}
