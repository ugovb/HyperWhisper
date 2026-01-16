import XCTest
@testable import HyperWhisper

final class TextInjectionServiceTests: XCTestCase {
    
    func testPermissionCheck() async {
        let service = TextInjectionService()
        // In a test runner, this usually returns false unless explicitly authorized.
        let trusted = await service.isAccessibilityTrusted()
        print("Accessibility Trusted: \(trusted)")
        // We can't assert true here, but we verify the call works.
    }
    
    func testCaptureApplication() async {
        let service = TextInjectionService()
        await service.captureActiveApplication()
        // Not much to assert internally without exposing state, 
        // but ensures no crash.
    }
    
    // Cannot easily test actual injection without a GUI session and a target app.
}
