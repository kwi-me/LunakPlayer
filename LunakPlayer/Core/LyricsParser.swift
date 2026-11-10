import Foundation

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: Double
    let text: String
    var translation: String?

    static func == (lhs: LyricLine, rhs: LyricLine) -> Bool {
        lhs.id == rhs.id
    }
}

/// Minimal LRC parser: `[mm:ss.xx]line`, supports multiple timestamps per line
/// and merges a second line sharing the same timestamp as the translation.
enum LyricsParser {

    static func parse(url: URL) -> [LyricLine] {
        guard let raw = loadText(url: url) else { return [] }
        var lines: [LyricLine] = []

        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            var rest = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            var stamps: [Double] = []

            while rest.hasPrefix("["), let close = rest.firstIndex(of: "]") {
                let tag = String(rest[rest.index(after: rest.startIndex)..<close])
                if let seconds = parseTimeTag(tag) {
                    stamps.append(seconds)
                }
                rest = String(rest[rest.index(after: close)...])
            }

            let text = rest.trimmingCharacters(in: .whitespaces)
            guard !stamps.isEmpty, !text.isEmpty else { continue }

            for stamp in stamps {
                if let existing = lines.firstIndex(where: { abs($0.time - stamp) < 0.01 }) {
                    if lines[existing].translation == nil {
                        lines[existing].translation = text
                    }
                } else {
                    lines.append(LyricLine(time: stamp, text: text, translation: nil))
                }
            }
        }

        return lines.sorted { $0.time < $1.time }
    }

    private static func parseTimeTag(_ tag: String) -> Double? {
        // Skip metadata tags such as ti:, ar:, al:, by:, offset:
        guard !tag.contains(":") || tag.first?.isNumber == true else { return nil }
        let parts = tag.replacingOccurrences(of: ":", with: ".").split(separator: ".")
        guard parts.count >= 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else { return nil }

        var fraction = 0.0
        if parts.count >= 3, let raw = Double(parts[2]) {
            let digits = parts[2].count
            fraction = raw / pow(10.0, Double(digits))
        }
        return minutes * 60 + seconds + fraction
    }

    private static func loadText(url: URL) -> String? {
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        // Many Chinese .lrc files are GB18030 encoded.
        let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        ))
        if let text = try? String(contentsOf: url, encoding: gb18030) {
            return text
        }
        return try? String(contentsOf: url, encoding: .isoLatin1)
    }
}
