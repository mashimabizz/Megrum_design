import Foundation

public enum MegrumRemoteImageCache {
    public static let defaultMemoryCapacity = 80 * 1_024 * 1_024
    public static let defaultDiskCapacity = 512 * 1_024 * 1_024

    public static func configure(
        memoryCapacity: Int = defaultMemoryCapacity,
        diskCapacity: Int = defaultDiskCapacity
    ) {
        guard
            URLCache.shared.memoryCapacity < memoryCapacity ||
                URLCache.shared.diskCapacity < diskCapacity
        else {
            return
        }

        URLCache.shared = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            directory: cacheDirectory
        )
    }

    private static var cacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MegrumRemoteImages", isDirectory: true)
    }
}
