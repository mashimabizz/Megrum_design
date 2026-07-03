import Foundation

struct AccountSetupToastState: Equatable {
    var message: String?
    var id = UUID()

    mutating func showToast(_ message: String, id: UUID = UUID()) {
        self.id = id
        self.message = message
    }

    mutating func clearToast(ifMatching id: UUID) {
        guard self.id == id else {
            return
        }
        message = nil
    }
}
