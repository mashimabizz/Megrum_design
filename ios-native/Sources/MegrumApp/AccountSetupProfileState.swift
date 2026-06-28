import Foundation
import MegrumCore

struct AccountSetupProfileState {
    var prefectureSearchText = ""
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?
    var inputErrorMessage: String?
}
