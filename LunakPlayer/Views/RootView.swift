import SwiftUI

struct RootView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var audio = AudioPlayer()
    @State private var showLibrary = false

    var body: some View {
        ZStack {
            Backdrop()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    HeaderBlock(song: audio.current, trackCount: max(library.songs.count, 1))

                    PlayerWindow(audio: audio) {
                        showLibrary = true
                    }

                    LyricsCard(audio: audio)

                    LibraryBar(count: library.songs.count) {
                        showLibrary = true
                    }

                    Colophon()
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 34)
                .frame(maxWidth: 470)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Ink.paper)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showLibrary) {
            LibrarySheet(library: library, audio: audio) {
                showLibrary = false
            }
        }
        .task {
            await library.scan()
            audio.setPlaylist(library.songs)
        }
        .onChange(of: library.songs) { songs in
            audio.setPlaylist(songs)
        }
    }
}

// MARK: - Library entry strip

private struct LibraryBar: View {
    var count: Int
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                MonoText(text: "LIBRARY", size: 6.5, weight: .bold, color: Ink.navy.opacity(0.85), tracking: 1.6)
                Rectangle()
                    .fill(Ink.hairline.opacity(0.45))
                    .frame(width: 22, height: 0.7)
                MonoText(text: "\(count) TRACKS", size: 6, color: Ink.hairline, tracking: 1.3)
                Spacer(minLength: 6)
                MonoText(text: "IMPORT / BROWSE ›", size: 6, color: Ink.blue.opacity(0.9), tracking: 1.3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Ink.hairline.opacity(0.32), lineWidth: 0.7)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Colophon

private struct Colophon: View {
    var body: some View {
        VStack(spacing: 3) {
            MonoText(
                text: "LUNAK PLAYER / LOCAL SANDBOX STORAGE",
                size: 5,
                color: Ink.hairline.opacity(0.75),
                tracking: 1.2
            )
            MonoText(
                text: "UNSIGNED BUILD — v1.0",
                size: 5,
                color: Ink.hairline.opacity(0.5),
                tracking: 1.2
            )
        }
        .padding(.top, 6)
    }
}

#Preview {
    RootView()
}
