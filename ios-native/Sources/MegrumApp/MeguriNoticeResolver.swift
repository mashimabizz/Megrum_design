import Foundation

enum MeguriNoticeResolver {
    static func notice(
        localMessage: String?,
        locationNotice: MegrumLocationNotice?,
        appErrorMessage: String?
    ) -> MegrumLocationNotice? {
        if let localMessage {
            return MegrumLocationNotice(message: localMessage, actionTitle: nil)
        }
        if let locationNotice {
            return locationNotice
        }
        if let appErrorMessage {
            return MegrumLocationNotice(message: appErrorMessage, actionTitle: nil)
        }
        return nil
    }
}
