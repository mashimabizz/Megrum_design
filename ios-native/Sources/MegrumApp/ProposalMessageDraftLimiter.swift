enum ProposalMessageDraftLimiter {
    static func limited(_ value: String, limit: Int) -> String {
        guard limit > 0 else {
            return ""
        }
        guard value.count > limit else {
            return value
        }
        return String(value.prefix(limit))
    }
}
