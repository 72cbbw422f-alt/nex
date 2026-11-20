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


## 2026-11-18 — First multi-channel EPG timeline prototype

- Added a dedicated timeline section above the channel browser in Live TV.
- The user can explicitly load programme data for the currently visible channel group; requests are sequential and capped at 8 channels per load to avoid a burst of provider API calls.
- Each channel row displays returned programme titles and start times. Programme card width is proportional to its returned duration when both timestamps exist; missing timestamps use a fixed fallback width.
- Existing per-channel EPG expansion remains available.
- This is an initial multi-channel visual prototype, not yet a fully time-aligned EPG grid: rows do not share a common clock origin, and a live-now marker, scrolling time ruler, pagination and provider-specific response validation remain outstanding.
- The timeline requires a saved Xtream connection and credentials in Keychain; no sample programme times are presented as real provider data.


## 2026-11-18 — Shared EPG clock axis

- Reworked the multi-channel programme rows to position each returned programme by its actual start time on one shared six-hour window beginning at the current hour.
- Added a shared hour ruler and a vertical current-time marker within the current hour.
- Programme cards are clipped to the visible six-hour window and their widths follow the returned programme duration.
- The timeline still only shows channels whose on-demand short EPG has been loaded, with the existing maximum of eight channel requests per load.
- Remaining work: paging/scrolling across time windows, handling overlaps and gaps more gracefully, real-provider validation, and testing on device sizes. The current marker is a visual clock indicator; it does not infer whether a programme is actually live when provider EPG data is missing.


## 2026-11-18 — EPG timeline build correction

- The first CI build of the shared six-hour timeline exposed an incorrectly escaped Swift key-path expression in the hour ruler (`ForEach` identity).
- Corrected the expression to the native Swift key-path form.
- A new CI run is required to validate the correction; no successful build is claimed yet.


## 2026-11-18 — Persisted Live TV favourites

- Replaced the provider-backed Live TV favourites' view-only behavior with UserDefaults persistence.
- Favourite sets are scoped by provider type, normalized server address and username, so different Xtream profiles do not share channel IDs accidentally.
- When no provider profile exists, the sample preview retains its two illustrative favourites; loading a provider profile restores only that profile's saved favourites.
- Favourite channel IDs are stored as a sorted integer array. No credentials are included in the preference key or stored value.
- CI validation is pending. Real-provider testing and profile-switching verification remain outstanding.


## 2026-11-18 — EPG timeline time-window navigation

- Added previous/next controls that shift the shared six-hour timeline in six-hour increments, plus a Nu control to return to the current window.
- The visible date is shown in the timeline heading.
- Moving to another window clears the in-memory EPG cache for the visible timeline channels and requests fresh short-EPG data for the selected window.
- Xtream `get_short_epg` does not accept a requested start timestamp in this adapter. Providers may therefore return only their current/upcoming listings; historical-window coverage is not guaranteed. This remains a provider-specific validation item rather than a claim of full historical EPG support.
- CI validation is pending.


## 2026-11-18 — Live TV channel logos

- Added provider-supplied channel artwork to the channel browser and multi-channel EPG labels using SwiftUI AsyncImage.
- Added a neutral TV glyph fallback for channels with no logo URL and while artwork is unavailable or fails to load.
- No external artwork catalogue or guessed logo mapping is used; only the Xtream stream_icon value is displayed.
- Build validation for the timeline paging and logo changes is pending.


## 2026-11-18 — EPG current-time marker correction

- Corrected the red current-time marker to use the selected six-hour window's actual elapsed time rather than the current minute within every window.
- The marker now appears only when the real current time falls inside the displayed six-hour interval; historical and future windows no longer show a misleading marker at the same horizontal position.
- Programme block positioning and provider data behavior are unchanged. Overlapping programme layout, gaps and historical EPG availability remain open items.
- CI validation is pending.


## 2026-11-18 — EPG overlap layout and timeline gaps

