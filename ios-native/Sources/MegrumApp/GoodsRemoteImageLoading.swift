import Foundation

enum GoodsRemoteImageLoadingPolicy {
    static let requestTimeout: TimeInterval = 12
    static let preloadMaxConcurrentRequests = 4
    static let retryDelaysNanoseconds: [UInt64] = [
        0,
        450_000_000,
        1_200_000_000,
        2_400_000_000
    ]

    static var maximumAttempts: Int {
        retryDelaysNanoseconds.count
    }
}

enum GoodsRemoteImageLoadError: Error {
    case emptyData
    case invalidImageData
    case unexpectedStatus(Int)
}

actor GoodsRemoteImageDataCache {
    static let shared = GoodsRemoteImageDataCache()
    private var dataByURL: [URL: Data] = [:]

    func data(for url: URL) -> Data? {
        dataByURL[url]
    }

    func insert(_ data: Data, for url: URL) {
        dataByURL[url] = data
    }

    func removeAll() {
        dataByURL.removeAll()
    }
}

enum GoodsRemoteImageDataLoader {
    static func loadData(from url: URL, session: URLSession = .shared) async throws -> Data {
        if let cached = await GoodsRemoteImageDataCache.shared.data(for: url) {
            return cached
        }
        if url.isFileURL {
            let data = try Data(contentsOf: url)
            try validate(data)
            await GoodsRemoteImageDataCache.shared.insert(data, for: url)
            return data
        }

        var lastError: Error?
        for (index, delay) in GoodsRemoteImageLoadingPolicy.retryDelaysNanoseconds.enumerated() {
            if delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            do {
                let data = try await fetchData(from: url, session: session, ignoresCache: index > 0)
                await GoodsRemoteImageDataCache.shared.insert(data, for: url)
                return data
            } catch {
                lastError = error
            }
        }
        throw lastError ?? GoodsRemoteImageLoadError.emptyData
    }

    static func preload(urls: [URL], maxConcurrentRequests: Int = GoodsRemoteImageLoadingPolicy.preloadMaxConcurrentRequests) async {
        let uniqueURLs = stableUniqueURLs(urls)
        guard !uniqueURLs.isEmpty else {
            return
        }

        let requestCount = min(max(1, maxConcurrentRequests), uniqueURLs.count)
        var iterator = uniqueURLs.makeIterator()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<requestCount {
                guard let url = iterator.next() else {
                    return
                }
                group.addTask {
                    _ = try? await loadData(from: url)
                }
            }

            while await group.next() != nil {
                guard let url = iterator.next() else {
                    continue
                }
                group.addTask {
                    _ = try? await loadData(from: url)
                }
            }
        }
    }

    private static func stableUniqueURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { url in
            guard !seen.contains(url) else {
                return false
            }
            seen.insert(url)
            return true
        }
    }

    private static func fetchData(from url: URL, session: URLSession, ignoresCache: Bool) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = GoodsRemoteImageLoadingPolicy.requestTimeout
        request.cachePolicy = ignoresCache ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad
        if !ignoresCache, let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            try validate(cachedResponse.data)
            return cachedResponse.data
        }
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw GoodsRemoteImageLoadError.unexpectedStatus(httpResponse.statusCode)
        }
        try validate(data)
        URLCache.shared.storeCachedResponse(
            CachedURLResponse(response: response, data: data, storagePolicy: .allowed),
            for: request
        )
        return data
    }

    private static func validate(_ data: Data) throws {
        guard !data.isEmpty else {
            throw GoodsRemoteImageLoadError.emptyData
        }
    }
}
