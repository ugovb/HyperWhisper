import Foundation

struct TranscriptionSegment: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let speakerID: String
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

// Helpers for export
extension TimeInterval {
    func toSRTTimestamp() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}
