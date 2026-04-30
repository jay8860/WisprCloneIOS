import AppKit
import Foundation
import UniformTypeIdentifiers

enum SpeakDashDiagnostics {
    @MainActor
    static func export(
        configURL: URL,
        historyURL: URL,
        logURL: URL?,
        completion: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        let panel = NSSavePanel()
        panel.title = "Export Diagnostics"
        panel.nameFieldStringValue = "SpeakDash-Diagnostics.zip"
        panel.allowedContentTypes = [UTType.zip]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let destURL = panel.url else {
                completion(.failure(NSError(domain: "Diagnostics", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cancelled"])))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let tempDir = FileManager.default.temporaryDirectory
                        .appendingPathComponent("speakdash-diag-\(UUID().uuidString)", isDirectory: true)
                    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                    try copyIfExists(configURL, to: tempDir.appendingPathComponent("config.json"))
                    try copyIfExists(historyURL, to: tempDir.appendingPathComponent("history.json"))
                    if let logURL {
                        try copyIfExists(logURL, to: tempDir.appendingPathComponent("speakdash.log"))
                    }

                    let info = """
                    app_version=\(AppVersion.displayString)
                    os=\(ProcessInfo.processInfo.operatingSystemVersionString)
                    date=\(ISO8601DateFormatter().string(from: Date()))
                    """
                    try info.write(to: tempDir.appendingPathComponent("info.txt"), atomically: true, encoding: .utf8)

                    try createZip(from: tempDir, to: destURL)
                    try? FileManager.default.removeItem(at: tempDir)
                    completion(.success(destURL))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func copyIfExists(_ from: URL, to: URL) throws {
        guard FileManager.default.fileExists(atPath: from.path) else { return }
        try? FileManager.default.removeItem(at: to)
        try FileManager.default.copyItem(at: from, to: to)
    }

    private static func createZip(from folder: URL, to output: URL) throws {
        // Use ditto for best macOS compatibility.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", folder.path, output.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "Diagnostics", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create zip (ditto exit \(process.terminationStatus))."])
        }
    }
}
