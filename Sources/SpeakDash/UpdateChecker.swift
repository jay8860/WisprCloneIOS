import Foundation

enum UpdateChecker {
    enum Status {
        case upToDate(version: String)
        case updateAvailable(current: String, latest: String, url: URL)
    }

    struct LatestRelease: Decodable {
        let tag_name: String?
        let html_url: String?
    }

    static func check(
        latestReleaseAPIURL: String,
        releasesPageURL: String,
        completion: @escaping @Sendable (Result<Status, Error>) -> Void
    ) {
        guard let url = URL(string: latestReleaseAPIURL) else {
            completion(.failure(NSError(domain: "UpdateChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid updates URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("SpeakDash/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 6

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "UpdateChecker", code: 2, userInfo: [NSLocalizedDescriptionKey: "No response data"])))
                return
            }

            do {
                let latest = try JSONDecoder().decode(LatestRelease.self, from: data)
                let tag = (latest.tag_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanedTag = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                let latestVersion = cleanedTag.isEmpty ? nil : cleanedTag

                let current = AppVersion.shortVersion
                let openURL = URL(string: latest.html_url ?? releasesPageURL) ?? URL(string: releasesPageURL)
                guard let openURL else {
                    completion(.failure(NSError(domain: "UpdateChecker", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid release page URL"])))
                    return
                }

                guard let latestVersion else {
                    completion(.success(.upToDate(version: current)))
                    return
                }

                if isVersion(latestVersion, greaterThan: current) {
                    completion(.success(.updateAvailable(current: current, latest: latestVersion, url: openURL)))
                } else {
                    completion(.success(.upToDate(version: current)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private static func isVersion(_ a: String, greaterThan b: String) -> Bool {
        let pa = parse(a)
        let pb = parse(b)
        for i in 0..<max(pa.count, pb.count) {
            let ai = i < pa.count ? pa[i] : 0
            let bi = i < pb.count ? pb[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }

    private static func parse(_ v: String) -> [Int] {
        v.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
    }
}
