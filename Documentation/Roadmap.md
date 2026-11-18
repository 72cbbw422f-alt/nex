# Roadmap

## Phase 0 — Foundation
- [x] Confirm product name and repository
- [x] Confirm iOS, iPadOS and tvOS
- [x] Confirm Nuvio-inspired design direction
- [x] Confirm unified movie/series presentation
- [ ] Establish Xcode project and build configurations
- [ ] Add CI build workflow for Apple platforms
- [ ] Add linting and test targets

## Phase 1 — Design shell
- [ ] Define NEXUS design tokens and typography
- [x] Present complete design direction for approval before major UI implementation
- [x] Lock approved NEXUS visual direction (deep navy, violet accent, cinematic layouts) from user-supplied reference images
- [ ] Build adaptive navigation for iPhone and iPad
- [ ] Build focus-driven tvOS navigation
- [ ] Build reusable poster, backdrop, shelf and detail components
- [x] Add searchable movie and series library grids and connect them to navigation
- [x] Add a global search screen and connect the home search action
- [x] Add first Xtream/Jellyfin connection setup form shell (no persistence or API calls yet)
- [ ] Design player, subtitle picker and playback settings
- [x] Add first cinematic film/series detail-view shell
- [x] Add first Live TV guide screen shell and connect it to mobile navigation
- [x] Make Live TV category filters and favourite-channel controls interactive
- [x] Add Apple TV navigation entry points for Home, Live TV, Films, Series and My List
- [ ] Add preview fixtures (no real credentials)

## Phase 2 — Xtream connector
- [x] Persist non-secret connection profiles and passwords separately in Keychain (CI/device validation pending)
- [x] Add Xtream Player API authentication test and live category/channel fetch adapter (CI and real-provider validation pending)
- [x] Wire live category/channel results into Live TV with category filters and loading/error states
- [ ] Validate authentication and response compatibility against real Xtream providers
- [ ] Live categories and channels
- [ ] VOD movies and categories
- [ ] Series, seasons and episodes
- [x] Add on-demand short EPG retrieval and per-channel programme panel (provider validation pending)
- [x] Decode EPG IDs and timestamps from string or numeric JSON values with deterministic fallback identity
- [ ] Full EPG timeline/grid and catch-up capability detection
- [ ] Playback locator tests

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
- [ ] KSPlayer technical spike: package, license, iOS/iPadOS/tvOS build and device compatibility
- [ ] Implement engine-independent PlaybackCoordinator
- [ ] KSPlayer adapter if the spike passes; retain AVPlayer fallback for supported streams
- [ ] Infuse external-player hand-off and callback validation
- [ ] Subtitle preferences with ordered language priority
- [ ] Embedded subtitle selection and external OpenSubtitles lookup
- [ ] Subtitle matching, cache, manual selection and sync offset
- [ ] Resume and periodic progress reporting
- [ ] Audio track selection and AirPlay behavior validation
- [ ] Device/codec compatibility matrix

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
- [x] Persist channel favourites separately per provider profile (CI/device validation pending)
- [ ] Support selecting among multiple saved provider profiles
- [x] Add first multi-channel EPG timeline prototype (on-demand, capped at 8 channels; provider validation pending)
- [x] Align programme blocks to a shared six-hour clock axis and show a current-time marker (initial implementation; provider validation pending)
- [x] Add six-hour previous/next timeline window controls and return-to-now action (CI/provider validation pending)
- [ ] Improve overlap/EPG-gap handling and verify historical EPG availability per provider
- [ ] Validate the shared timeline build after correcting a Swift key-path compile error (CI pending)
- [x] Display provider-supplied channel logos with neutral fallback (CI/device validation pending)
- [ ] Channel zapping
- [ ] Catch-up where provider supports it

## Phase 8 — Polish and release
- [ ] iPhone and iPad responsive refinement
- [ ] tvOS focus and remote refinement
- [ ] Offline/error/empty states
- [ ] Performance and memory profiling
- [ ] Privacy/security review
- [ ] Signed installation and distribution validation

## Definition of done

A phase is complete only when its code is committed, builds successfully for the relevant target(s), has documented tests, and its known limitations are recorded.
