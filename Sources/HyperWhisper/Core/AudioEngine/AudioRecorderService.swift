import Foundation
import AVFoundation
import OSLog
import CoreAudio
import AudioToolbox

/// Service responsible for Microphone audio capture.
/// Service responsible for Microphone audio capture.
class AudioRecorderService: NSObject {
    struct AudioDevice: Identifiable, Hashable {
        let id: String
        let name: String
    }

    private let logger = Logger(subsystem: "com.hyperwhisper", category: "AudioRecorderService")
    
    private var engine = AVAudioEngine()
    private var mixerNode = AVAudioMixerNode()
    
    // Callback for audio buffers - STRICTLY non-isolated execution
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    var isRecording: Bool {
        return engine.isRunning
    }
    
    override init() {
        super.init()
        setupEngine()
    }
    
    private func setupEngine() {
        // Attack Mixer to Input
        let inputNode = engine.inputNode
        engine.attach(mixerNode)
        
        // Connect Input -> Mixer
        // Note: Format is determined by hardware input
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Safety check: Logic might crash if input format is invalid (e.g. no mic permission yet or device error)
        if inputFormat.sampleRate == 0 || inputFormat.channelCount == 0 {
            print("AudioRecorderService: Invalid input format: \(inputFormat)")
            logger.error("Invalid input format from inputNode.")
            // Cannot connect if format is invalid. Engine start will likely fail or throw later.
            return
        }
        
        print("AudioRecorderService: Input Format: \(inputFormat)")
        logger.info("AudioRecorderService: Input Format: \(String(describing: inputFormat))")
        
        // Connect: Input -> Mixer (Tap here) -> Silencer (Mute) -> Output
        // 1. Connect Input to Mixer
        engine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        // 2. Set Mixer Volume to 1.0
        mixerNode.outputVolume = 1.0
        
        // 3. Create and attach Silencer
        let silencerNode = AVAudioMixerNode()
        engine.attach(silencerNode)
        
        // 4. Connect Mixer -> Silencer (Native Format)
        engine.connect(mixerNode, to: silencerNode, format: inputFormat)
        
        // 5. Mute Silencer
        silencerNode.outputVolume = 0.0
        
        // 6. Connect Silencer -> Main Mixer
        engine.connect(silencerNode, to: engine.mainMixerNode, format: inputFormat)

        // 7. Install Tap on Mixer (Native Format)
        // Using inputFormat ensures no implicit conversion issues in the graph
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
             guard let self = self else { return }
             self.onAudioBuffer?(buffer)
             self.calculateEnvelope(buffer: buffer)
        }
    }
    
    private func calculateEnvelope(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        
        // Simple RMS or Peak
        // Using straightforward loop for safety
        for i in 0..<frames {
            sum += abs(channelData[i])
        }
        let avg = sum / Float(frames)
        
        // Post notification (Decoupled UI update)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .audioAmplitudeUpdate, object: nil, userInfo: ["amplitude": avg])
        }
    }
    
    func startRecording() throws {
        guard !engine.isRunning else { return }
        
        // Prepare
        engine.prepare()
        
        do {
            try engine.start()
            print("AudioRecorderService: Engine started successfully")
            logger.info("Microphone capture started.")
        } catch {
            print("AudioRecorderService: Engine start FAILED: \(error)")
            throw error
        }
    }
    
    func stopRecording() {
        if engine.isRunning {
            engine.stop()
            logger.info("Microphone capture stopped.")
        }
    }
    
    func setInputDevice(id: String) async throws {
        let deviceID = try getAudioDeviceID(from: id)
        logger.info("Switching to device ID: \(deviceID) (UID: \(id))")
        
        // Safe Switching: Restart Engine
        if engine.isRunning {
            engine.stop()
            engine.reset()
        }
        
        // Small delay to ensure cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Create NEW engine instance to avoid any stale state
        let newEngine = AVAudioEngine()
        self.engine = newEngine // Update reference
        
        // Set Device on Input Node's AudioUnit
        let inputNode = newEngine.inputNode
        // Accessing inputNode creates the AU
        
        guard let au = inputNode.audioUnit else {
            throw AudioError.noAudioUnit
        }
        
        var deviceIDCopy = deviceID
        let err = AudioUnitSetProperty(
            au,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &deviceIDCopy,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        
        guard err == noErr else {
            logger.error("Failed to set device: \(err)")
            throw AudioError.deviceSelectionFailed(OSStatus: err)
        }
        
        // Re-setup Graph
        setupEngine()
        
        // Restart
        try startRecording()
    }
    
    private func getAudioDeviceID(from uid: String) throws -> AudioDeviceID {
        var deviceID: AudioDeviceID = kAudioDeviceUnknown
        var uidCFString = uid as CFString
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        // Pass the UID String as translation qualifier
        let err = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<CFString>.size),
            &uidCFString,
            &size,
            &deviceID
        )
        
        guard err == noErr, deviceID != kAudioDeviceUnknown else {
            throw AudioError.deviceNotFound
        }
        
        return deviceID
    }
    
    func listDevices() async -> [AudioDevice] {
        var allDevices: [AudioDevice] = []
        let coreAudioDevices = listDevicesCoreAudio()
        let avDevices = listDevicesAVCapture()
        
        // Merge and Deduplicate
        var seenIDs = Set<String>()
        
        // Prefer Core Audio (Detailed)
        for device in coreAudioDevices {
            if !seenIDs.contains(device.id) {
                allDevices.append(device)
                seenIDs.insert(device.id)
            }
        }
        
        // Add AVCapture Fallbacks (Robust)
        for device in avDevices {
            if !seenIDs.contains(device.id) {
                allDevices.append(device)
                seenIDs.insert(device.id)
            }
        }
        
        logger.info("Found \(allDevices.count) audio devices (CoreAudio: \(coreAudioDevices.count), AV: \(avDevices.count)).")
        print("AudioRecorderService: Found \(allDevices.count) unique devices.")
        
        return allDevices
    }
    
    private func listDevicesCoreAudio() -> [AudioDevice] {
        var devices: [AudioDevice] = []
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        
        // Get size
        var status = AudioObjectGetPropertyDataSize(systemObjectID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr else {
            print("AudioRecorderService: CoreAudio GetPropertyDataSize failed: \(status)")
            return []
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        // Get devices
        // Note: dataSize input indicates buffer capacity
        status = AudioObjectGetPropertyData(systemObjectID, &propertyAddress, 0, nil, &dataSize, &deviceIDs)
        guard status == noErr else {
             print("AudioRecorderService: CoreAudio GetPropertyData failed: \(status)")
            return []
        }
        
        for id in deviceIDs {
            // Check for input channels
            var streamSize = UInt32(0)
            var streamAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            // If checking size succeeds and > 0, it has input streams
            if AudioObjectGetPropertyDataSize(id, &streamAddr, 0, nil, &streamSize) == noErr && streamSize > 0 {
                
                // Get Name
                var name: String = "Unknown Device"
                var nameSize = UInt32(MemoryLayout<CFString>.size)
                var nameAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                var nameRef: Unmanaged<CFString>?
                if AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, &nameRef) == noErr {
                    if let ref = nameRef {
                        name = ref.takeRetainedValue() as String
                    }
                }
                
                // Get UID
                var uid: String = ""
                var uidSize = UInt32(MemoryLayout<CFString>.size)
                var uidAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceUID,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                var uidRef: Unmanaged<CFString>?
                if AudioObjectGetPropertyData(id, &uidAddr, 0, nil, &uidSize, &uidRef) == noErr {
                    if let ref = uidRef {
                        uid = ref.takeRetainedValue() as String
                    }
                }
                
                if !uid.isEmpty {
                    devices.append(AudioDevice(id: uid, name: name))
                }
            }
        }
        
        return devices
    }
    
    private func listDevicesAVCapture() -> [AudioDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        )
        
        return discoverySession.devices.map { device in
            AudioDevice(id: device.uniqueID, name: device.localizedName)
        }
    }
    
    func getInputVolume() async -> Float {
        return engine.inputNode.volume
    }
    
    func setInputVolume(_ volume: Float) async {
        engine.inputNode.volume = volume
    }
    
    func startMonitoring() async throws {
        // Monitoring means running engine but we handle data via notification.
        // Similar to startRecording but semantically different.
        // If already recording, do nothing.
        if !engine.isRunning {
             try engine.start()
        }
    }
    
    func stopMonitoring() async {
        // If recording, stopping monitoring might stop recording!
        // We typically reference count or separate them.
        // For simple app, stopping monitoring stops engine if not recording?
        // Let's assume manual control.
        if engine.isRunning {
            engine.stop()
        }
    }
}

enum AudioError: Error {
    case deviceNotFound
    case noAudioUnit
    case deviceSelectionFailed(OSStatus: OSStatus)
}