- Reworked each channel's six-hour EPG row to allocate overlapping programmes to separate vertical lanes instead of drawing them on top of one another.
- Rows now grow to fit the number of overlapping lanes; programme blocks retain their timestamp-based horizontal positions and are clipped to the selected six-hour window.
- Empty time remains visibly unoccupied on a subtle lane track rather than being filled with fabricated programme data. Invalid or zero-length intervals are excluded.
- The lane allocator uses programme start/end timestamps and reuses a lane once its previous programme has ended.
- CI validation and real-provider testing are pending. Dense schedules may increase row height; visual refinement on iPhone and iPad remains outstanding.


## 2026-11-18 — Compact EPG programme card readability

- Added a minimum readable width for short programme cards so brief listings do not collapse into near-zero-width blocks.
- The lane allocator now reserves the same minimum visual interval when checking collisions, preventing compact cards from covering the next programme in the same lane.
- Actual programme start/end timestamps and the displayed timeline duration remain unchanged; the extra width is a presentation aid only. Short programmes may therefore occupy an additional lane when needed.
- CI and device-size validation are pending. The timeline remains horizontally scrollable on narrow screens.


## 2026-11-18 — EPG response caching and build correction

- Corrected two malformed Swift key-path expressions in the EPG timeline lane layout that caused the iOS simulator build to fail.
- Added a five-minute in-memory freshness window for short-EPG responses. Reopening a channel or loading the timeline again within that window reuses the response instead of repeating the same Xtream request.
- Paging the six-hour timeline no longer clears already fetched EPG data. Cached programme intervals are clipped against the selected window; this improves reuse but does not create historical listings that the provider has not returned.
- Cache entries are invalidated when the active server address or username changes. Failed requests are also held for up to five minutes to avoid rapid repeated calls to an unavailable endpoint.
- The fix and cache implementation are committed on `project-foundation`. CI validation is pending; no successful build is claimed yet.


## 2026-11-18 — Compact iPhone Live TV layout

- Added width-class-aware sizing to the Live TV screen while retaining the approved navy/violet visual direction.
- On compact-width devices, reduced outer spacing and the channel label column, and tightened the six-hour timeline scale and minimum programme-card width so more guide content is visible without horizontal scrolling.
- Kept the horizontal timeline scroll available for full programme detail; regular-width layouts retain the wider dimensions.
- Simulator build validation is pending.


## 2026-11-18 — Live TV channel EPG panel refinement

- Reworked the expanded channel programme panel into distinct, high-contrast programme rows with a fixed time column, title and optional two-line synopsis.
- Displayed both start and end times when the provider supplies them, while retaining safe placeholders for incomplete EPG records.
- Added explicit loading, empty-provider-data and cached-state labels so opening a channel does not leave an ambiguous blank panel.
- Kept the existing five-programme limit and the approved navy/violet design language. Build validation is pending.


## 2026-11-18 — Live TV EPG error-state handling

- Distinguished a successful empty EPG response from a failed provider request in the expanded channel panel.
- Successful empty responses retain the five-minute cache lifetime; failed requests display the provider error and use a shorter one-minute retry window.
- A successful retry clears the stored channel error. EPG error state is cleared together with cached programme data when the active Xtream profile changes.
- Aligned the channel label column width across the compact channel list, guide header and timeline rows using the shared responsive width value.
- The preceding alignment commit passed both iOS and tvOS simulator builds. The EPG error-state change is awaiting CI and real-provider validation.


## 2026-11-18 — Profile-scoped EPG cache and stale-request guards

- Replaced channel-ID-only EPG cache keys with a composite key containing provider, normalized server address, username and channel ID. Programme data, fetch timestamps and error state now use the same profile-scoped key.
- Corrected all cache reads and writes to use the composite key consistently, including the timeline, channel panel and timeline channel filtering.
- Timeline loading captures the selected category and active profile before making requests. It stops applying results/status text if the profile or category changes while requests are in flight.
- Expanded-channel EPG requests now use a request token and capture the profile-scoped cache key before awaiting the provider. Late responses cannot overwrite the active profile's cache, and a superseded request cannot clear the newer request's loading indicator.
- The composite-cache implementation passed both iOS and tvOS simulator builds. The stale-request guard commit is awaiting CI and still needs real-provider/device validation.


