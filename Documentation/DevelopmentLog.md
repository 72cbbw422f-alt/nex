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
- Do not assume the two apps can share a local database. Inspect BingeLog's actual repository and persistence/sync design before choosing a shared backend or CloudKit contract.
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
