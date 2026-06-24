#if canImport(AuthenticationServices)
import AuthenticationServices
import CryptoKit
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AppleSignInNonce {
    static func make() -> String {
        "\(UUID().uuidString).\(UUID().uuidString)"
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func displayName(from components: PersonNameComponents?) -> String? {
        guard let components else {
            return nil
        }
        let value = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

#if canImport(UIKit)
final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
#endif
#endif
