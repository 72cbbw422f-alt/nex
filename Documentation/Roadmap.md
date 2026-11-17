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
- [ ] Build adaptive navigation for iPhone and iPad
- [ ] Build focus-driven tvOS navigation
- [ ] Build reusable poster, backdrop, shelf and detail components
- [ ] Add preview fixtures (no real credentials)

## Phase 2 — Xtream connector
- [ ] Secure connection setup and validation
- [ ] Live categories and channels
- [ ] VOD movies and categories
- [ ] Series, seasons and episodes
- [ ] EPG and catch-up capability detection
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

## Phase 5 — Playback
- [ ] AVPlayer integration
- [ ] Resume and progress reporting
- [ ] Audio and subtitle selection
- [ ] AirPlay behavior validation
- [ ] MPV feasibility spike and decision
- [ ] Device/codec compatibility matrix

## Phase 6 — Live TV
- [ ] Channel browser and favourites
- [ ] EPG grid and now/next
- [ ] Channel zapping
- [ ] Catch-up where provider supports it

## Phase 7 — Polish and release
- [ ] iPhone and iPad responsive refinement
- [ ] tvOS focus and remote refinement
- [ ] Offline/error/empty states
- [ ] Performance and memory profiling
- [ ] Privacy/security review
- [ ] Signed installation and distribution validation

## Definition of done

A phase is complete only when its code is committed, builds successfully for the relevant target(s), has documented tests, and its known limitations are recorded.
