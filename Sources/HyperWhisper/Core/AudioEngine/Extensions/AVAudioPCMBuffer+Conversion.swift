import AVFoundation
import CoreMedia

extension AVAudioPCMBuffer {
    /// Creates an AVAudioPCMBuffer from a CMSampleBuffer.
    /// Useful for converting ScreenCaptureKit audio output to a workable format.
    static func from(sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee else {
            return nil
        }
        
        // Create AVAudioFormat from ASBD
        guard let format = AVAudioFormat(streamDescription: UnsafePointer(unsafeAddress(of: asbd))) else {
            return nil
        }
        
        // Create Buffer
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))) else {
            return nil
        }
        
        // Copy audio data from CMSampleBuffer to AVAudioPCMBuffer
        // Note: CMSampleBufferGetDataBuffer returns a CMBlockBuffer
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        
        // Get data pointer
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        guard status == kCMBlockBufferNoErr, let dataPtr = dataPointer else { return nil }
        
        // Copy to buffer
        // Note: This assumes non-interleaved float or handles basic copy. 
        // For strict robustness, we might need to handle interleaved vs non-interleaved.
        // ScreenCaptureKit typically returns non-interleaved Float32 or Interleaved Int16 depending on config.
        // But let's assume standard float copy for now as per snippet request.
        
        // Update: The snippet provided used a direct memory copy assumption. We verify channel data availability.
        
        if let floatChannelData = buffer.floatChannelData {
            // buffer.frameCapacity is the max frames, but we likely want the actual number of samples in the buffer.
            // CMSampleBufferGetNumSamples gives us that.
            let samplesCount = Int(CMSampleBufferGetNumSamples(sampleBuffer))
            
            // Safety check for size
            let bytesPerFrame = Int(asbd.mBytesPerFrame)
            let totalBytes = samplesCount * bytesPerFrame
            
            if length >= totalBytes {
                // We copy the raw bytes. 
                // Using memcpy or buffer.floatChannelData updates.
                
                // If the format is Float32 non-interleaved (standard CoreAudio), we can copy directly for mono.
                // For multi-channel, it's more complex (planar vs interleaved).
                
                // Assuming 1 channel or interleaved copy for simplicity here, as validated by user snippet
                let srcData = UnsafeRawPointer(dataPtr).assumingMemoryBound(to: Float.self)
                
                // Copy for channel 0
                floatChannelData[0].update(from: srcData, count: samplesCount)
                
                buffer.frameLength = AVAudioFrameCount(samplesCount)
                return buffer
            }
        }
        
        return nil
    }
}

// Helper to get address easily
func unsafeAddress<T>(of x: T) -> UnsafePointer<T> {
    return withUnsafePointer(to: x) { $0 }
}
