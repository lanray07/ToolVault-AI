import Combine
import Foundation
import StoreKit

enum SubscriptionVerificationError: LocalizedError {
    case failed

    var errorDescription: String? {
        "The subscription transaction could not be verified."
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let proMonthlyID = "com.toolvaultai.pro.monthly"
    static let proYearlyID = "com.toolvaultai.pro.yearly"
    static let businessMonthlyID = "com.toolvaultai.business.monthly"

    static let productIDs: Set<String> = [
        proMonthlyID,
        proYearlyID,
        businessMonthlyID
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var plan: SubscriptionPlan = .free
    @Published private(set) var isActive = false
    @Published private(set) var renewsAt: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    var statusText: String {
        isActive ? plan.statusText : SubscriptionPlan.free.statusText
    }

    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshEntitlements()
            await self.observeTransactionUpdates()
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            errorMessage = nil
        } catch {
            errorMessage = "Products are unavailable in this build. Placeholder prices are shown."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Purchase could not be completed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func placeholderPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .free: return "Free"
        case .pro: return "£12.99 monthly or £99.99 yearly"
        case .business: return "£49.99 monthly"
        }
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        switch plan {
        case .free:
            return nil
        case .pro:
            return products.first { $0.id == Self.proMonthlyID } ?? products.first { $0.id == Self.proYearlyID }
        case .business:
            return products.first { $0.id == Self.businessMonthlyID }
        }
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await transaction.finish()
                await refreshEntitlements()
            } catch {
                errorMessage = "A subscription update could not be verified."
            }
        }
    }

    func refreshEntitlements() async {
        var detectedPlan: SubscriptionPlan = .free
        var detectedRenewalDate: Date?

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.businessMonthlyID {
                detectedPlan = .business
                detectedRenewalDate = transaction.expirationDate
                break
            }
            if transaction.productID == Self.proMonthlyID || transaction.productID == Self.proYearlyID {
                detectedPlan = .pro
                detectedRenewalDate = transaction.expirationDate
            }
        }

        plan = detectedPlan
        isActive = detectedPlan != .free
        renewsAt = detectedRenewalDate
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, _):
            throw SubscriptionVerificationError.failed
        }
    }
}
