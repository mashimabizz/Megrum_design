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
}
