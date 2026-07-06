import MegrumCore
import SwiftUI
#if os(iOS)
import UIKit
#endif

extension MeguriScreen {
    func showOutOfRangeAlert(_ message: String) {
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームとチャットルームのみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }

    func showToast(_ message: String, placement: MeguriToastPlacement = .bottom) {
        let toastID = UUID()
        self.toastID = toastID
        toastPlacement = placement
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard self.toastID == toastID else {
                return
            }
            withAnimation(.smooth(duration: 0.18)) {
                toastMessage = nil
            }
        }
    }

    var notice: MegrumLocationNotice? {
        // ガイドツアー中は位置ノーティスやエラー表示を出さない（デモの見た目を汚さない）。
        if appState.isTutorialActive {
            return nil
        }
        let shouldSuppressAppError = appState.isLoading || appState.isLoadingMeguri || appState.isLoadingGroomMap
        return MeguriNoticeResolver.notice(
            localMessage: localNoticeMessage,
            locationNotice: locationState.meguriNotice,
            appErrorMessage: shouldSuppressAppError ? nil : appState.errorMessage
        )
    }

    func handleLocationNoticeAction() {
        guard localNoticeMessage == nil, locationState.meguriNotice?.actionTitle != nil else {
            return
        }
        if locationState.permissionPhase == .denied || locationState.permissionPhase == .servicesDisabled {
            openAppSettings()
        } else {
            locationState.startUpdatingCurrentLocation()
        }
    }

    func openAppSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
        #endif
    }

    var canUseCamera: Bool {
        #if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
        #else
        false
        #endif
    }
}
