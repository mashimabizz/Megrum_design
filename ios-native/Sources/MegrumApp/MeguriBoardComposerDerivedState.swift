import MegrumCore

extension BoardThreadComposerSheet {
    var canSubmit: Bool {
        isShowingLocationStep
            && contentMessage == nil
            && locationMessage == nil
            && !appState.isCreatingBoardThread
    }

    var missingContextMessage: String? {
        if let contentMessage {
            return contentMessage
        }
        guard isShowingLocationStep else {
            return nil
        }
        return locationMessage
    }

    var contentMessage: String? {
        if let thumbnailErrorMessage {
            return thumbnailErrorMessage
        }
        guard !title.isBlank else {
            return "タイトルを入力してください"
        }
        guard !bodyText.isBlank else {
            return "本文を入力してください"
        }
        return nil
    }

    var locationMessage: String? {
        guard baseCoordinate != nil else {
            return "現在地を確認してから作成場所を選んでください"
        }
        guard selectedCoordinate != nil else {
            return "地図上で作成場所を選んでください"
        }
        guard submitCoordinate != nil else {
            return "1km圏外には作成できません"
        }
        return nil
    }

    var canAdvanceToLocationStep: Bool {
        contentMessage == nil && !appState.isCreatingBoardThread
    }

    var primaryActionTitle: String {
        isShowingLocationStep ? "この場所で作成する" : "最後に場所を決める"
    }

    var primaryActionEnabled: Bool {
        isShowingLocationStep ? canSubmit : canAdvanceToLocationStep
    }

    var submitLatitude: Double? {
        submitCoordinate?.latitude
    }

    var submitLongitude: Double? {
        submitCoordinate?.longitude
    }

    var submitScope: BoardThread.Audience {
        .nearby3km
    }

    var submitCoordinate: MegrumLocationCoordinate? {
        guard let selectedCoordinate,
              MeguriAccessPolicy.canCreateAt(
                  selectedCoordinate,
                  currentCoordinate: baseCoordinate
              )
        else {
            return nil
        }
        return selectedCoordinate
    }

    var baseCoordinate: MegrumLocationCoordinate? {
        locationState.coordinate ?? fallbackCoordinate
    }

    var submitPrefecture: String? {
        selectedPrefecture.nilIfBlank
            ?? (appState.viewer?.prefecture).nilIfBlank
            ?? (submitScope == .nearby3km ? "未設定" : nil)
    }
}