## 2026-11-18 — Live TV EPG request isolation and channel refresh guards

- Confirmed the profile-scoped EPG cache and stale-request guard changes pass both iOS and tvOS simulator builds.
- Added request identity to channel/category refreshes. When a newer refresh starts, an older response or error can no longer replace its channel list, category list or status message.
- The loading indicator is now cleared only by the refresh that owns the current request token, preventing an older completion from making a newer refresh appear idle.
- Profile changes clear EPG panel request/loading state as well as the profile-scoped EPG cache.
- The restored Live TV view and refresh-guard commit are awaiting their own iOS/tvOS CI run. Real-provider testing and device validation remain outstanding.


## 2026-11-18 — Xtream retry handling and timeline request ownership

- Added a single bounded retry for selected transient URLSession connectivity failures and HTTP 5xx responses, using a 500 ms backoff. Authentication failures, HTTP 4xx responses, invalid JSON and other non-transient errors are not retried.
- Added a unique request token to the six-hour EPG timeline loader. Superseded timeline requests can no longer write cache results/errors, overwrite status text or clear the loading indicator owned by a newer request.
- Timeline response application now verifies the active provider, server and username as well as the request token.
- Concurrent requests for the same EPG channel from the timeline and expanded channel panel are not yet deduplicated; that remains the next networking refinement.
- GitHub Actions validation is pending. Real Xtream-provider and physical-device behavior remain unverified.


## 2026-11-18 — Shared in-flight EPG request coordination

- Added an actor-based coordinator for short-EPG requests, keyed by provider, normalized server, username and channel ID.
- The six-hour timeline and expanded channel panel now share the same in-flight request when they ask for the same channel at the same time. This prevents duplicate API calls during overlapping UI activity.
- Existing profile-scoped cache behavior and freshness windows remain responsible for reuse after a request completes.
- Marked the provider request values and EPG response models Sendable for the concurrency boundary.
- iOS/tvOS CI validation is pending; real-provider behavior remains to be verified.


## 2026-11-18 — Xtream live playback locator foundation

- Extended the live stream response model to retain the optional `container_extension` supplied by the provider.
- Added a dedicated Xtream live playback locator for the `/live/{username}/{password}/{stream_id}.{extension}` URL shape.
- The locator rejects missing or malformed extensions instead of assuming a stream format. It percent-encodes credentials as individual path segments and does not log or persist the generated URL.
- This change only constructs a candidate URL. It does not establish that a provider accepts the path, that a stream is playable, or that a player engine supports its codec/container.
- iOS/tvOS CI and verification against a real provider are pending.


## 2026-11-18 — Harden Xtream playback URL construction

- Tightened URL validation to require a non-empty username/password, a positive stream ID, and an HTTP(S) base URL with a host.
- Restricted credential path-segment encoding to RFC 3986 unreserved ASCII characters, ensuring non-ASCII characters are percent-encoded rather than being passed through by Unicode alphanumeric character sets.
- GitHub Actions iOS and tvOS simulator builds passed for this source change.
- The generated URL remains sensitive runtime data; real-provider acceptance and physical-device playback are not yet verified.


## 2026-11-18 — KSPlayer player-engine evaluation

- Reviewed the upstream KSPlayer repository and package information. The project advertises iOS and tvOS support, but its README says the default distribution is GPL-3.0; an LGPL variant is offered under paid terms, with separate licensing discussions also possible.
- NEXUS will not add the dependency until licensing and distribution obligations are explicitly resolved.
- The current upstream main Package.swift declares Swift tools 6.2, while NEXUS currently uses Swift 5.9 build settings. Exact release/tag compatibility must be checked before any package integration.
- Decision for the next prototype: validate native AVPlayer with a known HLS sample behind an engine-independent playback interface. KSPlayer remains a candidate only after the legal and toolchain gates.
- No real-provider stream, physical device, codec, HDR, Dolby audio or subtitle capability has been validated by this research.


## 2026-11-18 — Playback coordinator concurrency correction and test target

