@testable import MegrumApp
import MegrumCore
import XCTest

final class UserOshiSelectionPersistenceMapperTests: XCTestCase {
    func testSelectionsPreserveInputOrderAndFields() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!
        var generatedIDs = [firstID, secondID]

        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000601")!
        let characterID = UUID(uuidString: "00000000-0000-0000-0000-000000000602")!
        let oshiRequestID = UUID(uuidString: "00000000-0000-0000-0000-000000000603")!
        let characterRequestID = UUID(uuidString: "00000000-0000-0000-0000-000000000604")!

        let selections = UserOshiSelectionPersistenceMapper.selections(
            from: [
                AccountSetupOshiInput(groupID: groupID, characterID: nil, kind: .box, priority: 1),
                AccountSetupOshiInput(
                    groupID: groupID,
                    characterID: characterID,
                    kind: .specific,
                    priority: 2,
                    oshiRequestID: oshiRequestID,
                    characterRequestID: characterRequestID
                )
            ],
            userID: userID,
            idFactory: { generatedIDs.removeFirst() }
        )

        XCTAssertEqual(selections.map(\.id), [firstID, secondID])
        XCTAssertEqual(selections.map(\.userID), [userID, userID])
        XCTAssertEqual(selections.map(\.groupID), [groupID, groupID])
        XCTAssertEqual(selections.map(\.characterID), [nil, characterID])
        XCTAssertEqual(selections.map(\.kind), [.box, .specific])
        XCTAssertEqual(selections.map(\.priority), [1, 2])
        XCTAssertEqual(selections[1].oshiRequestID, oshiRequestID)
        XCTAssertEqual(selections[1].characterRequestID, characterRequestID)
    }
}
