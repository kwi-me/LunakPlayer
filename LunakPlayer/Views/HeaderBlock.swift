import SwiftUI

/// Masthead: wordmark, technical strip and the compressed two-line headline.
struct HeaderBlock: View {
    let song: Song?
    let trackCount: Int

    private var words: [String] {
        let raw = (song?.title ?? "NO TRACK LOADED").uppercased()
        let parts = raw.split(separator: " ").map(String.init)
        return parts.isEmpty ? ["NO TRACK"] : parts
    }

    private var firstLine: String {
        words.first ?? "NO TRACK"
    }

    private var secondLine: String {
        words.count > 1 ? words.dropFirst().joined(separator: " ") : "PLAYER"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 3) {
                    Text("lunak")
                        .font(Typo.display(23))
                        .tracking(-0.5)
                        .foregroundColor(Ink.navy)
                    Sparkle(size: 10, color: Ink.navy)
                        .offset(y: -6)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 2) {
                    MonoText(text: "DIGITAL AUDIO", size: 6.5, color: Ink.navy.opacity(0.72), tracking: 1.5)
                    MonoText(
                        text: "STEREO / \(String(format: "%03d", max(trackCount, 1)))",
                        size: 6.5,
                        color: Ink.navy.opacity(0.72),
                        tracking: 1.5
                    )
                }
                .padding(.top, 3)
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: -16) {
                DisplayText(text: firstLine, size: 54, color: Ink.navy)

                HStack(alignment: .bottom, spacing: 8) {
                    DisplayText(text: secondLine, size: 54, color: Ink.blue)

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 3) {
                        Sparkle(size: 13, color: Ink.navy.opacity(0.85))
                        MonoText(text: genreLine, size: 6.3, color: Ink.navy.opacity(0.8), tracking: 1.7)
                        MonoText(text: "SWEET WORDS, LATE NIGHTS.", size: 5.3, color: Ink.hairline.opacity(0.9), tracking: 1.2)
                    }
                    .padding(.bottom, 9)
                }
            }
        }
    }

    private var genreLine: String {
        if let album = song?.album, !album.isEmpty {
            return album.uppercased()
        }
        return "ELECTRONIC MUSIC"
    }
}
