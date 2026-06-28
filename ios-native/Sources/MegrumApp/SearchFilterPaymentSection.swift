import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchPaymentMethodFilterSection: View {
    @Binding var selectedMethods: Set<UserPaymentMethod>
    var isLocked: Bool

    private let columns = [GridItem(.adaptive(minimum: 124), spacing: 10)]

    var body: some View {
        Section {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(UserPaymentMethod.allCases) { method in
                    SearchPaymentMethodChip(
                        method: method,
                        isSelected: selectedMethods.contains(method),
                        action: {
                            toggle(method)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("支払い条件", systemImage: "wallet.pass")
        }
        .disabled(isLocked)
    }

    private func toggle(_ method: UserPaymentMethod) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }
}

private struct SearchPaymentMethodChip: View {
    var method: UserPaymentMethod
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            Label {
                Text(method.displayName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            } icon: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : SearchFilterPresentation.paymentSymbol(for: method))
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .frame(maxWidth: .infinity)
            .background(isSelected ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.76), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? MegrumTheme.lavender.opacity(0.74) : MegrumTheme.muted.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SearchFilterResetSection: View {
    var onReset: () -> Void

    var body: some View {
        Section {
            Button("すべてリセット", role: .destructive) {
                onReset()
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
        }
    }
}
