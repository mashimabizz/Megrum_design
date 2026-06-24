import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsScreen: View {
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var preferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @Environment(\.dismiss) private var dismiss

    private var selectedPreference: HomeExchangePreference {
        HomeExchangePreference(rawValue: preferenceRawValue) ?? HomeDefaultExchangeSettings.standard.preference
    }

    var body: some View {
        List {
            Section("デフォルトの交換方法") {
                VStack(spacing: 10) {
                    ForEach(HomeExchangePreference.allCases) { preference in
                        HomeExchangePreferenceRow(
                            preference: preference,
                            isSelected: selectedPreference == preference
                        ) {
                            preferenceRawValue = preference.rawValue
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("交換条件")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる", action: dismiss.callAsFunction)
            }
        }
    }
}
