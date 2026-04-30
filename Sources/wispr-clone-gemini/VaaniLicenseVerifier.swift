import CryptoKit
import Foundation

enum VaaniLicenseVerifier {
    enum Mode: String, Codable {
        case off
        case trial
        case required
    }

    struct Payload: Codable {
        let email: String?
        let exp: Int? // unix seconds
        let features: [String]?
    }

    struct Result {
        let isValid: Bool
        let isExpired: Bool
        let payload: Payload?
        let reason: String?
    }

    static func verify(licenseKey: String?, publicKeyBase64: String?) -> Result {
        guard let licenseKey, !licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "missing")
        }
        guard let publicKeyBase64, let pubData = Data(base64Encoded: publicKeyBase64) else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "public_key_missing")
        }
        guard let pubKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubData) else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "public_key_invalid")
        }

        // Format: base64url(payload_json).base64url(signature)
        let parts = licenseKey.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "format")
        }
        guard let payloadData = base64URLDecode(parts[0]),
              let sigData = base64URLDecode(parts[1]) else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "b64")
        }
        guard sigData.count == 64 else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "sig_len")
        }

        let ok = pubKey.isValidSignature(sigData, for: payloadData)
        guard ok else {
            return Result(isValid: false, isExpired: false, payload: nil, reason: "sig")
        }

        let payload = (try? JSONDecoder().decode(Payload.self, from: payloadData))
        if let exp = payload?.exp {
            let now = Int(Date().timeIntervalSince1970)
            if now > exp {
                return Result(isValid: false, isExpired: true, payload: payload, reason: "expired")
            }
        }
        return Result(isValid: true, isExpired: false, payload: payload, reason: nil)
    }

    static func ensureTrialStart() -> Date {
        let key = "vaani.trial.start"
        if let existing = UserDefaults.standard.object(forKey: key) as? Date {
            return existing
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: key)
        return now
    }

    static func isTrialValid(trialDays: Int) -> Bool {
        let start = ensureTrialStart()
        let days = max(0, trialDays)
        guard days > 0 else { return false }
        let deadline = start.addingTimeInterval(Double(days) * 24 * 3600)
        return Date() <= deadline
    }

    private static func base64URLDecode(_ s: String) -> Data? {
        var base = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let mod = base.count % 4
        if mod != 0 {
            base += String(repeating: "=", count: 4 - mod)
        }
        return Data(base64Encoded: base)
    }
}

