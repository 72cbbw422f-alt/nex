# Architecture

## Targets

Use a single Xcode project with three app targets:
- NEXUS-iOS (iPhone)
- NEXUS-iPadOS (iPad; may share the iOS target with adaptive layouts)
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

### Playback
Define a PlaybackCoordinator protocol independent of UI. AVPlayer is the initial implementation for supported formats/protocols. Evaluate MPV as an optional engine after a real-world compatibility test matrix. Do not promise direct play, HDR, Dolby formats, subtitles or codec support until verified on each device/OS combination.

### Persistence and security
- Keychain: credentials, API tokens and sensitive connection details.
- SQLite: normalized catalogue, source mappings, watch progress, favourites and cache metadata.
- Artwork cache: bounded, evictable disk cache.
- Never log credentials, authorization headers, full secret-bearing stream URLs or user identifiers.

## Networking

Use URLSession with async/await, typed request/response models, cancellation, retry policies for safe requests, pagination where supported, and explicit timeout/error mapping. Avoid hard-coding undocumented endpoints until validated against the user's actual services.

## Sync

Initial sync is user-triggered and incremental where source APIs permit. Keep source sync state separate. A failed source must not block browsing data already cached from another source.

## Testing

- Unit tests: normalization, matching, URL construction, progress mapping, decoding.
- Contract tests: sanitized fixtures from Xtream and Jellyfin-compatible APIs.
- Playback tests: representative HLS, direct HTTP, containers, codecs, audio and subtitle combinations.
- UI tests: iPhone, iPad and tvOS navigation/focus.
- Security tests: ensure secrets are not written to logs or repository.
