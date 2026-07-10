import Foundation

extension SupabaseAuthClient {
    public func makePasswordSignInRequest(email: String, password: String) throws -> URLRequest {
        let payload = PasswordPayload(email: SupabaseTextNormalizer.trimmed(email), password: password)
        return try makeAuthRequest(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeRefreshSessionRequest(refreshToken: String) throws -> URLRequest {
        let payload = RefreshTokenPayload(refreshToken: SupabaseTextNormalizer.trimmed(refreshToken))
        return try makeAuthRequest(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeSignUpRequest(
        email: String,
        password: String,
        metadata: SupabaseAuthProfileMetadata = SupabaseAuthProfileMetadata(),
        emailRedirectTo: URL? = nil
    ) throws -> URLRequest {
        let normalizedHandle = SupabaseTextNormalizer.optional(metadata.handle)
        let normalizedDisplayName = SupabaseTextNormalizer.optional(metadata.displayName)
        let payload = SignUpPayload(
            email: SupabaseTextNormalizer.trimmed(email),
            password: password,
            data: SignUpMetadata(
                handle: normalizedHandle,
                displayName: normalizedDisplayName ?? normalizedHandle
            ),
            emailRedirectTo: emailRedirectTo?.absoluteString
        )
        return try makeAuthRequest(
            path: "/auth/v1/signup",
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeIDTokenSignInRequest(
        provider: SupabaseIDTokenProvider,
        idToken: String,
        accessToken: String? = nil,
        nonce: String? = nil
    ) throws -> URLRequest {
        let payload = IDTokenPayload(
            provider: provider.rawValue,
            idToken: SupabaseTextNormalizer.trimmed(idToken),
            accessToken: SupabaseTextNormalizer.optional(accessToken),
            nonce: SupabaseTextNormalizer.optional(nonce)
        )
        return try makeAuthRequest(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeOAuthAuthorizeURL(
        provider: SupabaseOAuthProvider,
        redirectTo: URL? = nil,
        scopes: [String] = []
    ) throws -> URL {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "provider", value: provider.rawValue)
        ]
        if let redirectTo {
            queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo.absoluteString))
        }
        let normalizedScopes = SupabaseTextNormalizer.nonEmptyValues(scopes)
        if !normalizedScopes.isEmpty {
            queryItems.append(URLQueryItem(name: "scopes", value: normalizedScopes.joined(separator: " ")))
        }

        components.path = "/auth/v1/authorize"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.invalidURL
        }
        return url
    }

    public func makeOAuthAuthorizeRequest(
        provider: SupabaseOAuthProvider,
        redirectTo: URL? = nil,
        scopes: [String] = []
    ) throws -> URLRequest {
        var request = URLRequest(
            url: try makeOAuthAuthorizeURL(provider: provider, redirectTo: redirectTo, scopes: scopes)
        )
        request.httpMethod = "GET"
        request.setValue("text/html,application/xhtml+xml,application/json", forHTTPHeaderField: "Accept")
        return request
    }

    public func makePasswordResetRequest(email: String, emailRedirectTo: URL? = nil) throws -> URLRequest {
        let payload = PasswordResetPayload(email: SupabaseTextNormalizer.trimmed(email))
        let queryItems = emailRedirectTo.map {
            [URLQueryItem(name: "redirect_to", value: $0.absoluteString)]
        } ?? []
        return try makeAuthRequest(
            path: "/auth/v1/recover",
            queryItems: queryItems,
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    /// メールに届いた確認コード（OTP）を検証する。成功でセッションが返る。iter1226.418。
    public func makeVerifyEmailOTPRequest(email: String, token: String, type: String) throws -> URLRequest {
        let payload = VerifyEmailOTPPayload(
            email: SupabaseTextNormalizer.trimmed(email),
            token: SupabaseTextNormalizer.trimmed(token),
            type: type
        )
        return try makeAuthRequest(
            path: "/auth/v1/verify",
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    /// 検証済みセッションでパスワードを更新する（リカバリの最終ステップ）。iter1226.418。
    public func makeUpdatePasswordRequest(accessToken: String, password: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/user",
            method: "PUT",
            body: encoder.encode(UpdatePasswordPayload(password: password)),
            bearerToken: accessToken
        )
    }

    /// 確認コードの再送（signup用）。iter1226.418。
    public func makeResendEmailRequest(email: String, type: String) throws -> URLRequest {
        let payload = ResendEmailPayload(
            email: SupabaseTextNormalizer.trimmed(email),
            type: type
        )
        return try makeAuthRequest(
            path: "/auth/v1/resend",
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeSignOutRequest(accessToken: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/logout",
            method: "POST",
            body: Data(),
            bearerToken: accessToken
        )
    }

    public func makeUserRequest(accessToken: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/user",
            method: "GET",
            body: nil,
            bearerToken: accessToken
        )
    }
}
