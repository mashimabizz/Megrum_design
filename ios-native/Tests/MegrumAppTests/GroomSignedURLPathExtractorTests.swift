import Foundation
import Testing
@testable import MegrumApp

@Suite("GroomSignedURLPathExtractor")
struct GroomSignedURLPathExtractorTests {
    @Test("署名URLからバケット内パスを取り出せる")
    func extractsPath() {
        let url = URL(string: "https://example.supabase.co/storage/v1/object/sign/groom-posts/user-id/12345_file.jpg?token=abc")!
        #expect(
            GroomSignedURLPathExtractor.storagePath(from: url) == "user-id/12345_file.jpg"
        )
    }

    @Test("対象バケットを含まないURLは nil")
    func returnsNilForOtherURL() {
        let url = URL(string: "https://example.com/images/photo.jpg")!
        #expect(GroomSignedURLPathExtractor.storagePath(from: url) == nil)
    }
}
