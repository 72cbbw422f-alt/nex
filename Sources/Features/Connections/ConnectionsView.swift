import SwiftUI

private enum ConnectionProvider: String, CaseIterable, Identifiable {
    case xtream = "Xtream"
    case jellyfin = "Jellyfin"

    var id: String { rawValue }
    var symbol: String { self == .xtream ? "antenna.radiowaves.left.and.right" : "server.rack" }
    var description: String {
        self == .xtream
            ? "IPTV-kanaler, filmer, serier och EPG från din leverantör."
            : "Bibliotek, metadata och tillgängliga strömmar från din Jellyfin-server."
    }
}

struct ConnectionsView: View {
    @State private var selectedProvider: ConnectionProvider = .xtream
    @State private var serverAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var draftMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Anslutningar")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Samla dina innehållskällor i ett gemensamt bibliotek.")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.secondaryText)
                }

                HStack(spacing: 10) {
                    providerCard(.xtream)
                    providerCard(.jellyfin)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Label(selectedProvider.rawValue, systemImage: selectedProvider.symbol)
                        .font(.headline.bold())
                        .foregroundStyle(NexusTheme.accentLight)
                    Text(selectedProvider.description)
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.secondaryText)

                    field("Serveradress", placeholder: "https://server.example.com", text: $serverAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    field("Användarnamn", placeholder: "Ditt användarnamn", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Lösenord").font(.caption.weight(.semibold)).foregroundStyle(NexusTheme.secondaryText)
                        SecureField("Ditt lösenord", text: $password)
                            .textContentType(.password)
                            .padding(13)
                            .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        draftMessage = "Utkastet finns kvar medan den här vyn är öppen. Ingen anslutning har ännu testats eller sparats säkert."
                    } label: {
                        Label("Kontrollera uppgifter", systemImage: "checkmark.shield")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(NexusTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(serverAddress.isEmpty || username.isEmpty || password.isEmpty)
                    .opacity(serverAddress.isEmpty || username.isEmpty || password.isEmpty ? 0.45 : 1)

                    if let draftMessage {
                        Text(draftMessage)
                            .font(.caption)
                            .foregroundStyle(NexusTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(NexusTheme.border, lineWidth: 1))

                Text("Säkerhet: uppgifterna hanteras ännu bara som ett tillfälligt formulärutkast. NEXUS kommer inte att ansluta till servern förrän respektive API och säker lagring är implementerade.")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("Anslutningar")
    }

    private func providerCard(_ provider: ConnectionProvider) -> some View {
        Button {
            selectedProvider = provider
            serverAddress = ""
            username = ""
            password = ""
            draftMessage = nil
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: provider.symbol)
                    .font(.title2)
                    .foregroundStyle(selectedProvider == provider ? NexusTheme.accentLight : NexusTheme.secondaryText)
                Text(provider.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(selectedProvider == provider ? "Vald källa" : "Välj källa")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(selectedProvider == provider ? NexusTheme.accent.opacity(0.18) : NexusTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedProvider == provider ? NexusTheme.accent : NexusTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func field(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(NexusTheme.secondaryText)
            TextField(placeholder, text: text)
                .padding(13)
                .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
