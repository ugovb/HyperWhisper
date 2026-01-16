import Foundation

public enum DownloadStatus: String, Codable, Sendable {
    case notDownloaded
    case downloading
    case paused
    case downloaded
    case error
}

public struct ModelDownloadInfo: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let remoteURL: URL
    public let expectedSize: String // Display string e.g. "1.2 GB"
    public let minSizeBytes: Int64
    public var status: DownloadStatus = .notDownloaded
    public var progress: Double = 0.0 // 0.0 to 1.0
    public var localPath: URL?
}

public struct ModelRegistry {
    public static let availableModels: [ModelDownloadInfo] = [
        ModelDownloadInfo(
            id: "parakeet-0.6b",
            name: "Parakeet TDT 0.6b",
            description: "Fast, high-accuracy multilingual transcription model.",
            remoteURL: URL(string: "https://huggingface.co/mlx-community/parakeet-tdt-0.6b-v3/resolve/main/model.safetensors?download=true")!,
            expectedSize: "1.2 GB",
            minSizeBytes: 1_200_000_000
        ),
        ModelDownloadInfo(
            id: "whisper-large-v3-turbo",
            name: "Whisper Large v3 Turbo",
            description: "Multi-lingual, high performance, and accurate.",
            remoteURL: URL(string: "https://huggingface.co/mlx-community/whisper-large-v3-turbo/resolve/main/model.safetensors?download=true")!,
            expectedSize: "1.6 GB",
            minSizeBytes: 1_600_000_000
        )
    ]
}
