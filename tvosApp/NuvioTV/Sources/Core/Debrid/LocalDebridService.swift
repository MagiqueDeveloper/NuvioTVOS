import Foundation

struct LocalDebridCachedItem: Sendable {
    let name: String?
    let size: Int64?
}

struct LocalDebridService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Queries the given debrid provider to determine which of the provided
    /// torrent hashes are already cached on their servers.
    func checkCached(
        provider: DebridProviderKind,
        apiKey: String,
        hashes: [String]
    ) async -> [String: LocalDebridCachedItem]? {
        let normalized = hashes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        guard !normalized.isEmpty else { return [:] }

        switch provider {
        case .torbox:
            return await checkTorboxCached(apiKey: apiKey, hashes: normalized)
        case .realDebrid:
            return await checkRealDebridCached(apiKey: apiKey, hashes: normalized)
        case .premiumize:
            return await checkPremiumizeCached(apiKey: apiKey, hashes: normalized)
        default:
            return nil
        }
    }

    // MARK: - TorBox

    private func checkTorboxCached(apiKey: String, hashes: [String]) async -> [String: LocalDebridCachedItem]? {
        guard let url = URL(string: "https://api.torbox.app/v1/api/torrents/checkcached?format=object") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["hashes": hashes]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let dataDict = json["data"] as? [String: Any] else {
                return nil
            }

            var result: [String: LocalDebridCachedItem] = [:]
            for (hash, itemVal) in dataDict {
                if let itemDict = itemVal as? [String: Any] {
                    let name = itemDict["name"] as? String
                    let size = (itemDict["size"] as? NSNumber)?.int64Value
                    result[hash.lowercased()] = LocalDebridCachedItem(name: name, size: size)
                }
            }
            return result
        } catch {
            return nil
        }
    }

    // MARK: - Real-Debrid

    private func checkRealDebridCached(apiKey: String, hashes: [String]) async -> [String: LocalDebridCachedItem]? {
        let hashPath = hashes.prefix(50).joined(separator: "/")
        guard let url = URL(string: "https://api.real-debrid.com/rest/1.0/torrents/instantAvailability/\(hashPath)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            var result: [String: LocalDebridCachedItem] = [:]
            for (hash, val) in json {
                guard let providerDict = val as? [String: Any],
                      let rdArray = providerDict["rd"] as? [[String: Any]],
                      !rdArray.isEmpty else {
                    continue
                }
                var firstName: String?
                var totalSize: Int64?
                if let firstVariant = rdArray.first {
                    for (_, fileInfoVal) in firstVariant {
                        if let fileInfo = fileInfoVal as? [String: Any] {
                            firstName = fileInfo["filename"] as? String
                            totalSize = (fileInfo["filesize"] as? NSNumber)?.int64Value
                            break
                        }
                    }
                }
                result[hash.lowercased()] = LocalDebridCachedItem(name: firstName, size: totalSize)
            }
            return result
        } catch {
            return nil
        }
    }

    // MARK: - Premiumize

    private func checkPremiumizeCached(apiKey: String, hashes: [String]) async -> [String: LocalDebridCachedItem]? {
        var components = URLComponents(string: "https://www.premiumize.me/api/cache/check")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apikey", value: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        for hash in hashes {
            queryItems.append(URLQueryItem(name: "items[]", value: "magnet:?xt=urn:btih:\(hash)"))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { return nil }
        let request = URLRequest(url: url)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String, status == "success",
                  let responses = json["response"] as? [Bool] else {
                return nil
            }
            let filenames = json["filename"] as? [String?]
            let filesizes = json["filesize"] as? [NSNumber?]

            var result: [String: LocalDebridCachedItem] = [:]
            for (index, isCached) in responses.enumerated() where isCached {
                guard index < hashes.count else { continue }
                let hash = hashes[index].lowercased()
                let name = (filenames?.indices.contains(index) == true) ? filenames?[index] : nil
                let size = (filesizes?.indices.contains(index) == true) ? filesizes?[index]?.int64Value : nil
                result[hash] = LocalDebridCachedItem(name: name, size: size)
            }
            return result
        } catch {
            return nil
        }
    }
}
