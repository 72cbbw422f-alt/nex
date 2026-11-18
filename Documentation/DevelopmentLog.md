# Development log

## 2026-11-17 — Project initialized

- Repository confirmed: 72cbbw422f-alt/nex
- Repository was newly created and contained only a minimal README.
- Product scope confirmed: iOS, iPadOS and tvOS.
- Design direction: Nuvio-inspired, original NEXUS implementation.
- Content model: unified movie/series catalogue combining Xtream IPTV and Jellyfin-compatible AIOMetadata/AIOStreams sources.
- Initial architecture and roadmap documented.
- No app code, API integration, or playback implementation had been completed at initialization.

## 2026-11-17 — Phase 1 design shell started

- Added XcodeGen project specification with iOS and tvOS application targets. iPadOS is supported through the adaptive iOS target.
- Added SwiftUI application entry point, design tokens, reusable poster tile, home screen and platform-adaptive root navigation.
- Added GitHub Actions simulator build workflow for iOS and tvOS.
- UI uses local illustrative placeholder artwork only; no real provider data is connected.
- Build has not yet been executed in this environment. CI will validate compilation.

## 2026-11-17 — Playback and viewing-history direction agreed

- User approved an embedded player plus external-player option.
- KSPlayer is the preferred embedded-engine candidate, subject to a technical spike covering exact package/components, GPL/LGPL/commercial licensing implications, iOS/iPadOS/tvOS build support and real-device playback tests.
- Keep PlaybackCoordinator engine-independent. Retain AVPlayer as a possible native fallback; do not couple UI, subtitles or tracking directly to KSPlayer APIs.
- Infuse is the planned external-player integration. Progress/completion must only be recorded when reliable callback data is returned; opening an external app is not proof of playback or completion.
- Add a shared subtitle-preference service: ordered language priority, embedded-track preference, OpenSubtitles lookup, conservative media/release matching, local cache and manual override. OpenSubtitles API access, authentication, quotas and terms remain to be validated.
- NEXUS should publish normalized playback events to BingeLog: start, pause, resume, periodic progress, stop, completion and hand-off. Use stable media/episode IDs, durable local outbox, idempotency keys and explicit in-progress/completed states.
- Inspected `72cbbw422f-alt/binge`: BingeLog is currently local-first and uses SwiftData. `BingeEntry` stores TMDB ID and movie/TV kind; `BingeEpisodeProgress` stores series TMDB ID, season and episode; `BingeWatchEvent` stores local status/episode activity. No remote sync transport is currently implemented.
- Use TMDB IDs + media kind for film/series identity, and series TMDB ID + season + episode for episode identity. Avoid title-only auto-matching.
- A shared backend or CloudKit-based contract is still required; the apps cannot directly share their separate local SwiftData stores.
- These are architecture decisions and planned capabilities only; no player, subtitle provider or BingeLog sync has been implemented yet.

## Decisions to validate

- Exact AIOMetadata server API, auth mode and available endpoints.
- Whether AIOStreams exposes playable variants through the user's current Jellyfin-compatible setup, and in what response shape.
- Xtream provider API behavior and supported EPG/catch-up capabilities.
- KSPlayer package/component choice, applicable license terms, build configuration and actual codec/audio/HDR support on iPhone, iPad and Apple TV.
- OpenSubtitles API authentication, quotas, terms and subtitle matching behavior.
- Infuse URL hand-off and callback behavior, including reliable progress and completion reporting.
- BingeLog repository architecture, stable media identifiers and sync endpoint/backend.
- Build/signing workflow for iOS, iPadOS and tvOS from the available PC-based workflow.


## 2026-11-18 — Visual direction approved and locked

- User selected the supplied NEXUS concept images as the definitive target appearance.
- Approved visual identity: deep navy/near-black cinematic surfaces, blue-purple atmosphere and vivid violet accents. The earlier lime-green concept is superseded.
- iPhone home: compact top bar, horizontal primary navigation, cinematic hero, Live nu shelf, continue-watching and popular shelves.
- Film/series detail: rich metadata, synopsis, cast/crew, related titles; series include season selector and episode list.
- Apple TV: wide cinematic hero, clear navigation, prominent Live nu row and remote-friendly violet focus states.
- Live TV is a first-class section with channel groups, favourites, now/next and a full EPG timeline/grid; the home screen also shows a Live nu shelf.
- The design reference is the visual acceptance baseline. Adapt responsively for iPhone, iPad and Apple TV without arbitrary redesign.
- Added `Documentation/DesignDirection.md` as the source of truth for colors, layouts, reusable components and acceptance criteria.
- These are approved design requirements, not yet implemented production UI. Existing scaffold remains an early placeholder until rebuilt to this specification.