- Added an XCTest target for the Xtream playback locator with coverage for URL construction, path preservation, reserved/Unicode credential encoding, malformed or missing extensions, and invalid inputs.
- Added an AVPlayer-backed engine behind the engine-independent playback coordinator.
- CI exposed a Swift actor-isolation error caused by constructing the default AVPlayer engine in a default argument. Replaced that default argument with a dedicated main-actor initializer and retained explicit engine injection for tests.
- The initial CI run confirmed the actor-isolation issue. The follow-up workflow run was cancelled before a usable build/test result was produced; the corrected code is therefore not yet marked CI-verified.


## 2026-11-18 — Xtream locator test findings and absolute-path fix

- The first XCTest execution ran all four cases: two passed and two failed because the locator returned `invalidURL` for valid server URLs.
- Root cause: assigning a relative value to `URLComponents.percentEncodedPath` produced an invalid URL. The builder now explicitly prefixes the assembled path with `/`, while preserving any existing server base path.
- The corrected source is committed on `project-foundation`. The follow-up iOS/tvOS build and XCTest run is queued; this fix is not yet marked verified.


## 2026-11-18 — Xtream locator tests pass; PlaybackCoordinator tests added

- The corrected Xtream locator source passed the complete GitHub Actions workflow: iOS Simulator build, tvOS Simulator build and the four XCTest cases.
- The URL builder now has CI-verified coverage for base-path preservation, reserved and Unicode credential encoding, extension validation and invalid input.
- Added a fake PlaybackEngine test double and four PlaybackCoordinator tests covering URL load/play ordering, pause/resume forwarding, seek forwarding and state passthrough.
- The new coordinator tests are committed on `project-foundation`; their CI run is pending.
- These tests exercise orchestration only. They do not verify network stream acceptance, codec compatibility or real playback on a physical device.


## 2026-11-18 — First Live TV playback surface and CI correction

- Added the first AVPlayer-backed full-screen playback view and connected provider-backed Live TV channel rows to it.
- The player obtains the Xtream password from Keychain at runtime and keeps the candidate stream URL in transient view state only.
- An initial CI run compiled an older commit containing literal escaped newline sequences in the LiveView playback model declaration. The source was corrected on `project-foundation`; the latest branch file now contains normal Swift line breaks.
- The CI run for the corrected branch head has not yet completed. Do not treat the player integration as build-verified until a fresh run passes.
- Playback remains unverified against a real provider and physical iPhone/iPad/Apple TV. AVPlayer format compatibility, loading/error feedback, audio/subtitle selection and tvOS remote behavior remain follow-ups.



## 2026-11-18 — Playback status handling passes CI; KSPlayer compatibility review

- The AVPlayer playback surface now observes AVPlayerItem status and AVPlayer time-control status. It displays connection/buffering feedback, surfaces item failure descriptions, offers a retry action, and pauses/cleans observations when dismissed.
- The complete GitHub Actions workflow passed for this change: Xcode project generation, iOS Simulator build, tvOS Simulator build and iOS unit tests.
- Rechecked upstream KSPlayer documentation and the exact 5.6.2 tag. KSPlayer advertises iOS/tvOS support and broader FFmpeg-backed format and subtitle capabilities, but its own documentation says the default distribution is GPL-3.0 and a paid LGPL/commercial licensing route is available. Do not integrate the default package into NEXUS without an explicit licensing decision.
- The exact 5.6.2 Package.swift declares Swift tools 6.2 and includes binary KSPlayer framework targets plus FFmpegKit dependencies. This is not compatible with the current NEXUS Swift tools 5.9 project configuration as-is. The release tag does not remove the toolchain gate.
- KSPlayer is described upstream as based on AVPlayer and FFmpeg; it should be evaluated as a richer engine/framework layer, not assumed to be a wholly separate replacement for Apple's media stack.
- Decision: retain the engine abstraction and current native prototype while evaluating a legally usable KSPlayer distribution or alternative engine. No package dependency was added. Next engineering work should be to define the engine capability surface (tracks, subtitle selection, seek/live state and playback errors) without leaking engine-specific types into feature views.
- Real Xtream provider playback and physical-device codec compatibility remain unverified.


