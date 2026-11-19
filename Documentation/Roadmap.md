# Roadmap

## Phase 0 — Foundation
- [x] Confirm product name and repository
- [x] Confirm iOS, iPadOS and tvOS
- [x] Confirm Nuvio-inspired design direction
- [x] Confirm unified movie/series presentation
- [x] Establish Xcode project and build configurations
- [x] Add CI build workflow for Apple platforms
- [x] Add XCTest target for iOS unit tests

## Phase 1 — Design shell
- [ ] Define NEXUS design tokens and typography
- [x] Lock approved deep-navy, near-black and violet cinematic visual direction
- [ ] Finish adaptive iPhone/iPad navigation and focus-driven tvOS navigation
- [ ] Build reusable poster, backdrop, shelf and detail components
- [x] Add searchable movie and series library grids and connect them to navigation
- [x] Add global search screen
- [x] Add Xtream/Jellyfin connection setup shell
- [x] Add cinematic film/series detail shell
- [x] Add Live TV guide shell and mobile navigation
- [x] Add interactive Live TV category filters and favourites
- [x] Add Apple TV navigation entry points for Home, Live TV, Films, Series and My List
- [ ] Replace remaining sample catalogue/EPG content with provider data

## Phase 2 — Xtream connector
- [x] Persist non-secret connection profiles and passwords separately in Keychain
- [x] Add Xtream Player API authentication and live category/channel adapter
- [x] Wire live category/channel results into Live TV with loading/error states
- [ ] Validate authentication and response compatibility against real Xtream providers
- [ ] Add VOD movies and categories
- [ ] Add series, seasons and episodes
- [x] Add on-demand short EPG retrieval and per-channel programme panel
- [x] Add multi-channel EPG timeline prototype, capped at 8 channels
- [x] Add timeline paging, overlap lanes, current-time marker and scoped EPG caches
- [ ] Validate timeline behavior against real providers
- [ ] Add full EPG timeline/grid and catch-up capability detection
- [x] Add provider-extension-aware live playback URL builder and unit tests

## Phase 3 — Jellyfin / AIOMetadata connector
- [ ] Validate actual server API and authentication mode
- [ ] Fetch libraries and items
- [ ] Fetch metadata and artwork
- [ ] Fetch playback information / stream variants
- [ ] Map watch progress and Next Up behavior
- [ ] Validate AIOStreams variant exposure

## Phase 4 — Unified catalogue
- [ ] Canonical media model
- [ ] External ID matching
- [ ] Conservative fallback matching
- [ ] Source provenance and source picker
- [ ] Unified search, favourites and continue watching

## Phase 5 — Playback and subtitles
- [x] Add engine-independent PlaybackCoordinator and AVPlayer adapter
- [x] Add explicit stop lifecycle and item teardown
- [x] Add embedded audio/subtitle track selection where AVPlayer exposes tracks
- [x] Add engine-neutral playback state/capability and external-subtitle boundaries
- [x] Evaluate AVPlayer, VLCKit, KSPlayer and libmpv licensing/platform/toolchain fit
- [x] Audit pinned VLCKit XCFramework archive, Info.plist platform slices and actual Mach-O architectures using bounded HTTP Range requests
- [x] Resolve pinned VLCKit package and compile/link isolated iOS/tvOS simulator and device framework probes
- [x] Add isolated iOS/iPadOS and tvOS VLCKit runtime host apps with URL-based media and SRT/VTT sidecar inputs
- [ ] Build and launch runtime host apps on physical iPhone/iPad and Apple TV
- [ ] Verify local fixture and permitted HLS/VOD playback
- [ ] Verify external SRT and WebVTT rendering, Swedish characters, cue timing and pause/resume
- [ ] Verify embedded audio/subtitle discovery and selection in VLCKit
- [ ] Complete performance, memory, thermal and codec compatibility matrix
- [ ] Complete LGPL/binary distribution review and determine a stable package release
- [ ] Decide whether VLCKit is suitable for a production adapter; retain AVPlayer fallback
- [ ] Add subtitle preferences, OpenSubtitles provider, downloader/cache and sync offset UI
- [ ] Add Infuse external-player hand-off and callback validation
- [ ] Add resume and periodic progress reporting

## Phase 6 — BingeLog integration
- [x] Inspect BingeLog repository and current persistence/sync architecture
- [ ] Agree on versioned playback-event contract and canonical media IDs
- [ ] Implement durable local event outbox and idempotent delivery
- [ ] Sync started/in-progress/completed state and episode history
- [ ] Reconcile resume positions across devices
- [ ] Validate external-player progress reporting separately
- [ ] End-to-end tests with both apps

## Phase 7 — Live TV
- [x] Load live channels and provider categories into the channel browser
- [x] Persist channel favourites separately per provider profile
- [ ] Support selecting among multiple saved provider profiles
- [x] Add first multi-channel EPG timeline prototype
- [x] Add six-hour paging and return-to-now action
- [x] Separate overlapping EPG programmes into vertical lanes
- [x] Add provider-supplied channel logos with neutral fallback
- [ ] Verify historical EPG availability per provider
- [ ] Add channel zapping
- [ ] Add catch-up where provider supports it

## Phase 8 — Polish and release
- [ ] iPhone and iPad responsive refinement
- [ ] tvOS focus and remote refinement
- [ ] Offline/error/empty states
- [ ] Performance and memory profiling
- [ ] Privacy/security review
- [ ] Signed installation and distribution validation

## Definition of done

A phase is complete only when its code is committed, builds successfully for the relevant target(s), has documented tests, and its known limitations are recorded.

## Current playback gate — 2026-11-19

The VLCKit archive and binary architecture audit passed. The isolated SwiftPM package/link spike also passed for simulator and generic device framework targets on iOS and tvOS. A dedicated iOS/iPadOS and tvOS runtime host app has now been added to the isolated spike branch. The host app targets require a fresh CI build; physical playback, sidecar subtitle rendering, real provider compatibility and licensing are still unverified.

Production NEXUS continues to use AVPlayer. The VLCKit dependency must not be moved into production targets until runtime and licensing gates pass.