## 2026-11-18 — First detail and Live TV navigation implementation

- Rebuilt the home screen around the approved deep-navy and violet design system, including a cinematic hero, Live nu shelf, continue-watching and curated shelves.
- Added a first Live TV guide screen shell with channel group chips and now/next rows with progress indicators. It currently uses illustrative sample data; no IPTV provider or EPG is connected.
- Added a first film/series detail shell with synopsis, metadata chips, technical metadata placeholders, cast section, related content and episode rows for series. It currently uses sample content; no TMDB or provider metadata is connected.
- Home shelf cards now navigate to the detail shell.
- Added Apple TV navigation destinations for Home, Live TV, Films, Series and My List.
- CI caught a SwiftUI font modifier compile error; corrected it from `.subheadline.semibold()` to `.subheadline.weight(.semibold)`.
- The corrected iOS simulator build and the detail-view iOS/tvOS simulator build completed successfully. A later navigation commit has a new CI run in progress.
- Earlier failed CI runs correspond to the pre-fix commits and are superseded by the successful corrected builds.
- No real streaming, metadata, EPG, subtitle or BingeLog integration is implemented yet.


## 2026-11-18 — Live TV guide interaction pass

- Channel group chips now filter the guide list (All, Favourites, Swedish, Sport, Film and Documentary categories).
- Channel star controls toggle favourite membership.
- Favourites filter has an explicit empty state.
- Current programme progress and next-programme fields remain sample fixtures pending a real provider/EPG connector.
- Favourite state is currently view-local and not persisted; persistence will be added with the real channel model and settings store.


## 2026-11-18 — Searchable library screens

- Added separate movie and series library screens with responsive adaptive poster grids.
- Added local title search and navigation from each card to the media detail shell.
- Connected both mobile tabs and Apple TV library destinations to the new screens.
- The screens currently use fixture entries; provider catalogue ingestion, real artwork and metadata remain unimplemented.


## 2026-11-18 — Global search shell

- Added a global search destination reachable from the home toolbar.
- Search filters a shared sample catalogue across film and series, shows result count and an empty/no-results state, and opens the selected detail shell.
- This is local fixture search only. Unified provider search across Xtream/Jellyfin/AIOStreams and metadata indexing remain future connector work.


## 2026-11-18 — Shared catalogue fixture model

- Added a single typed preview-catalogue model for movie and series fixtures.
- Updated the movie library, series library and global search to consume the same fixture records, including consistent title, type, subtitle and artwork seed.
- This removes duplicate sample lists and establishes a seam for replacing fixtures with repository-backed catalogue data.
- The catalogue remains local preview data; no Xtream, Jellyfin/AIOStreams or TMDB requests are made.


## 2026-11-18 — Provider connection setup shell

- Added an Anslutningar screen with separate Xtream and Jellyfin setup modes.
- Added server address, username and password fields, with a secure password field and a home-toolbar entry point.
- The form currently holds only an in-memory draft while the view is open. Its action explicitly reports that no connection has been tested or securely saved.
- No credentials are transmitted, persisted or logged. Keychain storage, provider-specific API validation and real connection tests remain unimplemented.
- This UI is a setup shell only; endpoint details and authentication flows must be validated against the actual provider/server APIs before networking is added.


## 2026-11-18 — Provider connection domain foundation

- Extracted Xtream and Jellyfin provider identity into a shared domain model.
- Added typed connection configuration and runtime credential value types.
- Added local validation for HTTP(S) server URLs, host, username and password presence.
- Added a provider connector protocol as the boundary for future API adapters.
- Updated the connection form to report local format validation separately from a real server test.
- No network requests or credential persistence are implemented. Credentials remain transient in the form; Keychain integration and provider-specific authentication still need implementation and tests.


## 2026-11-18 — Keychain credential storage

- Added a Security-framework Keychain store for provider passwords, scoped by provider and username.
- Passwords use device-only, after-first-unlock accessibility; values are never written to UserDefaults or logs.
- Added explicit user action in the connection form to save a password after local field/URL validation.
- Added read and delete operations for future connection lifecycle management.
- Server address and username are not yet persisted. No server API request or authentication test is performed.
- The Keychain implementation still requires successful iOS and tvOS CI builds and device-level verification before it is considered validated.


