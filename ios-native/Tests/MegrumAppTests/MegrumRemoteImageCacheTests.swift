import Foundation
@testable import MegrumApp
import XCTest

final class MegrumRemoteImageCacheTests: XCTestCase {
    func testConfigureInstallsLargerSharedURLCache() {
        let originalCache = URLCache.shared
        defer {
            URLCache.shared = originalCache
        }

        URLCache.shared = URLCache(memoryCapacity: 128, diskCapacity: 256, directory: nil)

        MegrumRemoteImageCache.configure(memoryCapacity: 1_024, diskCapacity: 2_048)

        XCTAssertGreaterThanOrEqual(URLCache.shared.memoryCapacity, 1_024)
        XCTAssertGreaterThanOrEqual(URLCache.shared.diskCapacity, 2_048)
    }
}
