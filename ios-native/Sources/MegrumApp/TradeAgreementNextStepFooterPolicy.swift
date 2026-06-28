import MegrumCore

enum TradeAgreementNextStepFooterPolicy {
    static func showsEvidenceCaptureFooter(
        status: ProposalStatus,
        evidencePhotos: [TradeEvidencePhoto]
    ) -> Bool {
        status == .agreed && evidencePhotos.isEmpty
    }
}