## 2026-11-18 — Embedded audio and subtitle selection in the player

- Added AVPlayer media-selection loading for embedded audible and legible tracks, with stable per-item IDs and selected-state metadata.
- Added audio and subtitle selection through the engine-neutral playback coordinator. Subtitle selection supports explicitly disabling the selected embedded subtitle track.
- Connected the track list to the full-screen player UI. The controls appear after track discovery, show available track counts, and provide explicit status labels when the source exposes no audio alternatives or no subtitle tracks.
- The first menu UI CI run exposed an incorrectly escaped Swift key-path expression. The expression was corrected using an explicit closure; the corrected branch-head workflow passed Xcode project generation, iOS Simulator build, tvOS Simulator build and all iOS unit tests.
- This verifies compilation and existing coordinator tests, not actual track switching against a live Xtream provider or on physical hardware. Track availability remains dependent on the media source exposing AVPlayer-compatible media-selection groups.
- External subtitle-file loading, subtitle search/download, synchronization offset and provider-specific playback compatibility are not implemented by this change.


## 2026-11-18 — External subtitle service foundation

- Added engine-neutral subtitle domain types for SRT/WebVTT, movie/series search identity, subtitle candidates, downloaded assets and ordered language preferences.
- Added a provider-neutral async SubtitleService contract for search and download. No provider credentials, API calls or network adapter are included.
- Added conservative candidate ranking: media kind and TMDB ID must agree when supplied; series season/episode must match; language order is respected; exact file hash outranks exact release-name evidence.
- Tightened matching so an item without a TMDB ID requires an exact file-hash or release-name match. Candidates with no reliable identity evidence are not auto-matched.
- Added unit tests for format recognition, language ordering, wrong media/episode rejection, hash ranking and ambiguous-match rejection.
- CI for the initial subtitle foundation passed iOS Simulator build, tvOS Simulator build and iOS unit tests. The stricter matching safeguard and added test have a new CI run pending.
- Kept external subtitle playback explicitly unimplemented. AVPlayer embedded media selection does not provide a generic sidecar SRT/VTT injection path; an engine must expose and implement that capability before downloaded files can be selected for playback.
- No OpenSubtitles integration, download/cache implementation, subtitle sync UI or physical-device playback validation has been added.


## 2026-11-18 — Playback engine research gate

- Compared AVPlayer, VideoLAN VLCKit 4.x, KSPlayer 5.6.2 and libmpv/mpv-ios for iOS/iPadOS/tvOS support, external subtitles, codec breadth, package/toolchain fit and licensing.
- Added Documentation/PlaybackEngineEvaluation.md with evidence, risks, comparison matrix and a proposed isolated technical spike.
- Research points to VLCKit 4.x as the first candidate to test: VideoLAN explicitly documents iOS/tvOS and LGPL 2.1+, its current SPM manifest uses Swift tools 5.9, and the official VLC iOS app attaches external subtitles through libVLC's media-slave API. The current SPM artifact is an unstable 4.0 binary, so package stability and all device slices remain unverified.
- KSPlayer remains a feature-rich alternative but its default distribution is GPL-3.0, the LGPL route is paid and not yet licensed, and its current Package.swift requires Swift tools 6.2 plus FFmpegKit.
- mpv-ios is currently documented as an iOS implementation, not a complete tvOS target; its XCFramework requires a macOS/Xcode build and its libmpv dependency stack has separate GPL/LGPL obligations.
- AVPlayer remains the native fallback for compatible media and embedded tracks; Apple marks the older external subtitle language properties deprecated.
- No engine dependency was added and no final engine decision was made. Next step is an isolated VLCKit package/build/API spike, followed by real-device subtitle and stream tests and a distribution licence review.


## 2026-11-19 — VLCKit audit documentation cleanup and baseline CI confirmation

