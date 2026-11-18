import SwiftUI

struct ConnectionsView: View {
    @State private var selectedProvider: ConnectionProvider = .xtream
    @State private var serverAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var draftMessage: String?
    @State private var isValidDraft = false
    @State private var isPasswordSaved = false

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

                    Button(action: validateDraft) {
                        Label("Kontrollera uppgifter", systemImage: "checkmark.shield")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(NexusTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    .opacity(serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty ? 0.45 : 1)

                    if isValidDraft {
                        Button(action: savePassword) {
                            Label("Spara lösenord säkert", systemImage: "lock.shield")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
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

                Text("Adress och användarnamn sparas inte ännu. Lösenord kan sparas separat i enhetens nyckelring. Ingen server kontaktas förrän API-anslutningen är implementerad.")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("Anslutningar")
    }

    private func validateDraft() {
        do {
            _ = try ProviderConnectionValidator.validate(
                provider: selectedProvider,
                address: serverAddress,
                username: username,
                password: password
            )
            isValidDraft = true
            isPasswordSaved = false
            draftMessage = "Formatet ser korrekt ut. Servern är inte kontaktad."
        } catch {
            isValidDraft = false
            isPasswordSaved = false
            draftMessage = error.localizedDescription
        }
    }

    private func savePassword() {
        do {
            _ = try ProviderConnectionValidator.validate(
                provider: selectedProvider,
                address: serverAddress,
                username: username,
                password: password
            )
            try KeychainCredentialStore.shared.save(
                password: password,
                provider: selectedProvider,
                username: username
            )
            isPasswordSaved = true
            draftMessage = "Lösenordet är sparat i enhetens nyckelring. Serveradress och användarnamn är ännu inte sparade."
        } catch {
            isPasswordSaved = false
            draftMessage = "Kunde inte spara lösenordet: \(error.localizedDescription)"
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
