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
- [x] Present complete design direction for approval before major UI implementation
- [x] Lock approved NEXUS visual direction (deep navy, violet accent, cinematic layouts) from user-supplied reference images
- [ ] Build adaptive navigation for iPhone and iPad
- [ ] Build focus-driven tvOS navigation
- [ ] Build reusable poster, backdrop, shelf and detail components
- [x] Add searchable movie and series library grids and connect them to navigation
- [x] Add a global search screen and connect the home search action
- [x] Add first Xtream/Jellyfin connection setup form shell (no persistence or API calls yet)
- [x] Add first native AVPlayer player screen with channel launch from Live TV (stream/device validation pending)\n- [ ] Design subtitle picker and playback settings
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
- [x] Refine expanded channel EPG rows with start/end times and explicit loading/empty states (CI pending)
- [x] Decode EPG IDs and timestamps from string or numeric JSON values with deterministic fallback identity
- [ ] Full EPG timeline/grid and catch-up capability detection
- [x] Add explicit Xtream live-stream playback locator with provider-supplied container extension (iOS/tvOS simulator CI passed)
- [x] Add four XCTest cases for Xtream playback URL construction, credential encoding, extension validation and invalid input (CI passed)

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
- [ ] Resolve KSPlayer GPL/LGPL licensing and distribution model before adoption
- [ ] Pin an exact KSPlayer release and verify its Swift tools/Xcode compatibility
- [x] Add first AVPlayer-backed playback surface behind the playback abstraction (real HLS/provider validation pending)
- [ ] KSPlayer technical spike: package, license, iOS/iPadOS/tvOS build and device compatibility
- [x] Add engine-independent PlaybackCoordinator and AVPlayer adapter (iOS/tvOS build and all eight XCTest cases passed)
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
- [x] Separate overlapping EPG programmes into vertical lanes and preserve visible empty gaps (CI/provider validation pending)
- [ ] Verify historical EPG availability per provider
- [x] Align the red current-time marker to the selected six-hour window and hide it outside the current-time range (CI pending)
- [ ] Validate the shared timeline build after correcting a Swift key-path compile error (CI passed on current source)
- [x] Reuse short-EPG responses across timeline paging with a five-minute cache and profile-change invalidation (CI pending)
- [x] Scope EPG programme, timestamp and error caches by provider/server/account/channel identity (iOS/tvOS CI passed; device validation pending)
- [x] Guard in-flight EPG requests against stale profile/category/channel state (iOS/tvOS CI passed; device validation pending)
- [x] Distinguish successful empty EPG responses from provider request failures; use shorter retry cooldown for failures (CI/provider validation pending)
- [x] Display provider-supplied channel logos with neutral fallback (CI/device validation pending)
- [x] Guard overlapping channel refreshes against stale profile and request results (iOS/tvOS CI pending)\n- [ ] Channel zapping
- [ ] Catch-up where provider supports it

## Phase 8 — Polish and release
- [ ] iPhone and iPad responsive refinement
- [x] Add compact-width Live TV spacing and EPG sizing (CI/device validation pending)
- [ ] tvOS focus and remote refinement
- [ ] Offline/error/empty states
- [ ] Performance and memory profiling
- [ ] Privacy/security review
- [ ] Signed installation and distribution validation

## Definition of done

A phase is complete only when its code is committed, builds successfully for the relevant target(s), has documented tests, and its known limitations are recorded.


## Xtream request resilience and timeline request ownership

- Added one bounded retry after a transient URLSession network failure (timeout, DNS/host/connectivity loss) and after an HTTP 5xx response, with a 500 ms delay. Authentication and other HTTP 4xx responses, malformed JSON and non-transient errors are not retried.
- Added a request UUID to timeline loads so only the latest timeline request can update EPG cache entries, status text and loading state. The request also verifies provider, server and username after each await.
- Concurrent EPG deduplication between the timeline and expanded channel panel remains a separate follow-up; both surfaces still share the profile-scoped cache, but simultaneous cache misses can still issue duplicate calls.
- iOS/tvOS CI and real-provider/device validation pending.


## Shared in-flight EPG requests

- Added an actor-based request coordinator keyed by provider, normalized server, username and channel ID.
- The Live TV timeline and expanded channel panel now await the same in-flight short-EPG task when they request the same channel concurrently, avoiding duplicate provider calls.
- Completed responses continue to use the existing profile-scoped five-minute success / one-minute failure cache in the view.
- Concurrent deduplication and Swift concurrency compatibility require iOS/tvOS CI validation and real-provider testing.


## Xtream live playback locator foundation

- The live-stream response model now captures the optional provider-supplied `container_extension`.
- Added a dedicated locator builder for the documented `/live/{username}/{password}/{stream_id}.{extension}` path shape.
- The builder requires an explicit, validated extension from provider data; it does not guess TS/HLS format when the provider omits it.
- Username and password are percent-encoded as individual path segments. The resulting secret-bearing URL must remain runtime-only and must never be logged or persisted.
- This is URL construction only: no channel player, stream probe, KSPlayer dependency or playback support claim has been added. iOS/tvOS simulator CI passed; real-provider URL verification remains pending.


## Playback coordinator test coverage

- Added fake-engine XCTest coverage for start/load ordering, pause/resume forwarding, seek forwarding, and playback state passthrough.
- The tests validate coordinator behavior independently of AVPlayer and do not claim that a real stream has played.
- All four PlaybackCoordinator tests passed in GitHub Actions on the subsequent branch commit; iOS and tvOS simulator builds also passed.


## PlaybackCoordinator XCTest verification

- GitHub Actions completed successfully after the four fake-engine PlaybackCoordinator tests were added.
- The successful run built iOS Simulator and tvOS Simulator targets and executed the iOS unit-test scheme.
- All four Xtream locator tests and all four PlaybackCoordinator tests passed.
- This validates URL construction and coordinator command forwarding only; it does not validate real provider streams, AVPlayer codec support or physical-device playback.


## First Live TV playback surface

- Added a full-screen SwiftUI playback view backed by AVPlayer and the existing PlaybackCoordinator abstraction.
- Added a play action to provider-backed Live TV channel rows. The action resolves the selected channel's provider-supplied container extension, retrieves the password from Keychain at runtime and constructs the candidate Xtream live URL.
- The candidate URL is held only in transient view state and is not written to preferences or logs.
- The screen exposes Apple's native VideoPlayer controls and a NEXUS-styled title/close overlay.
- This first integration is AVPlayer-only. It does not imply support for every Xtream container or codec. Real provider playback, audio/subtitle selection, stream error feedback, physical iPhone/iPad testing and tvOS remote controls remain pending.
