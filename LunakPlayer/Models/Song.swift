import Foundation

/// A track living inside the app sandbox.
struct Song: Identifiable, Hashable {
    let id: String              // stable identifier: relative path
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var artwork: Data?
    var lyricURL: URL?

    var isEmptyArtist: Bool {
        artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayArtist: String {
        isEmptyArtist ? "UNKNOWN ARTIST" : artist
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
