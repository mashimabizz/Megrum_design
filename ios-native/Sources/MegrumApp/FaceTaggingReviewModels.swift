import Foundation
import MegrumCore

struct FaceTaggingMemberOption: Identifiable, Equatable, Sendable {
    var id: UUID { memberID }
    var memberID: UUID
    var name: String
    var detail: String?

    init(memberID: UUID, name: String, detail: String? = nil) {
        self.memberID = memberID
        self.name = name
        self.detail = detail
    }
}

struct FaceTaggingCorrectionDraft: Identifiable, Equatable, Sendable {
    var id: UUID
    var resultID: UUID
    var imageType: MemberTaggingImageType
    var subjectType: MemberTaggingSubjectType
    var recognitionMethod: MemberTaggingRecognitionMethod
    var profileType: MemberProfileType?
    var selectedMemberID: UUID?
    var selectedMemberName: String?
    var shouldAddTrainingData: Bool

    init(result: FaceTaggingResult) {
        self.id = UUID()
        self.resultID = result.id
        self.imageType = result.imageType
        self.subjectType = result.subjectType
        self.recognitionMethod = result.recognitionMethod
        self.profileType = result.profileType
        self.selectedMemberID = result.matchedMemberID ?? result.candidates.first?.memberID
        self.selectedMemberName = result.matchedMemberName ?? result.candidates.first?.memberName
        self.shouldAddTrainingData = true
    }
}
