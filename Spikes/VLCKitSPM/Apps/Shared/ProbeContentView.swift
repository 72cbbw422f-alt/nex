import SwiftUI
import UIKit

@MainActor
private final class ProbeViewModel: ObservableObject {
    @Published var status = "Ange en medieadress och tryck på Spela."
    @Published var buffering = 0.0
    @Published var isPlaying = false
    @Published private(set) var audioTracks: [VLCKitProbeTrack] = []
    @Published private(set) var subtitleTracks: [VLCKitProbeTrack] = []
    let session = VLCKitProbeSession()

    var subtitlesDisabled: Bool {
        !subtitleTracks.contains(where: \.isSelected)
    }

    init() {
        session.onStateChanged = { [weak self] state in
            Task { @MainActor in
                let value = String(describing: state)
                self?.status = "Spelarstatus: \(value)"
                self?.isPlaying = value.localizedCaseInsensitiveContains("playing")
                self?.refreshTracks()
            }
        }
        session.onBufferingChanged = { [weak self] value in
            Task { @MainActor in self?.buffering = min(max(Double(value) / 100, 0), 1) }
        }
    }

    func refreshTracks() {
        audioTracks = session.audioTracks
        subtitleTracks = session.subtitleTracks
    }

    func selectAudioTrack(_ id: String) {
        guard session.selectAudioTrack(id: id) else {
            status = "Det valda ljudspåret är inte längre tillgängligt."
            refreshTracks()
            return
        }
        refreshTracks()
        status = "Ljudspår valt."
    }

    func disableAudioTrack() {
        session.disableAudioTrack()
        refreshTracks()
        status = "Ljudspår avstängt."
    }

    func selectSubtitleTrack(_ id: String?) {
        guard session.selectSubtitleTrack(id: id) else {
            status = "Den valda undertexten är inte längre tillgänglig."
            refreshTracks()
            return
        }
        refreshTracks()
        status = id == nil ? "Undertexter avstängda." : "Undertextspår valt."
    }

    func load(media: String, subtitle: String) {
        guard let mediaURL = Self.validatedURL(media) else {
            status = "Ogiltig medieadress. Använd http(s):// eller file://."
            return
        }
        let subtitleURL: URL?
        if subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subtitleURL = nil
        } else {
            guard let parsed = Self.validatedURL(subtitle) else {
                status = "Ogiltig undertextadress. Använd http(s):// eller file://."
                return
            }
            subtitleURL = parsed
        }
        status = "Laddar media…"
        buffering = 0
        isPlaying = false
        audioTracks = []
        subtitleTracks = []
        guard session.load(mediaURL: mediaURL, subtitleURL: subtitleURL, autoplay: true) else {
            status = "VLCKit kunde inte skapa media eller bifoga undertexten."
            return
        }
        refreshTracks()
    }

    func togglePlayback() {
        if isPlaying { session.pause(); status = "Pausad" }
        else { session.play(); status = "Uppspelning begärd" }
        isPlaying.toggle()
    }

    func stop() {
        session.stop()
        isPlaying = false
        buffering = 0
        audioTracks = []
        subtitleTracks = []
        status = "Stoppad"
    }

    private static func validatedURL(_ raw: String) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["https", "http", "file"].contains(scheme),
              url.host != nil || scheme == "file" else { return nil }
        return url
    }
}

private struct ProbeVideoSurface: UIViewRepresentable {
    let session: VLCKitProbeSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        view.isOpaque = true
        view.clipsToBounds = true
        session.attachDrawable(view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        if session.player.drawable as? UIView !== view {
            session.attachDrawable(view)
        }
    }
}

struct ProbeContentView: View {
    @StateObject private var model = ProbeViewModel()
    @State private var mediaAddress = ""
    @State private var subtitleAddress = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("NEXUS · VLCKIT TEST")
                .font(.headline.bold())
                .foregroundStyle(.purple)
            ProbeVideoSurface(session: model.session)
                .frame(maxWidth: .infinity)
                #if os(tvOS)
                .frame(height: 360)
                #else
                .frame(height: 220)
                #endif
                .background(.black)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.55), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            TextField("Medie-URL (http/https/file)", text: $mediaAddress)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Valfri undertext-URL (.srt/.vtt)", text: $subtitleAddress)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            HStack {
                Button("Ladda och spela") {
                    model.load(media: mediaAddress, subtitle: subtitleAddress)
                }.buttonStyle(.borderedProminent)
                Button(model.isPlaying ? "Pausa" : "Fortsätt") {
                    model.togglePlayback()
                }.buttonStyle(.bordered)
                Button("Stoppa", role: .destructive) { model.stop() }
                    .buttonStyle(.bordered)
            }
            HStack {
                Menu {
                    if model.audioTracks.isEmpty {
                        Text("Inga ljudspår hittades")
                    } else {
                        Button("Inget ljud", systemImage: "speaker.slash") {
                            model.disableAudioTrack()
                        }
                        ForEach(model.audioTracks) { track in
                            Button {
                                model.selectAudioTrack(track.trackId)
                            } label: {
                                Label(track.name, systemImage: track.isSelected ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                } label: {
                    Label("Ljudspår", systemImage: "speaker.wave.2")
                }
                .disabled(model.audioTracks.isEmpty)

                Menu {
                    Button {
                        model.selectSubtitleTrack(nil)
                    } label: {
                        Label("Av", systemImage: model.subtitlesDisabled ? "checkmark.circle.fill" : "circle")
                    }
                    ForEach(model.subtitleTracks) { track in
                        Button {
                            model.selectSubtitleTrack(track.trackId)
                        } label: {
                            Label(track.name, systemImage: track.isSelected ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    Label("Undertexter", systemImage: "captions.bubble")
                }
                Button {
                    model.refreshTracks()
                } label: {
                    Label("Uppdatera spår", systemImage: "arrow.clockwise")
                }
            }
            Text(model.status).font(.footnote)
            ProgressView(value: model.buffering)
            Text("Buffring: \(Int(model.buffering * 100)) %")
                .font(.caption.monospacedDigit())
            Text("Isolerad testapp. Använd endast egna eller uttryckligen tillåtna testströmmar.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.035, green: 0.045, blue: 0.085).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onDisappear { model.stop(); model.session.detachDrawable() }
    }
}
