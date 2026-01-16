import Foundation
import SwiftData

@Model
public final class TranscriptionRecord {
    public var id: UUID
    public var createdAt: Date
    public var rawText: String
    public var processedText: String
    public var audioPath: URL?
    public var modeId: UUID
    public var modeName: String
    public var duration: TimeInterval
    
    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawText: String,
        processedText: String,
        audioPath: URL? = nil,
        modeId: UUID,
        modeName: String,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawText = rawText
        self.processedText = processedText
        self.audioPath = audioPath
        self.modeId = modeId
        self.modeName = modeName
        self.duration = duration
    }
}
