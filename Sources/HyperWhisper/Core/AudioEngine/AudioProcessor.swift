import Foundation
@preconcurrency import AVFoundation
import Accelerate
import OSLog

/// Processing Unit: Handles VAD, Normalization, and Buffer Conversion.
class AudioProcessor {
    private let logger = Logger(subsystem: "com.hyperwhisper", category: "AudioProcessor")
    
    // Config
    var isVADEnabled = false // Disabled for robust recording
    var isNormalizationEnabled = true
    
    private let targetSampleRate: Double = 16000.0
    
    // VAD State - Lowered threshold to be less aggressive
    private let energyThreshold: Float = 0.0005 
    
    /// Processes an incoming buffer (CMSampleBuffer or AVAudioPCMBuffer) and returns a clean [Float] array at 16kHz
    func process(buffer: AVAudioPCMBuffer) -> [Float]? {
        // 1. Check Silent / VAD
        if isVADEnabled {
            let energy = calculateEnergy(buffer: buffer)
            if energy < energyThreshold {
                return nil
            }
        }
        
        return convertTo16kHz(buffer: buffer)
    }
    
    func process(sampleBuffer: CMSampleBuffer) -> [Float]? {
        guard let pcmBuffer = createPCMBuffer(from: sampleBuffer) else { return nil }
        return process(buffer: pcmBuffer)
    }
    
    // MARK: - Helpers
    
    private func calculateEnergy(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        vDSP_sve(channelData, 1, &sum, vDSP_Length(frameLength))
        
        return sum / Float(frameLength)
    }
    
    private func convertTo16kHz(buffer: AVAudioPCMBuffer) -> [Float] {
        let processingFormat = buffer.format
        if processingFormat.sampleRate == targetSampleRate && processingFormat.channelCount == 1 {
             let ptr = buffer.floatChannelData![0]
             return Array(UnsafeBufferPointer(start: ptr, count: Int(buffer.frameLength)))
        }
        
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: targetSampleRate, channels: 1)!
        guard let converter = AVAudioConverter(from: processingFormat, to: outputFormat) else {
            return []
        }
        
        let ratio = targetSampleRate / processingFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputCapacity) else {
            return []
        }
        
        var error: NSError?
        // Capture buffer safely
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
           outStatus.pointee = .haveData
           return buffer
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        guard let outPtr = outputBuffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: outPtr, count: Int(outputBuffer.frameLength)))
    }
    
    private func createPCMBuffer(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
         return AVAudioPCMBuffer.from(sampleBuffer: sampleBuffer)
    }
}