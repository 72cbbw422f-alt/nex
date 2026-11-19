import SwiftUI
import UIKit
import VLCKitProbe

@MainActor
private final class ProbeViewModel: ObservableObject {
    @Published var status = "Ange en medieadress och tryck på Spela."
    @Published var buffering = 0.0
    @Published var isPlaying = false

    let session = VLCKitProbeSession()

    init() {
        session.onStateChanged = { [weak self] state in
            let description = String(describing: state)
            Task { @MainActor in
                self?.status = "Spelarstatus: \(description)"
                self?.isPlaying = description.localizedCaseInsensitiveContains("playing")
            }
        }
        session.onBufferingChanged = { [weak self] value in
            Task { @MainActor in
                self?.buffering = min(max(Double(value) / 100.0, 0), 1)
            }
        }
    }

    func load(mediaAddress: String, subtitleAddress: String) {
        guard let mediaURL = validatedURL(mediaAddress) else {
            status = "Medieadressen är ogiltig. Använd en fullständig https://- eller file://-adress."
            return
        }

        let subtitleURL: URL?
        if subtitleAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subtitleURL = nil
        } else {
            guard let parsed = validatedURL(subtitleAddress) else {
                status = "Undertextadressen är ogiltig. Använd en fullständig https://- eller file://-adress."
                return
            }
            subtitleURL = parsed
        }

        status = "Laddar media och förbereder undertext…"
        buffering = 0
        isPlaying = false

        guard session.load(mediaURL: mediaURL, subtitleURL: subtitleURL, autoplay: true) else {
            status = "VLCKit kunde inte skapa media eller bifoga undertextfilen."
            return
        }
    }

    func playPause() {
        if isPlaying {
            session.pause()
            status = "Pausad"
            isPlaying = false
        } else {
            session.play()
            status = "Uppspelning begärd"
            isPlaying = true
        }
    }

    func stop() {
        session.stop()
        isPlaying = false
        buffering = 0
        status = "Stoppad"
    }

    private func validatedURL(_ rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["https", "http", "file"].contains(scheme),
              url.host != nil || scheme == "file" else {
            return nil
        }
        return url
    }
}

private struct ProbeVideoSurface: UIViewRepresentable {
    let session: VLCKitProbeSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        session.attachDrawable(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        session.attachDrawable(uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // The parent view's onDisappear performs session teardown.
    }
}

struct ProbeContentView: View {
    @StateObject private var model = ProbeViewModel()
    @State private var mediaAddress = ""
    @State private var subtitleAddress = ""

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text("NEXUS")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white)
                Text("VLCKIT RUNTIME TEST")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.purple.opacity(0.95))
            }

            ProbeVideoSurface(session: model.session)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 9) {
                TextField("Medie-URL (https:// eller file://)", text: $mediaAddress)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Valfri undertext-URL (.srt / .vtt)", text: $subtitleAddress)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                HStack(spacing: 10) {
                    Button {
                        model.load(mediaAddress: mediaAddress, subtitleAddress: subtitleAddress)
                    } label: {
                        Label("Ladda och spela", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.purple)
                    .disabled(mediaAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        model.playPause()
                    } label: {
                        Label(model.isPlaying ? "Pausa" : "Fortsätt", systemImage: model.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        model.stop()
                    } label: {
                        Label("Stoppa", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(model.status)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(3)
                ProgressView(value: model.buffering)
                    .tint(Color.purple)
                Text("Buffring: \(Int(model.buffering * 100)) %")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.58))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Testappen är isolerad från NEXUS produktion. Använd endast egna eller uttryckligen tillåtna testströmmar och undertexter.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.035, green: 0.045, blue: 0.085).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onDisappear { model.stop(); model.session.detachDrawable() }
    }
}
