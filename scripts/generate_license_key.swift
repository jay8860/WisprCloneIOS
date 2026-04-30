#!/usr/bin/swift
import CryptoKit
import Foundation

// Usage:
//   scripts/generate_license_key.swift --private-key-base64 <b64> --email <email> --days 365
//
// Prints:
//   public_key_base64=...
//   license_key=...

struct Payload: Codable {
    let email: String?
    let exp: Int?
    let features: [String]?
}

func b64url(_ data: Data) -> String {
    let s = data.base64EncodedString()
    return s.replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

func arg(_ name: String) -> String? {
    if let idx = CommandLine.arguments.firstIndex(of: name), idx + 1 < CommandLine.arguments.count {
        return CommandLine.arguments[idx + 1]
    }
    return nil
}

guard let privB64 = arg("--private-key-base64"),
      let privData = Data(base64Encoded: privB64),
      let priv = try? Curve25519.Signing.PrivateKey(rawRepresentation: privData) else {
    fputs("Missing/invalid --private-key-base64\n", stderr)
    exit(2)
}

let email = arg("--email")
let days = Int(arg("--days") ?? "") ?? 365
let exp = Int(Date().addingTimeInterval(Double(max(0, days)) * 24 * 3600).timeIntervalSince1970)

let payload = Payload(email: email, exp: exp, features: ["pro"])
let payloadData = try JSONEncoder().encode(payload)
let sig = try priv.signature(for: payloadData)

let pubB64 = priv.publicKey.rawRepresentation.base64EncodedString()
let license = "\(b64url(payloadData)).\(b64url(sig))"

print("public_key_base64=\(pubB64)")
print("license_key=\(license)")

