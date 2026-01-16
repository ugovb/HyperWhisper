import XCTest
import SwiftData
@testable import HyperWhisper

final class PersistenceTests: XCTestCase {
    
    @MainActor
    func testTranscriptionRecordSaving() throws {
        let schema = Schema([TranscriptionRecord.self, Mode.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        let record = TranscriptionRecord(
            rawText: "Hello",
            processedText: "Hello world",
            modeId: UUID(),
            modeName: "Test Mode"
        )
        
        context.insert(record)
        try context.save()
        
        let descriptor = FetchDescriptor<TranscriptionRecord>()
        let records = try context.fetch(descriptor)
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.rawText, "Hello")
        XCTAssertEqual(records.first?.processedText, "Hello world")
    }
}
