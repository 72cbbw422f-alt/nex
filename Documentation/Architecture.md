# Architecture

## Targets

Use a single Xcode project with three app targets:
- NEXUS-iOS (iPhone)
- NEXUS-iPadOS (iPad; shared iOS target with adaptive layouts)
- NEXUS-tvOS (Apple TV)

Share platform-independent domain models, networking, source adapters, persistence contracts and playback coordination through Swift packages or shared target groups. Keep platform-specific navigation and playback presentation separate where needed.

## Layers

### Presentation
SwiftUI feature views and view models. Adapt navigation:
- iPhone: tab-based navigation and compact detail layouts.
- iPad: adaptive split navigation and richer multi-column browsing.
- tvOS: focus-driven navigation, large artwork and remote-friendly controls.

### Domain
Canonical entities:
- MediaItem: stable internal ID, media kind, title, original title, year, synopsis, artwork references, external IDs.
- MediaSourceItem: provider, source-specific ID, parent/series IDs, availability state.
- PlaybackVariant: source ID, stream locator (runtime only), container/codec/resolution/audio/subtitle hints when known.
- WatchProgress: canonical item ID plus source-specific resume data and timestamps.
- PlaybackSession: session ID, canonical media ID, source/variant, player type, start/end timestamps, current position, duration and completion state.
- PlaybackEvent: started, paused, resumed, periodic progress, ended, failed and handed-off events. Events must be idempotent and timestamped.

### Source adapters
- XtreamAdapter: authentication, live categories/channels, VOD, series, EPG and playback locator construction.
- JellyfinAdapter: Jellyfin-compatible authentication, libraries, items, metadata, images, playback information and progress APIs.
- AIOStreams is treated as a source of stream variants exposed through the configured Jellyfin-compatible integration. Validate the actual deployment's API behavior before implementation.

### Unified catalogue
Normalize provider records into domain entities. Match in this order:
1. Stable external IDs (TMDB/IMDb when present).
2. Provider metadata IDs only within their own provider.
3. Conservative title + year + media-kind matching.
4. Uncertain matches remain separate and may be manually linked later.

Keep provenance for every field and every playback variant. Do not assume IPTV and Jellyfin use identical metadata or identifiers.

### Playback architecture
Define a PlaybackCoordinator protocol independent of UI and player engine. Player engines are replaceable adapters behind this protocol.

- Evaluate KSPlayer as the preferred embedded engine for iOS, iPadOS and tvOS. Before committing, run a focused technical spike covering the exact KSPlayer package/components, platform support, Swift/Xcode compatibility, licensing obligations and required build configuration. Do not claim codec/HDR/audio support until verified on physical target devices.
- Keep an AVPlayer adapter available for native HLS and formats where it is the more reliable option.
- Add an Infuse hand-off adapter using its documented URL integration where supported. Treat external-player progress as best-effort: only report actual position/completion when Infuse returns reliable callback data. Never infer completion merely because the app was opened.
- Playback UI, progress tracking, subtitles and BingeLog integration must not depend directly on KSPlayer-specific types.

### Subtitles
Create a shared SubtitleService and SubtitlePreference model, independent of playback engine.

- User-configurable ordered language preferences (for example Swedish, then English).
- Prefer compatible embedded tracks when configured; otherwise search external sources such as OpenSubtitles.
- Match by stable media identifiers, episode metadata and release/file hash when available; rank uncertain matches conservatively.
- Cache downloaded subtitle assets with bounded storage and source attribution.
- Support manual selection, sync offset and supported styling controls.
- Pass the selected subtitle to the active engine using its supported API. For Infuse hand-off, pass a subtitle URL only where the integration supports it.
- Validate OpenSubtitles API access, authentication, quotas and terms before implementation. Never commit API credentials.

### Watch tracking and BingeLog integration
NEXUS is the playback event source; BingeLog is the user's viewing-history and tracking destination.

- Emit a normalized event contract for start, pause, resume, periodic progress, stop, completion and external-player hand-off.
- Identify media with canonical NEXUS IDs plus stable external IDs (TMDB/IMDb where available), and include season/episode identity for series.
- Persist an outbox locally so events survive app termination and network loss. Use idempotency keys to prevent duplicate watch history.
- Keep "in progress", "completed" and "abandoned/unknown" distinct. Completion requires a verified threshold or authoritative player completion signal, not just a start event.
- Sync progress periodically and on lifecycle transitions; avoid excessive writes.
- Use a documented, versioned integration API between NEXUS and BingeLog. Do not assume two apps can share a local database. Evaluate a shared backend or CloudKit-based sync after inspecting BingeLog's actual architecture.
- Cross-device resume must reconcile timestamps and positions deterministically. Define conflict rules before enabling multi-device writes.
- Infuse progress is best-effort and must be marked with its provenance and confidence.

### Persistence and security
- Keychain: credentials, API tokens and sensitive connection details.
- SQLite: normalized catalogue, source mappings, watch progress, playback sessions, event outbox, subtitle cache metadata and favourites.
- Artwork and subtitle cache: bounded, evictable disk caches.
- Never log credentials, authorization headers, full secret-bearing stream URLs or user identifiers.
- Keep API secrets out of source control and sample configuration.

## Networking

Use URLSession with async/await, typed request/response models, cancellation, retry policies for safe requests, pagination where supported, and explicit timeout/error mapping. Avoid hard-coding undocumented endpoints until validated against the user's actual services.

## Sync

Initial sync is user-triggered and incremental where source APIs permit. Keep source sync state separate. A failed source must not block browsing data already cached from another source. Playback events use a durable outbox and retry independently from catalogue sync.

## Testing

- Unit tests: normalization, matching, URL construction, progress mapping, event idempotency, completion thresholds and decoding.
- Contract tests: sanitized fixtures from Xtream, Jellyfin-compatible APIs, OpenSubtitles and BingeLog sync.
- Playback tests: representative HLS, direct HTTP, containers, codecs, audio and subtitle combinations.
- Player hand-off tests: Infuse open, callback, resume position and failure behavior.
- UI tests: iPhone, iPad and tvOS navigation/focus.
- Security tests: ensure secrets are not written to logs or repository.
