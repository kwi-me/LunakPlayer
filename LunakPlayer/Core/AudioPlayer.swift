import Foundation
import UIKit
import AVFoundation
import Combine
import MediaPlayer

/// Owns playback, the faux spectrum, disc rotation and lyric timing.
@MainActor
final class AudioPlayer: ObservableObject {

    // MARK: Published state

    @Published private(set) var playlist: [Song] = []
    @Published private(set) var index: Int?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var levels: [Double]
    @Published private(set) var discAngle: Double = 0
    @Published private(set) var lyrics: [LyricLine] = []
    @Published private(set) var activeLyricIndex: Int?
    @Published var volume: Double = 0.78 {
        didSet { player?.volume = Float(volume) }
    }

    // MARK: Private

    private var player: AVAudioPlayer?
    private var ticker: Timer?
    private let bridge = PlayerDelegateBridge()
    private static let barCount = 52
    private var weights: [Double] = []

    var current: Song? {
        guard let index, playlist.indices.contains(index) else { return nil }
        return playlist[index]
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, currentTime / duration))
    }

    // MARK: Lifecycle

    init() {
        levels = Array(repeating: 0.03, count: AudioPlayer.barCount)

        weights = (0..<AudioPlayer.barCount).map { i in
            let x = Double(i) / Double(max(1, AudioPlayer.barCount - 1))
            let tilt = 0.28 + 0.92 * sin(Double.pi * min(1.0, x * 0.96 + 0.03))
            return tilt * Double.random(in: 0.72...1.12)
        }

        bridge.onFinish = { [weak self] in
            Task { @MainActor in self?.handleTrackFinished() }
        }
        bridge.onFailure = { [weak self] in
            Task { @MainActor in self?.isPlaying = false }
        }

        configureSession()
        configureRemoteCommands()
        startTicker()
    }

    deinit {
        ticker?.invalidate()
    }

    // MARK: Session

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    func setPlaylist(_ songs: [Song]) {
        let previousID = current?.id
        playlist = songs

        if let previousID {
            if let restored = songs.firstIndex(where: { $0.id == previousID }) {
                index = restored
                return
            }
            // The track that was playing is gone (deleted or moved).
            stop()
            index = nil
        }
        if let first = songs.indices.first {
            select(first, autoplay: false)
        } else {
            index = nil
            player?.stop()
            player = nil
            isPlaying = false
            duration = 0
            currentTime = 0
            lyrics = []
            activeLyricIndex = nil
        }
    }

    // MARK: Transport

    func select(_ i: Int, autoplay: Bool = true) {
        guard playlist.indices.contains(i) else { return }
        let song = playlist[i]

        player?.stop()
        index = i
        activeLyricIndex = nil
        currentTime = 0
        lyrics = song.lyricURL.map { LyricsParser.parse(url: $0) } ?? []

        do {
            let created = try AVAudioPlayer(contentsOf: song.url)
            created.delegate = bridge
            created.isMeteringEnabled = true
            created.volume = Float(volume)
            created.prepareToPlay()
            player = created
            duration = created.duration
            isPlaying = false
            if autoplay { play() }
        } catch {
            player = nil
            duration = 0
            isPlaying = false
        }
        updateNowPlayingInfo()
    }

    func play() {
        guard let player else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        if player.play() {
            isPlaying = true
            updateNowPlayingInfo()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        activeLyricIndex = nil
        isPlaying = false
    }

    func next() {
        guard !playlist.isEmpty else { return }
        let currentIndex = index ?? -1
        let target = (currentIndex + 1) % playlist.count
        select(target)
    }

    func previous() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard !playlist.isEmpty else { return }
        let currentIndex = index ?? 0
        let target = (currentIndex - 1 + playlist.count) % playlist.count
        select(target)
    }

    func seek(to time: Double) {
        guard let player else { return }
        let clamped = min(max(0, time), max(0, player.duration - 0.15))
        player.currentTime = clamped
        currentTime = clamped
        updateActiveLyric()
    }

    func seekProgress(_ value: Double) {
        guard duration > 0 else { return }
        seek(to: duration * min(max(0, value), 1))
    }

    // MARK: Tick loop

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        guard let player else { return }

        if player.isPlaying {
            currentTime = player.currentTime
            player.updateMeters()

            let power = Double(player.averagePower(forChannel: 0))   // -160...0 dB
            let amplitude = min(1.0, max(0.0, pow(10.0, power / 42.0)))

            var next = levels
            for i in next.indices {
                let energy = amplitude * weights[i]
                let jitter = Double.random(in: 0.45...1.30)
                let target = min(1.0, max(0.015, energy * jitter * 1.75))
                let k: Double = target > next[i] ? 0.66 : 0.15
                next[i] += (target - next[i]) * k
            }
            levels = next

            discAngle = (discAngle + 2.1).truncatingRemainder(dividingBy: 360)
            updateActiveLyric()
        } else {
            if isPlaying { isPlaying = false }
            if levels.contains(where: { $0 > 0.02 }) {
                levels = levels.map { $0 * 0.85 }
            }
        }
    }

    private func updateActiveLyric() {
        guard !lyrics.isEmpty else {
            if activeLyricIndex != nil { activeLyricIndex = nil }
            return
        }
        var found: Int?
        for (i, line) in lyrics.enumerated() {
            if line.time <= currentTime + 0.2 {
                found = i
            } else {
                break
            }
        }
        if found != activeLyricIndex {
            activeLyricIndex = found
        }
    }

    // MARK: Now Playing / remote

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let song = current else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.displayArtist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let data = song.artwork, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - Track end handling

extension AudioPlayer {
    func handleTrackFinished() {
        isPlaying = false
        next()
    }
}

/// AVAudioPlayer's delegate is a plain ObjC protocol delivered on an arbitrary
/// thread, so it is bridged here instead of putting the callback on the
/// main-actor-isolated player class.
private final class PlayerDelegateBridge: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?
    var onFailure: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFailure?()
    }
}