- Reconciled the main VLCKit evidence section with the latest upstream Package.swift observation: the current manifest points to the November 9, 2026 unstable binary and checksum. The August 31 reference is retained only as historical audit context, not as the current manifest target.
- Checked the GitHub Actions run for commit `86617d2104827c2de5f01cfcbf3e6d300f0500d1`: project generation, iOS Simulator build, tvOS Simulator build and iOS unit tests all completed successfully.
- This successful run validates the existing NEXUS baseline only; it does not download or inspect the 910 MB VLCKit archive and does not validate physical-device playback.
- Next gate remains a bounded HTTP Range/ZIP metadata inspection of the exact pinned archive. The inspection must fail closed if the server does not honor byte-range requests, so CI never falls back to downloading the full archive unintentionally. If the archive can be inspected safely, verify the actual XCFramework platform/architecture slices before considering a minimal isolated package-resolution/build spike.
- No playback dependency was added, no engine was selected, and the AVPlayer implementation remains unchanged.


## 2026-11-19 — Bounded ZIP inspector and parser tests

- Added a Python standard-library tool that reads the ZIP end-of-central-directory record and central-directory listing through bounded HTTP Range requests. It requires HTTP 206 and validates Content-Range, response length and stable total size; HTTP 200 is treated as Range refusal and the response is closed without a full-download fallback.
- The first-stage tool has a 65,557-byte tail limit and a 32 MiB central-directory limit. ZIP64 and multi-disk archives fail closed. It inventories XCFramework-related paths but does not yet prove architectures or supported platforms from Info.plist.
- Added offline unit tests for ZIP central-directory parsing, invalid ZIP data, ZIP64 rejection and corrupt directory rejection. The GitHub Actions workflow now runs these Python tests before the Xcode builds.
- The real VideoLAN endpoint has not yet been tested by this script. The latest workflow run will validate the local parser tests and normal app builds only; no VLCKit archive download is part of CI.


## 2026-11-19 — VLCKit remote archive verified at ZIP-directory level

- Added a separate path-filtered GitHub Actions workflow, `.github/workflows/vlckit-audit.yml`, to run the bounded archive inspection on Ubuntu without coupling the 910 MB package to the normal Xcode build.
- The exact VideoLAN November 9 archive passed the bounded HTTP Range audit. The runner received HTTP 206 responses with valid `Content-Range` values and consistent total size; the full archive was not downloaded.
- The ZIP central directory contains all four NEXUS target variants: `ios-arm64`, `ios-arm64_x86_64-simulator`, `tvos-arm64`, and `tvos-arm64_x86_64-simulator`. It also lists macOS, watchOS and visionOS variants.
- Corrected the ZIP64 sentinel unit test to encode the actual EOCD signature. The parser suite had already passed in the preceding runs; the corrected test is included in the next normal build run.
- This is a directory-level finding only. The inspector has not yet extracted or validated XCFramework `Info.plist` metadata, checked Mach-O architectures, resolved VLCKit through SwiftPM, or linked it into an app target.
- No playback engine was selected or integrated. AVPlayer remains unchanged; next gate is targeted `Info.plist` extraction and validation followed by an isolated package/build spike.

## 2026-11-19 — VLCKit XCFramework Info.plist verified

- Extended the bounded ZIP inspector to parse central-directory metadata (compression method, sizes, flags and local-header offset) and fetch selected members using bounded HTTP Range requests.
- The inspector validates local/central ZIP header agreement, supports stored and deflate members, rejects encrypted or unsupported compression, and caps metadata reads at 1 MiB compressed / 4 MiB uncompressed.
- The exact VideoLAN archive's `VLCKit.xcframework/Info.plist` was successfully fetched and parsed in the separate GitHub Actions audit.
- `AvailableLibraries` declares: iOS device arm64; iOS simulator arm64 + x86_64; tvOS device arm64; tvOS simulator arm64 + x86_64. The same XCFramework also contains macOS, watchOS and visionOS variants.
- This is now stronger evidence than directory-name matching: the package's XCFramework manifest declares all four NEXUS target variants. The actual Mach-O binary architecture headers have not yet been inspected, and the package has not yet been resolved/linked in NEXUS.
- Added offline tests for XCFramework metadata fixture parsing and bounded deflate-member extraction. No production dependency was added and no playback engine was selected.
- Next gate: inspect Mach-O headers from small bounded ranges or perform an isolated SwiftPM resolution/build spike, then assess runtime playback and LGPL distribution obligations.


