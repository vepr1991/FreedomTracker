import SwiftUI
import StoreKit

// MARK: - Store Manager

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    static let proProductID = "com.vladimirkovalenko.FreedomTracker.pro"

    var proProduct: Product?
    var isPurchased: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private init() {
        Task { await self.listenForTransactions() }
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
        }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    func purchase() async {
        guard let product = proProduct else { return }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isPurchased = true
                    await transaction.finish()
                } else {
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func restore() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
            if !isPurchased {
                errorMessage = "No previous purchases found."
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                isPurchased = true
                await transaction.finish()
            }
        }
    }
}

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPro: Bool

    @State private var store = StoreManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 10)
                    .padding(.bottom, 16)

                Text("DayLimit Pro")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Unlock the full potential of your daily allowance.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    PaywallFeatureRow(icon: "square.grid.2x2.fill",       title: "Custom Categories", subtitle: "Change widget icons and names.")
                    PaywallFeatureRow(icon: "list.bullet.rectangle.fill", title: "Full History",      subtitle: "View and manage all your past expenses.")
                    PaywallFeatureRow(icon: "icloud.fill",                title: "iCloud Sync",       subtitle: "Securely backup and sync across devices.")
                }
                .padding(.horizontal, 32)

                Spacer()

                if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await store.purchase()
                            if store.isPurchased { isPro = true; dismiss() }
                        }
                    } label: {
                        ZStack {
                            if store.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                VStack(spacing: 2) {
                                    Text("Lifetime Access").font(.headline)
                                    Text(store.proProduct?.displayPrice ?? "$29.99")
                                        .font(.caption).opacity(0.8)
                                }
                                .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(store.isLoading || store.proProduct == nil)
                    .opacity((store.isLoading || store.proProduct == nil) ? 0.6 : 1)

                    Button {
                        Task {
                            await store.restore()
                            if store.isPurchased { isPro = true; dismiss() }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .disabled(store.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Task { await store.refreshPurchaseStatus() }
        }
        .onChange(of: store.isPurchased) { _, purchased in
            if purchased { isPro = true }
        }
    }
}

// MARK: - Feature Row

struct PaywallFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2).foregroundStyle(.yellow).frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
