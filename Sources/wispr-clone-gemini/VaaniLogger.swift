import Foundation

final class VaaniLogger: @unchecked Sendable {
    static let shared = VaaniLogger()

    private let queue = DispatchQueue(label: "vaani.logger.queue")
    private var fileHandle: FileHandle?
    private(set) var logFileURL: URL?

    func bootstrap(logsDirectory: URL) {
        queue.sync {
            do {
                try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
                let fileURL = logsDirectory.appendingPathComponent("vaani.log")
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    FileManager.default.createFile(atPath: fileURL.path, contents: nil)
                }
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                self.fileHandle = handle
                self.logFileURL = fileURL
                writeUnlocked("[boot] logger started at \(Date())")
            } catch {
                self.fileHandle = nil
                self.logFileURL = nil
            }
        }
    }

    func log(_ message: String) {
        queue.async { [weak self] in
            self?.writeUnlocked(message)
        }
    }

    private func writeUnlocked(_ message: String) {
        guard let fileHandle else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(message)\n"
        if let data = line.data(using: .utf8) {
            try? fileHandle.write(contentsOf: data)
        }
    }
}

