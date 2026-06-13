import MegrumCore
import MegrumData
import XCTest

final class AuthSessionStoreTests: XCTestCase {
    func testInMemoryStoreSavesLoadsAndClearsSession() throws {
        let store = InMemoryAuthSessionStore()
        let session = AuthSession(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresIn: 3_600,
            user: AuthUser(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                email: "michi@example.com"
            )
        )

        try store.save(session)
        XCTAssertEqual(try store.load(), session)

        try store.clear()
        XCTAssertNil(try store.load())
    }

    func testAuthSessionRefreshPolicyHandlesLegacyExpiryData() {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        let user = AuthUser(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            email: "michi@example.com"
        )

        XCTAssertTrue(
            AuthSession(
                accessToken: "access_token",
                refreshToken: "refresh_token",
                user: user
            ).shouldRefresh(now: now, leeway: 300)
        )
        XCTAssertTrue(
            AuthSession(
                accessToken: "access_token",
                refreshToken: "refresh_token",
                expiresAt: now.addingTimeInterval(60),
                user: user
            ).shouldRefresh(now: now, leeway: 300)
        )
        XCTAssertFalse(
            AuthSession(
                accessToken: "access_token",
                refreshToken: "refresh_token",
                expiresAt: now.addingTimeInterval(3_600),
                user: user
            ).shouldRefresh(now: now, leeway: 300)
        )
        XCTAssertFalse(
            AuthSession(
                accessToken: "access_token",
                user: user
            ).shouldRefresh(now: now, leeway: 300)
        )
    }
}
