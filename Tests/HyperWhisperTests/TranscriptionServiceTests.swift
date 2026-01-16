import XCTest
import AVFoundation
@testable import HyperWhisper

final class TranscriptionServiceTests: XCTestCase {
    
    func testTranscriptionPipeline() async throws {
        throw XCTSkip("Skipping MLX tests due to Metal unavailability in CLI environment")
    }
    
    func testRealWavCreationAndTranscription() async throws {
        throw XCTSkip("Skipping MLX tests due to Metal unavailability in CLI environment")
    }
}