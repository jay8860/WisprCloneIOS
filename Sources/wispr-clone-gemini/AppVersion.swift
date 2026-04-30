import Foundation

enum AppVersion {
    static var shortVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return (v?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "0.0.0-dev"
    }

    static var buildNumber: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return (v?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "0"
    }

    static var displayString: String {
        "\(shortVersion) (\(buildNumber))"
    }
}