## 2026-11-19 — Mach-O extraction and manifest comparison regression tests

- Added offline regression coverage for reading a stored Mach-O framework executable prefix through bounded ZIP ranges.
- Added tests for matching a thin arm64 Mach-O header against the XCFramework `SupportedArchitectures` declaration and rejecting a deliberate mismatch.
- The tests exercise the extraction/validation helpers without downloading or storing the full VLCKit archive.
- GitHub Actions run for this commit is queued/in progress; results have not yet been recorded.
- The separate live archive audit previously passed, including actual Mach-O architecture-header inspection for the declared XCFramework libraries. This new change strengthens offline regression coverage; it does not resolve or link VLCKit through SwiftPM.


## 2026-11-19 — Explicit playback stop and item teardown

- Added `stop()` to the engine-neutral PlaybackEngine lifecycle contract, with a compatibility default that pauses simple engines.
- The AVPlayer adapter now cancels pending media-selection loading, clears track caches, pauses playback and removes the current AVPlayerItem when stopped.
- PlaybackCoordinator forwards the stop operation, and PlaybackView uses it when its playback session ends.
- Added a fake-engine XCTest for stop forwarding. The CI run for this change is pending; no runtime/device playback claim is made.


## 2026-11-19 — Playback teardown verification and first rendering boundary

- The explicit playback stop lifecycle passed GitHub Actions: iOS Simulator build, tvOS Simulator build and the complete iOS unit-test suite. The new stop-forwarding test passed with the existing tests.
- Extracted `AVPlayerPlaybackSurface` as the only view that directly hosts SwiftUI `VideoPlayer`; `PlaybackView` now composes that surface rather than embedding AVPlayer rendering itself.
- This is an initial rendering seam, not yet a fully engine-neutral surface factory: playback status observation and track selection still use AVPlayer-specific APIs and are the next refactoring targets.
- The source remains AVPlayer-only in production. No VLCKit runtime integration or physical-device playback has been performed.


## 2026-11-19 — Engine-neutral playback state events

- Added an optional `onStateChanged` event to the `PlaybackEngine` contract, with a no-op default for compatibility.
- The AVPlayer adapter now observes item readiness and time-control changes internally and emits state updates; feature UI no longer owns AVPlayer KVO observations.
- PlaybackStatusModel now maps the engine-neutral `PlaybackEngineState` values to loading, buffering, and error presentation.
- Added a coordinator unit test proving state-change notifications are forwarded from the engine.
- CI validation is pending for this change. This refactor does not establish third-party engine playback or physical-device runtime behavior.


## 2026-11-19 — Engine capability contract and external subtitle boundary

- Added an engine-neutral capability OptionSet for seeking, embedded audio selection, embedded subtitle selection and external subtitle support.
- PlaybackCoordinator now exposes the active engine's capabilities. AVPlayer advertises seeking and embedded track selection, but not external subtitle ingestion.
- Added an engine-neutral external subtitle attachment method accepting a local URL and optional language code. Calls are rejected at the coordinator boundary unless the active engine advertises external subtitle support.
- Added fake-engine tests for both unsupported rejection and supported forwarding.
- The capability-contract commit passed iOS Simulator build, tvOS Simulator build and iOS unit tests. The external-subtitle contract commit also passed those checks. The latest test-forwarding workflow run ended as a cancelled job and therefore does not validate the two new tests; a fresh CI run is required.
- No external subtitle is rendered by AVPlayer, and no production VLCKit dependency has been added. Runtime playback and subtitle rendering remain unverified.


## 2026-11-20 — VLCKit spike refreshed on current foundation