## 2026-11-18 — Saved provider connection profiles

- Added a Codable profile store for non-secret connection metadata (provider, server URL, username and creation date). Profiles persist locally across app launches.
- The connection screen now lists saved profiles, can load one for editing, and can remove a profile together with its Keychain credential.
- Saving a profile stores the password separately in Keychain; passwords are not part of the Codable profile or UserDefaults payload.
- Keychain credential identity now includes provider, normalized server URL and case-preserved username, preventing collisions when the same account name is used on different servers.
- The form clearly distinguishes local validation and local persistence from a real server authentication test. No provider API request is made yet.
- CI validation for these latest changes is pending; device-level Keychain verification remains outstanding.


## 2026-11-18 — First Xtream API adapter

- Added an Xtream Player API adapter using the documented `/player_api.php` authentication response and `get_live_categories` / `get_live_streams` actions.
- Authentication checks the returned `user_info.auth` flag and reports inactive account status separately where the server supplies it.
- Added typed live category and channel response models. Empty artwork URLs are tolerated.
- Requests use URLComponents/URLQueryItem for parameter encoding, a bounded timeout and JSON response validation. Credentials are not written to application logs or persisted by the API adapter.
- Added a real “Testa serverinloggning” action to the connection form for Xtream profiles. Jellyfin is explicitly not supported by this test yet.
- The adapter can fetch live categories and streams, but those results are not yet wired into the Live TV UI. EPG, VOD, series and playback URL handling remain future work.
- Xtream-compatible panels vary; validation against a real provider account and device testing are still required. HTTP servers are accepted by local validation, so users should prefer HTTPS where their provider supports it.
- API shape reference used: Xtream Player API overview and live category/stream endpoint references (worldofiptvcom/xtream-codes-api).
- CI for the new adapter and UI action is pending.


## 2026-11-18 — Live TV wired to Xtream catalogue

- Live TV now checks the locally saved connection profiles for the first Xtream profile and reads its password from Keychain.
- When credentials are available, the screen requests live categories and live streams through the new Xtream adapter and replaces the fixture channel list with returned provider channels.
- Category chips are populated from the provider response; selecting a category filters the returned channel list. The favourites filter and per-channel favourite control remain available in this first integration pass.
- Added loading, refresh, missing-profile, missing-credential and request-error states.
- Programme now/next and progress are deliberately not fabricated: the current screen labels EPG data as pending until a real EPG endpoint/parser is implemented.
- This first pass loads the first saved Xtream profile only. Multi-profile source selection, persisted favourites, pagination/caching and real-device/provider compatibility tests remain open.
- Latest Live TV integration commits are awaiting GitHub Actions results.


## 2026-11-18 — On-demand Xtream EPG

- Added `get_short_epg` support to the Xtream adapter, including bounded result limits and decoding of base64 programme title/description fields and Unix timestamps.
- Tapping a provider channel name in Live TV now expands an on-demand programme panel and requests that channel's short EPG. Results are held in view memory for the current screen session to avoid repeated requests.
- Added loading, empty and request-error feedback. The panel displays programme start times and available descriptions.
- EPG is fetched per channel only when requested; the app does not issue one network request per channel during initial catalogue loading.
- This is a short per-channel EPG view, not yet a full multi-channel timeline/grid. EPG coverage and response variations differ between Xtream panels and require real-provider validation.
- CI runs for the new Xtream EPG and Live TV changes remain queued; no successful build result is available yet.


## 2026-11-18 — Xtream EPG response compatibility hardening

- Updated `XtreamEPGProgram` to accept EPG IDs as either strings or integer values.
- Updated start/stop timestamp decoding to accept JSON strings, integers and floating-point numbers.
- Replaced random UUID fallback IDs with a deterministic identity based on programme start, end and title, so repeated decoding does not change row identity when a provider omits the EPG ID.
- Kept Base64 decoding with plain-text fallback for programme titles and descriptions.
- This is a defensive compatibility improvement; actual response variations still need validation against the user's provider.
- Full multi-channel EPG timeline/grid remains pending. The current UI fetches short EPG on demand for one selected channel and does not yet provide a synchronized timeline.
