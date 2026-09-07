//
//  ExternalSubtitleFileCache.swift
//  NuvioTV
//
//  Downloads add-on subtitle sidecars to local files so MPV/Aether can load them
//  without stream proxy headers or extensionless remote paths.
//

import CryptoKit
import Foundation

/// Resolves remote add-on subtitle URLs into local files the playback engines
/// can open reliably. OpenSubtitles / subDL links often omit a file extension
/// and must not inherit debrid/stream `http-header-fields`.
actor ExternalSubtitleFileCache {
    static let shared = ExternalSubtitleFileCache()

    private let fileManager = FileManager.default
    private let directory: URL
    private var inFlight: [String: Task<URL?, Never>] = [:]

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("external_subtitles", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Returns a `file://` URL ready for `sub-add` / Aether sidecar decode.
    func resolvedFileURL(for subtitle: NuvioSubtitle) async -> URL? {
        guard let remote = URL(string: subtitle.url), !subtitle.url.isEmpty else { return nil }
        if remote.isFileURL { return remote }

        let key = subtitle.url
        if let existing = cachedFile(for: key) { return existing }

        if let task = inFlight[key] {
            return await task.value
        }

        let task = Task<URL?, Never> {
            await self.downloadAndStore(remote: remote, cacheKey: key)
        }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        return result
    }

    /// Copies the subtitle with a local `playbackURL` (and format hint) when possible.
    func prepare(_ subtitle: NuvioSubtitle) async -> NuvioSubtitle {
        guard let local = await resolvedFileURL(for: subtitle) else { return subtitle }
        var prepared = subtitle
        prepared.playbackURL = local.absoluteString
        if prepared.formatHint == nil {
            prepared.formatHint = ExternalSubtitleFormat.hint(forFileURL: local)
        }
        return prepared
    }

    func purge() {
        inFlight.values.forEach { $0.cancel() }
        inFlight.removeAll()
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    private func cachedFile(for key: String) -> URL? {
        let candidates = ["srt", "vtt", "ass", "ssa"].map { fileURL(for: key, ext: $0) }
        return candidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    private func downloadAndStore(remote: URL, cacheKey: String) async -> URL? {
        var request = URLRequest(url: remote)
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (AppleTV; tvOS 18.0) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.cachePolicy = .reloadIgnoringLocalCacheData

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode,
              !data.isEmpty else {
            return nil
        }

        // ZIP archives from some providers are uncommon on the Stremio UTF-8
        // proxy path; reject them rather than feeding binary zip bytes to mpv.
        if ExternalSubtitleFormat.isZip(data) {
            return nil
        }

        guard let extracted = ExternalSubtitleFormat.payload(
            data: data,
            response: http,
            sourceURL: remote
        ) else {
            return nil
        }

        let destination = fileURL(for: cacheKey, ext: extracted.fileExtension)
        do {
            try extracted.data.write(to: destination, options: .atomic)
            return destination
        } catch {
            return nil
        }
    }

    private func fileURL(for key: String, ext: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directory.appendingPathComponent("\(digest).\(ext)")
    }
}

enum ExternalSubtitleFormat {
    struct Payload {
        let data: Data
        let fileExtension: String
    }

    static func hint(forFileURL url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        guard ["srt", "vtt", "ass", "ssa"].contains(ext) else { return nil }
        return ext
    }

    static func payload(
        data: Data,
        response: HTTPURLResponse,
        sourceURL: URL
    ) -> Payload? {
        let ext = inferredExtension(data: data, response: response, sourceURL: sourceURL)
        guard looksLikeSubtitleText(data) || ["srt", "vtt", "ass", "ssa"].contains(ext) else {
            return nil
        }
        return Payload(data: data, fileExtension: ext)
    }

    static func inferredExtension(
        data: Data,
        response: HTTPURLResponse,
        sourceURL: URL
    ) -> String {
        if let fromDisposition = extensionFromContentDisposition(
            response.value(forHTTPHeaderField: "Content-Disposition")
        ) {
            return fromDisposition
        }
        if let fromType = extensionFromContentType(
            response.value(forHTTPHeaderField: "Content-Type")
        ) {
            return fromType
        }
        let pathExt = sourceURL.pathExtension.lowercased()
        if ["srt", "vtt", "ass", "ssa"].contains(pathExt) {
            return pathExt
        }
        return sniffExtension(from: data) ?? "srt"
    }

    static func extensionFromContentDisposition(_ header: String?) -> String? {
        guard let header else { return nil }
        let patterns = [
            #"filename\*=(?:UTF-8''|utf-8'')([^;]+)"#,
            #"filename=\"([^\"]+)\""#,
            #"filename=([^;]+)"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(
                      in: header,
                      range: NSRange(header.startIndex..., in: header)
                  ),
                  let range = Range(match.range(at: 1), in: header) else {
                continue
            }
            var name = String(header[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            name = name.removingPercentEncoding ?? name
            let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
            if ["srt", "vtt", "ass", "ssa"].contains(ext) { return ext }
        }
        return nil
    }

    static func extensionFromContentType(_ header: String?) -> String? {
        guard let header else { return nil }
        let lower = header.lowercased()
        if lower.contains("webvtt") || lower.contains("text/vtt") { return "vtt" }
        if lower.contains("ass") || lower.contains("ssa") { return "ass" }
        if lower.contains("subrip") || lower.contains("x-subrip") || lower.contains("srt") {
            return "srt"
        }
        return nil
    }

    static func sniffExtension(from data: Data) -> String? {
        guard let prefix = String(data: data.prefix(256), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() else { return nil }
        if prefix.hasPrefix("webvtt") { return "vtt" }
        if prefix.contains("[script info]") || prefix.contains("dialogue:") { return "ass" }
        if prefix.contains("-->") { return "srt" }
        return nil
    }

    static func looksLikeSubtitleText(_ data: Data) -> Bool {
        sniffExtension(from: data) != nil
    }

    static func isZip(_ data: Data) -> Bool {
        data.count >= 4 && data[0] == 0x50 && data[1] == 0x4b && data[2] == 0x03 && data[3] == 0x04
    }
}
