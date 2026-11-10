import SwiftUI
import UniformTypeIdentifiers

struct LibrarySheet: View {
    @ObservedObject var library: LibraryStore
    @ObservedObject var audio: AudioPlayer
    var onClose: () -> Void

    @State private var importing = false

    private var allowedTypes: [UTType] {
        var types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav]
        if let lrc = UTType(filenameExtension: "lrc") {
            types.append(lrc)
        }
        return types
    }

    var body: some View {
        ZStack {
            Ink.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
                footer
            }
        }
        .preferredColorScheme(.light)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                library.importFiles(urls)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LIBRARY")
                    .font(Typo.display(30))
                    .tracking(-0.5)
                    .foregroundColor(Ink.navy)
                MonoText(
                    text: "\(library.songs.count) TRACKS / LOCAL SANDBOX",
                    size: 6,
                    color: Ink.hairline,
                    tracking: 1.4
                )
            }

            Spacer()

            Button {
                onClose()
            } label: {
                MonoText(text: "CLOSE ✕", size: 7, weight: .bold, color: Ink.navy, tracking: 1.3)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Ink.navy.opacity(0.35), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if library.songs.isEmpty {
            emptyState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(library.songs.enumerated()), id: \.element.id) { index, song in
                        row(index: index, song: song)
                        Rectangle()
                            .fill(Ink.hairline.opacity(0.18))
                            .frame(height: 0.6)
                            .padding(.leading, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func row(index: Int, song: Song) -> some View {
        let isCurrent = audio.current?.id == song.id

        return Button {
            audio.select(index)
            onClose()
        } label: {
            HStack(spacing: 12) {
                Text(String(format: "%02d", index + 1))
                    .font(Typo.mono(9, .bold))
                    .foregroundColor(isCurrent ? Ink.blue : Ink.hairline.opacity(0.7))
                    .frame(width: 22, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Ink.navy)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        MonoText(text: song.displayArtist, size: 6, color: Ink.hairline, tracking: 1)
                        if song.lyricURL != nil {
                            MonoText(text: "LRC", size: 5, color: Ink.blue.opacity(0.8), tracking: 1)
                        }
                    }
                }

                Spacer(minLength: 8)

                Text(timecode(song.duration))
                    .font(Typo.mono(9))
                    .foregroundColor(Ink.hairline)

                if isCurrent {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(audio.isPlaying ? Ink.blue : Ink.hairline.opacity(0.6))
                        .frame(width: 4, height: 14)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 20)
            .background(isCurrent ? Ink.blue.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                library.delete(song)
            } label: {
                Label("删除文件", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Sparkle(size: 26, color: Ink.hairline.opacity(0.5))
            Text("NO TRACKS")
                .font(Typo.display(26))
                .foregroundColor(Ink.navy.opacity(0.7))
            Text("导入本地音频，或把文件放进「文件」App → 我的 iPhone → Lunak")
                .font(.system(size: 12))
                .foregroundColor(Ink.hairline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                importing = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("IMPORT AUDIO FILES")
                        .font(Typo.mono(8, .bold))
                        .tracking(1.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Ink.blue)
            }
            .buttonStyle(.plain)

            if let error = library.lastError {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.8))
            } else {
                MonoText(
                    text: "MP3 / M4A / FLAC / WAV · 歌词放同名 .LRC",
                    size: 5.5,
                    color: Ink.hairline.opacity(0.85),
                    tracking: 1.1
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 26)
        .background(
            Ink.paper
                .overlay(alignment: .top) {
                    Rectangle().fill(Ink.hairline.opacity(0.2)).frame(height: 0.6)
                }
        )
    }
}
