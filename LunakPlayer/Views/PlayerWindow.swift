import SwiftUI

// MARK: - Window shell

struct PlayerWindow: View {
    @ObservedObject var audio: AudioPlayer
    var onTapStage: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WindowTitleBar()

            VStack(spacing: 7) {
                CDStage(song: audio.current, angle: audio.discAngle, onTap: onTapStage)
                NowPlayingCard(audio: audio)
                TransportBar(audio: audio)
                WindowFooter(trackNumber: (audio.index ?? 0) + 1)
            }
            .padding(7)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xEDF1F8), Color(hex: 0xDDE5F2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(Ink.panel)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Ink.line.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Ink.navy.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

// MARK: - Title bar

private struct WindowTitleBar: View {
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color(hex: 0x0B1B44))
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 0.6))

            MonoText(text: "LUNAK MEDIA PLAYER", size: 6.5, weight: .bold, color: .white.opacity(0.93), tracking: 1.35)

            Spacer(minLength: 6)

            MonoText(text: "mp3", size: 5.5, color: .white.opacity(0.55), tracking: 0.5)

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(i == 2 ? Color.white.opacity(0.85) : Color.clear)
                        .frame(width: 8, height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0.5)
                                .stroke(Color.white.opacity(0.55), lineWidth: 0.6)
                        )
                }
            }
            .padding(.leading, 3)
        }
        .padding(.horizontal, 8)
        .frame(height: 23)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x20428C), Color(hex: 0x17346E)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Now playing plate

private struct NowPlayingCard: View {
    @ObservedObject var audio: AudioPlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        MonoText(text: String(format: "%02d", (audio.index ?? 0) + 1), size: 6.5, color: .white.opacity(0.55))
                        MonoText(text: "NOW PLAYING", size: 6.5, color: .white.opacity(0.55))
                    }

                    Text(audio.current?.title ?? "NO TRACK")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    MonoText(text: audio.current?.displayArtist ?? "—", size: 6.5, color: .white.opacity(0.48))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 0) {
                    MonoText(
                        text: audio.isPlaying ? "PLAY ▶" : "PAUSE ▮▮",
                        size: 5.8,
                        color: .white.opacity(0.55)
                    )
                    Text(timecode(audio.currentTime))
                        .font(.system(size: 23, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    MonoText(text: "/ \(timecode(audio.duration))", size: 6.5, color: .white.opacity(0.45))
                }
            }

            SpectrumView(levels: audio.levels)
                .frame(height: 30)

            ScrubBar(audio: audio)

            HStack(spacing: 4) {
                MonoText(text: "VOL / \(String(format: "%02d", Int(audio.volume * 99)))", size: 5.2, color: .white.opacity(0.38))
                Spacer()
                MonoText(text: "STEREO", size: 5.2, color: .white.opacity(0.38))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x193A74), Color(hex: 0x0D2353)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                GridTexture(spacing: 11, color: .white, opacity: 0.045)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}

// MARK: - Spectrum

struct SpectrumView: View {
    var levels: [Double]

    var body: some View {
        GeometryReader { geo in
            let count = max(1, levels.count)
            let gap: CGFloat = 2.1
            let barWidth = max(0.8, (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count))

            HStack(alignment: .center, spacing: gap) {
                ForEach(levels.indices, id: \.self) { i in
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.18 + 0.52 * levels[i]))
                        .frame(width: barWidth, height: max(1.5, CGFloat(levels[i]) * geo.size.height))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}

// MARK: - Scrub

private struct ScrubBar: View {
    @ObservedObject var audio: AudioPlayer

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.16))
                    .frame(height: 2)
                Capsule()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: max(0, geo.size.width * audio.progress), height: 2)
            }
            .frame(height: 12, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard geo.size.width > 0 else { return }
                        audio.seekProgress(Double(value.location.x / geo.size.width))
                    }
            )
        }
        .frame(height: 12)
    }
}

// MARK: - Transport

private struct TransportBar: View {
    @ObservedObject var audio: AudioPlayer

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                MonoText(text: "TRANSPORT", size: 5.2, color: Ink.hairline, tracking: 1.2)
                MonoText(
                    text: audio.isPlaying ? "PLAYING" : "STANDBY",
                    size: 5.2,
                    color: Ink.blue.opacity(0.9),
                    tracking: 1.2
                )
            }
            .frame(width: 40, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                TransportButton(label: "STOP", symbol: "stop.fill", size: 28) { audio.stop() }
                TransportButton(label: "PREV", symbol: "backward.fill", size: 28) { audio.previous() }
                PlayButton(isPlaying: audio.isPlaying) { audio.toggle() }
                TransportButton(label: "NEXT", symbol: "forward.fill", size: 28) { audio.next() }
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                MonoText(text: "VOL", size: 5.2, color: Ink.hairline, tracking: 1)
                Slider(value: $audio.volume, in: 0...1)
                    .frame(width: 62)
                    .tint(Ink.blue)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 3)
    }
}

private struct TransportButton: View {
    let label: String
    let symbol: String
    let size: CGFloat
    var action: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Button(action: action) {
                    ZStack {
                        Circle().fill(Color(hex: 0xFAFBFD))
                        Circle().stroke(Ink.blue.opacity(0.40), lineWidth: 0.9)
                        Circle().stroke(Color.white.opacity(0.95), lineWidth: 0.5).padding(1)
                        Image(systemName: symbol)
                            .font(.system(size: size * 0.33, weight: .medium))
                            .foregroundColor(Ink.blue.opacity(0.9))
                    }
                    .frame(width: size, height: size)
                    .shadow(color: Ink.navy.opacity(0.10), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 50)

            MonoText(text: label, size: 4.8, color: Ink.hairline.opacity(0.85), tracking: 0.9)
        }
    }
}

private struct PlayButton: View {
    let isPlaying: Bool
    var action: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(Ink.blue.opacity(0.22))
                    .frame(width: 58, height: 58)
                    .blur(radius: 6)

                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0x2E5EE0), Color(hex: 0x16358F)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 1.5)
                    }
                    .frame(width: 50, height: 50)
                    .shadow(color: Ink.blue.opacity(0.35), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 50)

            MonoText(text: "PLAYING", size: 4.8, color: Ink.hairline.opacity(0.85), tracking: 0.9)
        }
    }
}

// MARK: - Footer

private struct WindowFooter: View {
    var trackNumber: Int

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Ink.hairline.opacity(0.32))
                .frame(height: 0.6)

            HStack(spacing: 6) {
                MonoText(text: "STEREO 44.1 KHz", size: 5.2, color: Ink.hairline.opacity(0.9))
                Spacer(minLength: 4)
                MonoText(text: "LWK / \(String(format: "%03d", trackNumber))", size: 5.2, color: Ink.hairline.opacity(0.9))
                BarcodeView(width: 38, height: 8, color: Ink.hairline.opacity(0.85))
            }
        }
        .padding(.horizontal, 3)
    }
}