- The earlier `spike/vlckit-spm` branch had diverged substantially from the current `project-foundation` branch (30 commits ahead and 29 behind at inspection). Its older Roadmap.md would have overwritten newer playback abstraction, Xtream resilience and Live TV work if merged as-is.
- Created `integration/vlckit-spike-refresh` from the current `project-foundation` head and copied only the isolated VLCKit spike files. Production sources and the current roadmap were left untouched.
- Added an isolated XcodeGen project, pinned VideoLAN binary package, iOS/tvOS host app entry points, media/subtitle probe session, Swedish SRT/WebVTT fixtures and a dedicated GitHub Actions workflow.
- The workflow is configured to build iOS Simulator, tvOS Simulator and generic device host targets. It will download the approximately 910 MB unstable upstream binary when the workflow runs.
- No production dependency or playback path was changed. AVPlayer remains the production engine.
- This refreshed branch has not yet completed CI. Swift/Xcode compilation, runtime media playback, sidecar subtitle rendering, physical-device behavior and licensing remain unverified.


## 2026-11-20 — VLCKit probe build failure analysis and target wiring correction

- The first refreshed VLCKit workflow resolved the pinned SwiftPM binary successfully and generated the Xcode project, but the iOS Simulator build failed because the host app could not resolve the intermediate `VLCKitProbe` framework module.
- Reworked the isolated XcodeGen project so each iOS/tvOS probe host compiles the adapter source directly and links the pinned VLCKit package product. Removed the unnecessary intermediate framework targets and the corresponding app-level module import.
- Corrected the state delegate callback parameter from implicitly unwrapped to non-optional `Notification`, matching the Swift-imported protocol requirement and removing the compiler's near-match warning.
- The first run's failure was a target/module wiring issue, not a package-resolution failure. The follow-up run was cancelled as the branch received subsequent commits; the corrected branch head still requires a fresh complete iOS/tvOS build.
- No production playback source or dependency was changed. AVPlayer remains the production engine. Physical-device playback, sidecar subtitle behavior and distribution licensing remain unverified.


## 2026-11-20 — tvOS probe compile correction

- The next VLCKit CI run successfully resolved the pinned binary and built the iOS Simulator host. The tvOS Simulator host exposed two platform-specific compile errors: SwiftUI's `.roundedBorder` text-field style is unavailable on tvOS.
- Replaced the shared probe text-field style with the cross-platform `.plain` style so the same input UI compiles on iOS and tvOS.
- Moved the optional Objective-C VLCKit delegate callback implementations into a class extension and restored the imported implicitly-unwrapped Notification signature to address the compiler's near-match warning.
- The run stopped at the tvOS Simulator step; device builds were skipped. The latest corrections require a fresh complete CI run. No physical playback, subtitle rendering or production integration is claimed.


- Adjusted the dedicated spike workflow concurrency policy so an in-flight validation is not cancelled merely because another PR synchronization event arrives. This prevents rapid sequential source/documentation commits from repeatedly cancelling the expensive binary-resolution/build job. The next run should be allowed to finish against its triggering revision.

## 2026-11-20 — VLCKit isolated host build verification

- GitHub Actions run #51 completed successfully for commit `f82654e89cf7351ea4271b4692fdd819b80a149b`.
- XcodeGen project generation and resolution of the pinned VideoLAN SwiftPM binary completed successfully.
- All four generic build destinations passed: iOS Simulator, tvOS Simulator, generic iOS device and generic tvOS device. The job completed with success and all ten workflow steps passed.
- The prior tvOS `.roundedBorder` compile issue and the delegate callback warning correction are therefore covered by this successful compile/link run.
- This validates project generation, package resolution and compile/link for the four configured destinations only. It does not prove runtime playback, audio output, external SRT/WebVTT subtitle rendering or synchronization, codec compatibility, performance, signing, physical-device behavior or LGPL/distribution compliance.
- The build log includes a non-blocking Xcode warning that App Intents metadata extraction was skipped because the probe does not depend on AppIntents.framework, plus a GitHub Actions Node.js 20 deprecation warning for actions/checkout@v4. Neither caused the build to fail.
- No production source, production dependency or playback path was changed. AVPlayer remains the production engine.
- Next gate: install/run the isolated probe on physical iOS and tvOS hardware with permitted test media, verify playback and sidecar subtitles, then complete the licensing/distribution review before any production engine decision.
