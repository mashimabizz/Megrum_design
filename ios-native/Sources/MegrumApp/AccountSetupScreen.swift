import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    @State private var displayName: String
    @State private var prefecture: String
    @FocusState private var focusedField: Field?

    public init(appState: MegrumAppState) {
        self.appState = appState
        _displayName = State(initialValue: appState.viewer?.displayName ?? "")
        _prefecture = State(initialValue: appState.viewer?.prefecture ?? "")
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                form
                saveButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 42)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("プロフィール設定")
        .megrumInlineNavigationTitle()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Megrumへようこそ")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("まずはアプリ内で表示する名前と都道府県を設定します")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var form: some View {
        VStack(spacing: 16) {
            TextField("表示名", text: $displayName)
                .focused($focusedField, equals: .displayName)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .prefecture
                }
                .megrumTextFieldStyle()

            TextField("都道府県", text: $prefecture)
                .focused($focusedField, equals: .prefecture)
                .submitLabel(.done)
                .onSubmit {
                    Task { await save() }
                }
                .megrumTextFieldStyle()

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                if appState.isSavingAccountSetup {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("設定を完了する")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.lavender)
        .disabled(appState.isSavingAccountSetup || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func save() async {
        focusedField = nil
        _ = await appState.completeAccountSetup(displayName: displayName, prefecture: prefecture)
    }

    private enum Field {
        case displayName
        case prefecture
    }
}
