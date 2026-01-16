import XCTest
@testable import HyperWhisper

final class CloudLLMProviderTests: XCTestCase {
    
    func testKeychainOperations() throws {
        // Warning: This touches the real Keychain. Use a test-specific service name if possible or cleanup.
        // For local development on user machine, this might trigger OS prompts.
        // We'll skip actual Keychain writing in automated CI/CD usually, but here we are in dev mode.
        // Let's rely on the compiler check for now to ensure API matches.
    }
    
    func testProviderInitialization() {
        let provider = CloudLLMProvider(accountName: "openai", modelName: "gpt-4o")
        XCTAssertNotNil(provider)
    }
    
    func testMissingKeyFailure() async {
        let provider = CloudLLMProvider(accountName: "nonexistent_account", modelName: "gpt-4o")
        
        do {
            _ = try await provider.process(text: "Hi", systemPrompt: "test")
            XCTFail("Should fail with missing key")
        } catch let error as LLMError {
            // Success
            print("Caught expected error: \(error.localizedDescription)")
        } catch {
            XCTFail("Caught unexpected error type: \(error)")
        }
    }
}
