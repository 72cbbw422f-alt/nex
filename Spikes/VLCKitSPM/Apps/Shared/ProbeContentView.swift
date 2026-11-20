import SwiftUI
import UIKit


@MainActor
private final class ProbeViewModel: ObservableObject {
    @Published var status = "Ange en medieadress och tryck på Spela."
    @Published var buffering = 0.0
    @Published var isPlaying = false
    let session = VLCKitProbeSession()

    init() {
        session.onStateChanged = { [weak self] state in
            Task { @MainActor in
                let value = String(describing: state)
                self?.status = "Spelarstatus: \(value)"
                self?.isPlaying = value.localizedCaseInsensitiveContains("playing")
            }
        }
        session.onBufferingChanged = { [weak self] value in
            Task { @MainActor in self?.buffering = min(max(Double(value) / 100, 0), 1) }
        }
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
        guard session.load(mediaURL: mediaURL, subtitleURL: subtitleURL, autoplay: true) else {
            status = "VLCKit kunde inte skapa media eller bifoga undertexten."
            return
        }
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
        let view = UIView()
        view.backgroundColor = .black
        session.attachDrawable(view)
        return view
    }
    func updateUIView(_ view: UIView, context: Context) {
        session.attachDrawable(view)
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
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(.black)
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
