import XCTest
import MLX
import MLXNN
@testable import HyperWhisper

final class TDTDecoderTests: XCTestCase {
    
    func testTokenizer() {
        let vocab = [0: "<blank>", 1: "H", 2: "e", 3: "l", 4: "o"]
        let tokenizer = BasicTokenizer(vocab: vocab, blankToken: 0)
        
        let text = tokenizer.decode(tokens: [1, 2, 3, 3, 4])
        XCTAssertEqual(text, "Hello")
        
        // Simple encoding check (not full BPE)
        let ids = tokenizer.encode(text: "Hello")
        XCTAssertEqual(ids, [1, 2, 3, 3, 4])
    }
    
    func testTDTDecodingLoop() async throws {
        throw XCTSkip("Skipping MLX tests due to Metal unavailability in CLI environment")
    }
    
    func testDurationSkipLogic() async throws {
        throw XCTSkip("Skipping MLX tests due to Metal unavailability in CLI environment")
    }
}
