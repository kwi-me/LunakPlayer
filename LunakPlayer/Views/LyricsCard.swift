import SwiftUI

struct LyricsCard: View {
    @ObservedObject var audio: AudioPlayer

    private var currentLine: LyricLine? {
        guard let idx = audio.activeLyricIndex, audio.lyrics.indices.contains(idx) else { return nil }
        return audio.lyrics[idx]
    }

    private var upcomingLine: LyricLine? {
        guard !audio.lyrics.isEmpty else { return nil }
        let target = (audio.activeLyricIndex ?? -1) + 1
        return audio.lyrics.indices.contains(target) ? audio.lyrics[target] : nil
    }

    private var metaLine: String {
        guard let song = audio.current else { return "NO SIGNAL" }
        return "\(song.displayArtist) / \(song.title)".uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 0.8)
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                MonoText(text: "LYRICS", size: 6.5, color: .white.opacity(0.72), tracking: 1.5)
                Spacer(minLength: 8)
                MonoText(text: metaLine, size: 5.2, color: .white.opacity(0.35), tracking: 1.1)
            }

            ZStack {
                if let line = currentLine {
                    VStack(spacing: 5) {
                        lyricText(line.text)
                        if let translation = line.translation {
                            Text(translation)
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.8)
                                .foregroundColor(.white.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    .id(line.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                } else if let upcoming = upcomingLine {
                    VStack(spacing: 5) {
                        lyricText(upcoming.text)
                            .opacity(0.55)
                        if let translation = upcoming.translation {
                            Text(translation)
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.8)
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                    .id(upcoming.id)
                } else {
                    VStack(spacing: 5) {
                        lyricText(audio.current == nil ? "NO SIGNAL" : "INSTRUMENTAL")
                            .opacity(0.75)
                        Text(audio.current == nil ? "请先导入音乐" : "纯音乐，请欣赏")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.8)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .clipped()
            .animation(.easeInOut(duration: 0.3), value: audio.activeLyricIndex)

            DashedRule(color: .white, opacity: 0.28, dash: [3, 3])
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x19396F), Color(hex: 0x0B1F48)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GridTexture(spacing: 12, color: .white, opacity: 0.045)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: Ink.navy.opacity(0.20), radius: 10, x: 0, y: 6)
    }

    @ViewBuilder
    private func lyricText(_ text: String) -> some View {
        let isCJK = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        if isCJK {
            Text(text)
                .font(.system(size: 22, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        } else {
            Text(text.uppercased())
                .font(Typo.display(26))
                .italic()
                .tracking(-0.3)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
    }
}
