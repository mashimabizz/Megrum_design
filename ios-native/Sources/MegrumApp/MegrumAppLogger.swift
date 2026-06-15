import Foundation
import OSLog

enum MegrumAppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.megrum.native"

    static let general = Logger(subsystem: subsystem, category: "MegrumApp")
}
