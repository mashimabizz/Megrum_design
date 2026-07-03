import Foundation
import MegrumCore

#if canImport(StoreKit)
import StoreKit
#endif

struct MegrumPlusPurchaseOffer: Equatable, Sendable {
    var productID: String
    var displayName: String
    var priceText: String
}

enum MegrumPlusPurchaseOutcome: Equatable, Sendable {
    case purchased(MegrumPlusPurchaseSyncInput)
    case restored(MegrumPlusPurchaseSyncInput)
    case pending
    case cancelled
    case unavailable
}

enum MegrumPlusPurchaseError: LocalizedError, Equatable {
    case storeKitUnavailable
    case productUnavailable
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .storeKitUnavailable:
            "この環境ではApp Store課金を利用できません。"
        case .productUnavailable:
            "\(SubscriptionCatalog.currentPremiumDisplayName)の商品情報を取得できませんでした。"
        case .verificationFailed:
            "購入情報を確認できませんでした。"
        }
    }
}

protocol MegrumPlusPurchaseClient: Sendable {
    func loadOffer(productID: String) async throws -> MegrumPlusPurchaseOffer
    func purchase(productID: String) async throws -> MegrumPlusPurchaseOutcome
    func restore(productID: String) async throws -> MegrumPlusPurchaseOutcome
}

struct StoreKitMegrumPlusPurchaseClient: MegrumPlusPurchaseClient {
    func loadOffer(productID: String) async throws -> MegrumPlusPurchaseOffer {
        #if canImport(StoreKit)
        let product = try await product(for: productID)
        return MegrumPlusPurchaseOffer(
            productID: product.id,
            displayName: product.displayName.isEmpty ? SubscriptionCatalog.currentPremiumDisplayName : product.displayName,
            priceText: product.displayPrice
        )
        #else
        throw MegrumPlusPurchaseError.storeKitUnavailable
        #endif
    }

    func purchase(productID: String) async throws -> MegrumPlusPurchaseOutcome {
        #if canImport(StoreKit)
        let product = try await product(for: productID)
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .purchased(syncInput(from: transaction))
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .unavailable
        }
        #else
        throw MegrumPlusPurchaseError.storeKitUnavailable
        #endif
    }

    func restore(productID: String) async throws -> MegrumPlusPurchaseOutcome {
        #if canImport(StoreKit)
        try await AppStore.sync()
        for await verification in Transaction.currentEntitlements {
            let transaction = try verified(verification)
            guard transaction.productID == productID, transaction.revocationDate == nil else {
                continue
            }
            return .restored(syncInput(from: transaction))
        }
        return .unavailable
        #else
        throw MegrumPlusPurchaseError.storeKitUnavailable
        #endif
    }

    #if canImport(StoreKit)
    private func product(for productID: String) async throws -> Product {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw MegrumPlusPurchaseError.productUnavailable
        }
        return product
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw MegrumPlusPurchaseError.verificationFailed
        }
    }

    private func syncInput(from transaction: Transaction) -> MegrumPlusPurchaseSyncInput {
        MegrumPlusPurchaseSyncInput(
            productID: transaction.productID,
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            expiresAt: transaction.expirationDate
        )
    }
    #endif
}
