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
Define an engine-independent playback contract. Player engines are replaceable adapters behind it; feature views must not depend on AVPlayer, KSPlayer or MPV types.

The contract should expose:
- Load/start, pause, resume, seek and stop.
- Current playback state: preparing, buffering, playing, paused, ended and failed.
- A normalized error category and user-safe diagnostic message.
- Available audio and subtitle tracks, selected track IDs and track-selection operations.
- Live/DVR state and seekable ranges when the active source/engine provides them.
- Current position, duration and periodic progress events where meaningful.

The current implementation has an AVPlayer-backed prototype and coordinator. It is a baseline adapter, not the final format-compatibility decision. Keep it for native HLS and formats where Apple's media stack is suitable. KSPlayer remains a candidate, not an adopted dependency, until its exact licence, package distribution and toolchain are cleared.
- Add an Infuse hand-off adapter using its documented URL integration where supported. Treat external-player progress as best-effort: only report actual position/completion when Infuse returns reliable callback data. Never infer completion merely because the app was opened.
- Playback UI, progress tracking, subtitles and BingeLog integration must not depend directly on KSPlayer-specific types.

### Subtitles
Create a shared SubtitleService and SubtitlePreference model, independent of playback engine.

- User-configurable ordered language preferences (for example Swedish, then English).
- Prefer compatible embedded tracks when configured; otherwise search external sources such as OpenSubtitles.
- Match by stable media identifiers, episode metadata and release/file hash when available; rank uncertain matches conservatively. Never auto-select an unverified title-only match.
- Cache downloaded subtitle assets with bounded storage and source attribution.
- Support manual selection, sync offset and supported styling controls.
- Pass the selected subtitle to the active engine using its supported API. The engine must explicitly advertise external subtitle support; a downloaded file is not playable merely because it exists locally.
- For Infuse hand-off, pass a subtitle URL only where the integration supports it.
- Validate OpenSubtitles API access, authentication, quotas and terms before implementation. Never commit API credentials.

Current foundation: SubtitleService protocol, SRT/WebVTT format model, search query/candidate/asset value types, ordered language preferences and conservative candidate ranking are implemented and unit-tested. No provider adapter, downloader/cache, subtitle injection into a player engine or OpenSubtitles integration exists yet.

### Watch tracking and BingeLog integration
NEXUS is the playback event source; BingeLog is the user's viewing-history and tracking destination.

- Emit a normalized event contract for start, pause, resume, periodic progress, stop, completion and external-player hand-off.
- Identify media with canonical NEXUS IDs plus stable external IDs (TMDB/IMDb where available), and include season/episode identity for series.
- Persist an outbox locally so events survive app termination and network loss. Use idempotency keys to prevent duplicate watch history.
- Keep "in progress", "completed" and "abandoned/unknown" distinct. Completion requires a verified threshold or authoritative player completion signal, not just a start event.
- Sync progress periodically and on lifecycle transitions; avoid excessive writes.
- BingeLog currently uses local-first SwiftData models: `BingeEntry` (TMDB ID + movie/TV kind), `BingeEpisodeProgress` (series TMDB ID + season/episode) and `BingeWatchEvent` (local activity). It has no implemented remote sync transport today.
- Map NEXUS media to BingeLog using TMDB ID and media kind; map episodes using series TMDB ID + season + episode. Do not title-match automatically when stable IDs are missing or ambiguous.
- Use a documented, versioned integration contract between NEXUS and BingeLog. Do not assume two apps can share a local database. A shared backend or CloudKit-based sync must be designed and implemented before cross-device app-to-app sync can work.
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


### Player engine evaluation — KSPlayer (research gate, not an adoption decision)

- The upstream KSPlayer project advertises iOS and tvOS support and documents a Swift Package Manager integration. Its README states that the default distribution is GPL-3.0 and that a paid LGPL variant or separately negotiated licence is available. The README also describes different delivery forms for the GPL and LGPL variants; the exact terms and package artefacts must be confirmed with the maintainer before any dependency is added.
- NEXUS is not cleared to adopt the default GPL distribution. Do not add KSPlayer, its binary frameworks or FFmpeg dependencies until the intended distribution model and written licence terms have been reviewed and approved.
- Inspected the exact upstream 5.6.2 tag: its Package.swift declares Swift tools 6.2, includes a binary KSPlayer framework target and references FFmpegKit. NEXUS currently builds with Swift 5.9 settings, so this exact tag is not a drop-in dependency.
- The AVPlayer prototype now exists and its iOS/tvOS simulator builds and unit tests pass. The next engineering step is to expand the engine contract for track selection, live state and normalized errors, then assess a legally usable KSPlayer distribution or another engine. Do not claim real-stream compatibility until tested on target hardware. Evaluate KSPlayer only after licence and toolchain gates are cleared.
- No codec, HDR, Dolby audio, subtitle or physical-device capability is inferred from the project's feature claims. Validate each required combination on actual iPhone and Apple TV hardware.
