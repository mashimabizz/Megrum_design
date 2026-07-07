import Foundation

enum ProposalCreateBottomBarCopy {
    static func primaryTitle(
        selectedStep: ProposalCreateStep,
        configuration: ProposalCreateConfiguration,
        meetupHasTimeDraft: Bool
    ) -> String {
        guard configuration.canAdvance(from: selectedStep) else {
            if selectedStep == .meetup {
                return "待ち合わせ入力が必要"
            }
            return configuration.blockedTitle(for: selectedStep)
        }

        switch selectedStep {
        case .give:
            // 個別募集の1/3と同じ文言。押下で常に受け取るもの選択（2/3）へ。
            return "この内容で次へ"
        case .receive:
            return nextStepTitle(configuration: configuration)
        case .conditions:
            // 金額が発生する時は次が支払方法ステップになる（iter1226.381）。
            return configuration.requiresPaymentSelection ? "支払方法へ進む" : "次へ：送信確認"
        case .meetup:
            if configuration.requiresShippingBeforeSubmit {
                return "送料へ進む"
            }
            return configuration.requiresPaymentSelection ? "支払方法へ進む" : "次へ：送信確認"
        case .shipping:
            return configuration.requiresPaymentSelection ? "支払方法へ進む" : "次へ：送信確認"
        case .payment:
            return "この方法にする"
        case .confirm:
            return configuration.submitTitle
        }
    }

    private static func nextStepTitle(configuration _: ProposalCreateConfiguration) -> String {
        "交換条件へ進む"
    }
}

enum ProposalCreatePrimaryStepDestination {
    static func destination(
        from selectedStep: ProposalCreateStep,
        configuration: ProposalCreateConfiguration,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        guard selectedStep != .confirm, configuration.canAdvance(from: selectedStep) else {
            return nil
        }

        switch selectedStep {
        case .give:
            return adjacentStep(after: selectedStep, visibleSteps: visibleSteps)
        case .receive:
            return nextMajorStep(configuration: configuration, visibleSteps: visibleSteps)
        case .conditions:
            // 金額が発生する時は 3/3 の後に独立した支払方法ステップへ（iter1226.381）。
            if configuration.requiresPaymentSelection, visibleSteps.contains(.payment) {
                return .payment
            }
            return visibleSteps.contains(.confirm) ? .confirm : nil
        case .meetup:
            if configuration.requiresShippingBeforeSubmit, visibleSteps.contains(.shipping) {
                return .shipping
            }
            if configuration.requiresPaymentSelection, visibleSteps.contains(.payment) {
                return .payment
            }
            return visibleSteps.contains(.confirm) ? .confirm : nil
        case .shipping:
            if configuration.requiresPaymentSelection, visibleSteps.contains(.payment) {
                return .payment
            }
            return visibleSteps.contains(.confirm) ? .confirm : nil
        case .payment:
            return visibleSteps.contains(.confirm) ? .confirm : nil
        case .confirm:
            return nil
        }
    }

    private static func nextMajorStep(
        configuration _: ProposalCreateConfiguration,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        if visibleSteps.contains(.conditions) {
            return .conditions
        }
        return visibleSteps.contains(.confirm) ? .confirm : nil
    }

    private static func adjacentStep(
        after step: ProposalCreateStep,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        guard let index = visibleSteps.firstIndex(of: step),
              visibleSteps.indices.contains(index + 1)
        else {
            return nil
        }
        return visibleSteps[index + 1]
    }
}

enum ProposalPreviousStepResolver {
    static func destination(
        from selectedStep: ProposalCreateStep,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        guard let index = visibleSteps.firstIndex(of: selectedStep), index > 0 else {
            return nil
        }
        return visibleSteps[index - 1]
    }
}

enum ProposalInitialStepResolution: Equatable {
    case apply(ProposalCreateStep)
    case markApplied
    case wait
}

enum ProposalInitialStepResolver {
    /// 旧ステップ指定（待ち合わせ/送料/支払）は統合先の「交換条件」に読み替える。
    static func normalized(_ step: ProposalCreateStep) -> ProposalCreateStep {
        switch step {
        case .meetup, .shipping, .payment:
            .conditions
        default:
            step
        }
    }

    static func resolution(
        initialStep rawInitialStep: ProposalCreateStep,
        visibleSteps: [ProposalCreateStep],
        configuration: ProposalCreateConfiguration
    ) -> ProposalInitialStepResolution {
        let initialStep = normalized(rawInitialStep)
        guard visibleSteps.contains(initialStep) else {
            return .markApplied
        }
        let priorSteps = visibleSteps.prefix(while: { $0 != initialStep })
        guard priorSteps.allSatisfy({ configuration.canAdvance(from: $0) }) else {
            return .wait
        }
        return .apply(initialStep)
    }
}

enum ProposalFlowBottomBarPlacement {
    static func usesInlineScrollButton(for step: ProposalCreateStep) -> Bool {
        false
    }
}

enum ProposalFlowScreenCopy {
    static func title(for step: ProposalCreateStep) -> String {
        switch step {
        case .payment:
            "支払方法"
        case .confirm:
            "送信確認"
        case .give, .receive, .conditions, .meetup, .shipping:
            "提示物の選択"
        }
    }

    static func showsHeaderKicker(for step: ProposalCreateStep) -> Bool {
        false
    }

    static func selectionTabs(from steps: [ProposalCreateStep]) -> [ProposalCreateStep] {
        steps.filter { $0 != .payment && $0 != .confirm }
    }
}

extension ProposalCreateConfiguration {
    func canAdvance(from step: ProposalCreateStep) -> Bool {
        switch step {
        case .give:
            hasSenderSelection
        case .receive:
            hasReceiverSelection
        case .conditions:
            // 支払方法は独立ステップに移動したので、3/3 完了条件からは外す（iter1226.381）。
            targetStatus != nil
        case .meetup:
            targetStatus != nil
        case .shipping:
            true
        case .payment:
            !requiresPaymentSelection || hasSelectedPaymentMethod
        case .confirm:
            canSubmit
        }
    }

    func blockedTitle(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            "出すものを選択してください"
        case .receive:
            "受け取るものを確認してください"
        case .conditions, .meetup, .shipping, .confirm:
            submitTitle
        case .payment:
            "支払方法を選択してください"
        }
    }
}
