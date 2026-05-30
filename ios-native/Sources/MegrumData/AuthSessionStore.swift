import Foundation
import MegrumCore
import Security

public enum AuthSessionStoreError: Error, Equatable, Sendable {
    case keychainStatus(OSStatus)
}

public protocol AuthSessionStore: Sendable {
    func load() throws -> AuthSession?
    func save(_ session: AuthSession) throws
    func clear() throws
}

public final class InMemoryAuthSessionStore: AuthSessionStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storedSession: AuthSession?

    public init(initialSession: AuthSession? = nil) {
        self.storedSession = initialSession
    }

    public func load() throws -> AuthSession? {
        lock.withLock {
            storedSession
        }
    }

    public func save(_ session: AuthSession) throws {
        lock.withLock {
            storedSession = session
        }
    }

    public func clear() throws {
        lock.withLock {
            storedSession = nil
        }
    }
}

public final class KeychainAuthSessionStore: AuthSessionStore, @unchecked Sendable {
    private let service: String
    private let account: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(service: String = "jp.megrum.auth", account: String = "primary") {
        self.service = service
        self.account = account
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> AuthSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw AuthSessionStoreError.keychainStatus(status)
        }
        guard let data = result as? Data else {
            return nil
        }
        return try decoder.decode(AuthSession.self, from: data)
    }

    public func save(_ session: AuthSession) throws {
        let data = try encoder.encode(session)
        let status = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if status == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AuthSessionStoreError.keychainStatus(addStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw AuthSessionStoreError.keychainStatus(status)
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthSessionStoreError.keychainStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
