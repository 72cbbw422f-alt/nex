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
