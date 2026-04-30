import Foundation

enum LicenseManager {
    private static let service = "wispr-clone-gemini"
    private static let account = "license_key"

    static func readKey() -> String? {
        (try? KeychainStore.read(service: service, account: account)) ?? nil
    }

    static func saveKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "License", code: 1, userInfo: [NSLocalizedDescriptionKey: "License key is empty."])
        }
        try KeychainStore.save(trimmed, service: service, account: account)
    }

    static func clearKey() throws {
        // KeychainStore doesn't currently expose delete; overwrite with empty by removing item manually.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

