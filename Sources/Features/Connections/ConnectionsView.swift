import SwiftUI

struct ConnectionsView: View {
    @State private var selectedProvider: ConnectionProvider = .xtream
    @State private var serverAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var draftMessage: String?
    @State private var isValidDraft = false
    @State private var isPasswordSaved = false
    @State private var savedConnections = ProviderConnectionStore.shared.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Anslutningar").font(.largeTitle.bold()).foregroundStyle(.white)
                    Text("Samla dina innehållskällor i ett gemensamt bibliotek.")
                        .font(.subheadline).foregroundStyle(NexusTheme.secondaryText)
                }

                if !savedConnections.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SPARADE ANSLUTNINGAR")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(NexusTheme.secondaryText)
                        ForEach(savedConnections) { connection in
                            HStack(spacing: 12) {
                                Image(systemName: connection.provider.symbol)
                                    .foregroundStyle(NexusTheme.accentLight)
                                    .frame(width: 34, height: 34)
                                    .background(NexusTheme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(connection.displayName).font(.subheadline.bold()).foregroundStyle(.white)
                                    Text("\(connection.provider.rawValue) · \(connection.username)")
                                        .font(.caption).foregroundStyle(NexusTheme.secondaryText)
                                }
                                Spacer()
                                Button {
                                    load(connection)
                                } label: {
                                    Image(systemName: "pencil").foregroundStyle(NexusTheme.accentLight)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    delete(connection)
                                } label: {
                                    Image(systemName: "trash").foregroundStyle(.red.opacity(0.85))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                        }
                    }
                }

                HStack(spacing: 10) {
                    providerCard(.xtream)
                    providerCard(.jellyfin)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Label(selectedProvider.rawValue, systemImage: selectedProvider.symbol)
                        .font(.headline.bold()).foregroundStyle(NexusTheme.accentLight)
                    Text(selectedProvider.description)
                        .font(.subheadline).foregroundStyle(NexusTheme.secondaryText)

                    field("Serveradress", placeholder: "https://server.example.com", text: $serverAddress)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                    field("Användarnamn", placeholder: "Ditt användarnamn", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Lösenord").font(.caption.weight(.semibold)).foregroundStyle(NexusTheme.secondaryText)
                        SecureField("Ditt lösenord", text: $password)
                            .textContentType(.password)
                            .padding(13)
                            .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: validateDraft) {
                        Label("Kontrollera uppgifter", systemImage: "checkmark.shield")
                            .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(NexusTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    .opacity(serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty ? 0.45 : 1)

                    if isValidDraft {
                        Button(action: saveConnection) {
                            Label("Spara anslutning och lösenord", systemImage: "lock.shield")
                                .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 13))
                                .foregroundStyle(NexusTheme.accentLight)
                        }
                        .buttonStyle(.plain)
                    }

                    if let draftMessage {
                        Label(draftMessage, systemImage: isPasswordSaved ? "checkmark.shield.fill" : (isValidDraft ? "checkmark.circle" : "info.circle"))
                            .font(.caption)
                            .foregroundStyle(isPasswordSaved ? NexusTheme.accentLight : NexusTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(NexusTheme.border, lineWidth: 1))

                Text("Serveradress och användarnamn sparas som anslutningsinformation. Lösenordet lagras separat i enhetens nyckelring. Att spara innebär inte att servern har kontaktats eller verifierats.")
                    .font(.caption).foregroundStyle(NexusTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("Anslutningar")
    }

    private func validateDraft() {
        do {
            _ = try validatedDraft()
            isValidDraft = true
            isPasswordSaved = false
            draftMessage = "Uppgifterna har godkänt lokal formatkontroll. Servern är inte kontaktad."
        } catch {
            isValidDraft = false
            isPasswordSaved = false
            draftMessage = error.localizedDescription
        }
    }

    private func validatedDraft() throws -> (ProviderConnectionConfiguration, ProviderCredentials) {
        let result = try ProviderConnectionValidator.validate(
            provider: selectedProvider, address: serverAddress, username: username, password: password
        )
        return (result.configuration, result.credentials)
    }

    private func saveConnection() {
        do {
            let result = try validatedDraft()
            let configuration = result.0
            let existing = savedConnections.first {
                $0.provider == configuration.provider &&
                $0.baseURL.absoluteString == configuration.baseURL.absoluteString &&
                $0.username == configuration.username
            }
            let profile = SavedProviderConnection(
                id: existing?.id ?? UUID(),
                provider: configuration.provider,
                baseURL: configuration.baseURL,
                username: configuration.username,
                createdAt: existing?.createdAt ?? .now
            )

            try ProviderConnectionStore.shared.save(profile)
            do {
                try KeychainCredentialStore.shared.save(
                    password: result.1.password,
                    provider: configuration.provider,
                    baseURL: configuration.baseURL,
                    username: configuration.username
                )
            } catch {
                if existing == nil { try? ProviderConnectionStore.shared.delete(id: profile.id) }
                throw error
            }

            savedConnections = ProviderConnectionStore.shared.load()
            isPasswordSaved = true
            draftMessage = "Anslutningen är sparad. Serverinloggningen är ännu inte testad."
        } catch {
            isPasswordSaved = false
            draftMessage = "Kunde inte spara anslutningen: \(error.localizedDescription)"
        }
    }

    private func load(_ connection: SavedProviderConnection) {
        selectedProvider = connection.provider
        serverAddress = connection.baseURL.absoluteString
        username = connection.username
        password = (try? KeychainCredentialStore.shared.password(
            provider: connection.provider, baseURL: connection.baseURL, username: connection.username
        )) ?? ""
        isValidDraft = false
        isPasswordSaved = false
        draftMessage = password.isEmpty
            ? "Profilen är laddad, men inget lösenord hittades i nyckelringen. Ange lösenordet igen."
            : "Profilen är laddad. Kontrollera uppgifterna innan du sparar ändringar."
    }

    private func delete(_ connection: SavedProviderConnection) {
        do {
            try KeychainCredentialStore.shared.delete(
                provider: connection.provider, baseURL: connection.baseURL, username: connection.username
            )
            try ProviderConnectionStore.shared.delete(id: connection.id)
            savedConnections = ProviderConnectionStore.shared.load()
            draftMessage = "Anslutningen och dess sparade lösenord har tagits bort."
            isPasswordSaved = false
        } catch {
            draftMessage = "Kunde inte ta bort anslutningen: \(error.localizedDescription)"
        }
    }

    private func providerCard(_ provider: ConnectionProvider) -> some View {
        Button {
            selectedProvider = provider
            serverAddress = ""
            username = ""
            password = ""
            draftMessage = nil
            isValidDraft = false
            isPasswordSaved = false
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: provider.symbol)
                    .font(.title2)
                    .foregroundStyle(selectedProvider == provider ? NexusTheme.accentLight : NexusTheme.secondaryText)
                Text(provider.rawValue).font(.subheadline.bold()).foregroundStyle(.white)
                Text(selectedProvider == provider ? "Vald källa" : "Välj källa")
                    .font(.caption).foregroundStyle(NexusTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(selectedProvider == provider ? NexusTheme.accent.opacity(0.18) : NexusTheme.surface,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selectedProvider == provider ? NexusTheme.accent : NexusTheme.border, lineWidth: 1))
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
