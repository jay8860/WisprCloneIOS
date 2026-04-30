import Foundation

enum OfflineWhisperClient {
    struct Config {
        let binaryPath: String
        let modelPath: String
        let languageHint: String?
    }

    static func transcribe(audioURL: URL, config: Config) throws -> String {
        let binary = URL(fileURLWithPath: config.binaryPath)
        let model = URL(fileURLWithPath: config.modelPath)

        guard FileManager.default.isExecutableFile(atPath: binary.path) else {
            throw NSError(domain: "OfflineWhisper", code: 1, userInfo: [NSLocalizedDescriptionKey: "whisper.cpp binary not executable at \(binary.path)"])
        }
        guard FileManager.default.fileExists(atPath: model.path) else {
            throw NSError(domain: "OfflineWhisper", code: 2, userInfo: [NSLocalizedDescriptionKey: "whisper model not found at \(model.path)"])
        }

        // whisper.cpp generally expects WAV/PCM. Our recorder already produces 16k mono WAV.
        let outputBaseURL = makeOutputBaseURL()

        let args: [String] = {
            var a: [String] = []
            a += ["-m", model.path]
            a += ["-f", audioURL.path]
            a += ["-otxt"]
            a += ["-of", outputBaseURL.path]
            a += ["-nt"] // no timestamps
            if let lang = whisperLangCode(from: config.languageHint) {
                a += ["-l", lang]
            }
            return a
        }()

        let process = Process()
        process.executableURL = binary
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let err = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OfflineWhisper", code: 3, userInfo: [NSLocalizedDescriptionKey: "whisper.cpp failed (\(process.terminationStatus)): \(err)"])
        }

        let outPath = outputBaseURL.path + ".txt"
        guard let text = try? String(contentsOfFile: outPath, encoding: .utf8) else {
            throw NSError(domain: "OfflineWhisper", code: 4, userInfo: [NSLocalizedDescriptionKey: "whisper.cpp produced no output at \(outPath)"])
        }
        try? FileManager.default.removeItem(atPath: outPath)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func makeOutputBaseURL() -> URL {
        // whisper.cpp writes `<base>.txt` for -otxt
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("speakdash", isDirectory: true)
            .appendingPathComponent("offline-whisper-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: base.deletingLastPathComponent(), withIntermediateDirectories: true)
        return base
    }

    private static func whisperLangCode(from languageHint: String?) -> String? {
        guard let languageHint else { return nil }
        let lower = languageHint.lowercased()
        if lower.hasPrefix("hi") { return "hi" }
        if lower.hasPrefix("en") { return "en" }
        return nil
    }
}
