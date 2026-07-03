import Foundation
import MegrumCore

struct GroomArchivePresentationState: Equatable {
    var selectedGroom: GroomPost?
    var focusedGroomID: UUID?
    var showsMegrumPlus = false

    var selectedGroomID: UUID? {
        selectedGroom?.id
    }

    func focusedGroom(in grooms: [GroomPost]) -> GroomPost? {
        guard let focusedGroomID else {
            return nil
        }
        return grooms.first { $0.id == focusedGroomID }
    }

    mutating func select(_ groom: GroomPost) {
        selectedGroom = groom
    }

    mutating func focus(_ groom: GroomPost?) {
        focusedGroomID = groom?.id
    }

    mutating func showMegrumPlus() {
        showsMegrumPlus = true
    }

    mutating func dismissMegrumPlus() {
        showsMegrumPlus = false
    }
}
