import Foundation

extension IndividualListingDraft {
    mutating func ensureDefaultCondition(groupID: UUID?, goodsTypeID: UUID?) {
        if conditionGroupID == nil {
            conditionGroupID = groupID
        }
        if conditionGoodsTypeID == nil {
            conditionGoodsTypeID = goodsTypeID
        }
    }

    mutating func setConditionGroupID(_ id: UUID?) {
        guard conditionGroupID != id else {
            return
        }
        conditionGroupID = id
        conditionMemberIDs.removeAll()
        excludesSelectedConditionMembers = false
        conditionTagNames.removeAll()
    }

    mutating func toggleConditionMember(_ id: UUID) {
        if conditionMemberIDs.contains(id) {
            conditionMemberIDs.remove(id)
            if conditionMemberIDs.isEmpty {
                excludesSelectedConditionMembers = false
            }
        } else {
            conditionMemberIDs.insert(id)
        }
    }

    mutating func setExcludesSelectedConditionMembers(_ value: Bool) {
        excludesSelectedConditionMembers = value && !conditionMemberIDs.isEmpty
    }

    mutating func toggleConditionTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        if let index = conditionTagNames.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            conditionTagNames.remove(at: index)
        } else if conditionTagNames.count < 5 {
            conditionTagNames.append(trimmed)
        }
    }

    mutating func setConditionQuantity(_ quantity: Int) {
        conditionQuantity = Self.boundedQuantity(quantity)
    }

    var usesConditionLogicChoice: Bool {
        conditionMemberIDs.count > 1 || excludesSelectedConditionMembers
    }
}
