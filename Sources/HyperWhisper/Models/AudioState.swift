import SwiftUI

// Shared state object for UI updates
public class AudioState: ObservableObject {
    public enum Status: String {
        case idle
        case recording
        case processing
        case finished
        case error
    }
    
    @Published public var isRecording: Bool = false
    @Published public var amplitude: Float = 0.0
    @Published public var inputGain: Float = 1.0
    
    // Device Management
    public struct InputDevice: Identifiable, Hashable {
        public let id: String
        public let name: String
        public init(id: String, name: String) { self.id = id; self.name = name }
    }
    @Published public var devices: [InputDevice] = []
    @Published public var selectedDeviceId: String = "default"
    
    @Published public var status: Status = .idle
    @Published public var transcript: String = ""
    
    public init() {}
}
