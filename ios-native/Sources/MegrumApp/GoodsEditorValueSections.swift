import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorQuantitySection: View {
    @Binding var quantity: Int
    var isItemReadOnly: Bool

    private var normalizedQuantity: Int {
        max(1, min(quantity, 999))
    }

    var body: some View {
        GoodsEditorSectionContainer(title: "数量", systemImage: "number", required: true) {
            HStack(spacing: 12) {
                GoodsEditorQuantityButton(systemImage: "minus") {
                    quantity = max(1, quantity - 1)
                }
                .disabled(isItemReadOnly || normalizedQuantity <= 1)

                quantityInputField

                GoodsEditorQuantityButton(systemImage: "plus") {
                    quantity = min(999, quantity + 1)
                }
                .disabled(isItemReadOnly || normalizedQuantity >= 999)
            }
        }
    }

    @ViewBuilder
    private var quantityInputField: some View {
        let field = TextField("数量", value: $quantity, format: .number)
            .multilineTextAlignment(.center)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .monospacedDigit()
            .frame(height: 46)
            .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .onChange(of: quantity) { _, newValue in
                quantity = max(1, min(newValue, 999))
            }
            .disabled(isItemReadOnly)

        #if os(iOS)
        field.keyboardType(.numberPad)
        #else
        field
        #endif
    }
}

struct GoodsEditorStatusSection: View {
    var entryKind: GoodsEntryKind
    @Binding var selectedStatus: GoodsEditorStatus
    var isItemReadOnly: Bool

    var body: some View {
        GoodsEditorSectionContainer(title: "状態", systemImage: "checkmark.seal") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(GoodsEditorStatus.options(for: entryKind)) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        GoodsEditorStatusOptionRow(
                            status: status,
                            isSelected: selectedStatus == status
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isItemReadOnly)
                }
            }
        }
    }
}
