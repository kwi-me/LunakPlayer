import Foundation
import AVFoundation
import Combine

/// Scans the app sandbox for playable audio and reads lightweight metadata.
///
/// Because iOS sandboxes the app, "local music" means files that live in
/// `Documents/` — dropped in via the Files app, iTunes/Finder file sharing,
/// or the in-app importer (which copies them here).
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isScanning = false
    @Published var lastError: String?

    let audioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aif", "aiff", "caf", "flac", "mp4", "m4b"
    ]

    var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Scan

    func scan() async {
        isScanning = true
        defer { isScanning = false }

        let root = documentsURL
        var urls: [URL] = []

        if let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if audioExtensions.contains(ext) {
                    urls.append(fileURL)
                }
            }
        }

        urls.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        var built: [Song] = []
        for url in urls {
            built.append(makeSong(url: url, root: root))
            await Task.yield()
        }
        songs = built
    }

    // MARK: - Song construction

    private func makeSong(url: URL, root: URL) -> Song {
        let meta = readMetadata(url: url)

        let fileName = url.deletingPathExtension().lastPathComponent
        var inferredArtist = ""
        var inferredTitle = fileName
        if let dashRange = fileName.range(of: " - ") {
            inferredArtist = String(fileName[fileName.startIndex..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            inferredTitle = String(fileName[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        let title = nonEmpty(meta.title) ?? inferredTitle
        let artist = nonEmpty(meta.artist) ?? inferredArtist
        let album = nonEmpty(meta.album) ?? ""

        let seconds = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0

        let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
        let lyricURL = FileManager.default.fileExists(atPath: lrcURL.path) ? lrcURL : nil

        let relative = url.path.replacingOccurrences(of: root.path, with: "")

        return Song(
            id: relative,
            url: url,
            title: title,
            artist: artist,
            album: album,
            duration: seconds,
            artwork: meta.artwork,
            lyricURL: lyricURL
        )
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private struct Metadata {
        var title: String?
        var artist: String?
        var album: String?
        var artwork: Data?
    }

    private func readMetadata(url: URL) -> Metadata {
        let asset = AVURLAsset(url: url)
        let items = asset.commonMetadata
        var out = Metadata()

        func string(_ identifier: AVMetadataIdentifier) -> String? {
            AVMetadataItem.metadataItems(from: items, filteredByIdentifier: identifier).first?.stringValue
        }

        out.title = string(.commonIdentifierTitle)
        out.artist = string(.commonIdentifierArtist)
        out.album = string(.commonIdentifierAlbumName)
        if let artwork = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: .commonIdentifierArtwork).first?.dataValue as? Data {
            out.artwork = artwork
        }
        return out
    }

    // MARK: - Import / delete

    func importFiles(_ urls: [URL]) {
        let fm = FileManager.default
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            let ext = url.pathExtension.lowercased()
            guard audioExtensions.contains(ext) || ext == "lrc" else { continue }

            let destination = documentsURL.appendingPathComponent(url.lastPathComponent)
            if fm.fileExists(atPath: destination.path) {
                try? fm.removeItem(at: destination)
            }
            do {
                try fm.copyItem(at: url, to: destination)
            } catch {
                lastError = "导入失败：\(url.lastPathComponent)"
            }
        }
        Task { await scan() }
    }

    func delete(_ song: Song) {
        try? FileManager.default.removeItem(at: song.url)
        if let lyric = song.lyricURL {
            try? FileManager.default.removeItem(at: lyric)
        }
        Task { await scan() }
    }

    func isEmpty() -> Bool {
        songs.isEmpty
    }
}
