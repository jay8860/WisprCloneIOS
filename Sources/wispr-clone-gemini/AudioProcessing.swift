import AVFoundation
import Foundation

enum AudioProcessing {
    struct CompressedAudio {
        let url: URL
        let mimeType: String
    }

    static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "m4a", "mp4":
            return "audio/mp4"
        case "aac":
            return "audio/aac"
        case "wav":
            return "audio/wav"
        case "caf":
            return "audio/x-caf"
        default:
            return "application/octet-stream"
        }
    }

    static func compressToM4AIfPossible(inputWAV: URL) -> CompressedAudio? {
        // Expect WAV as input (our recorder output). If something else, skip.
        guard inputWAV.pathExtension.lowercased() == "wav" else { return nil }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("wispr-clone-gemini", isDirectory: true)
            .appendingPathComponent("dictation-\(UUID().uuidString).m4a")

        try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: outputURL)

        let asset = AVURLAsset(url: inputWAV)
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return nil
        }
        export.outputURL = outputURL
        export.outputFileType = .m4a

        let semaphore = DispatchSemaphore(value: 0)
        export.exportAsynchronously {
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 6.0)

        guard export.status == .completed else {
            try? FileManager.default.removeItem(at: outputURL)
            return nil
        }
        return CompressedAudio(url: outputURL, mimeType: "audio/mp4")
    }
}

