# Development log

## 2026-11-17 — Project initialized

- Repository confirmed: 72cbbw422f-alt/nex
- Repository was newly created and contained only a minimal README.
- Product scope confirmed: iOS, iPadOS and tvOS.
- Design direction: Nuvio-inspired, original NEXUS implementation.
- Content model: unified movie and series catalogue combining Xtream IPTV and Jellyfin-compatible AIOMetadata/AIOStreams sources.
- Initial architecture and roadmap documented.
- No app code, API integration, or playback implementation had been completed at initialization.

## 2026-11-17 — Phase 1 design shell started

- Added XcodeGen project specification with iOS and tvOS application targets. iPadOS is supported through the adaptive iOS target.
- Added SwiftUI application entry point, design tokens, reusable poster tile, home screen and platform-adaptive root navigation.
- Added GitHub Actions simulator build workflow for iOS and tvOS.
- UI uses local illustrative placeholder artwork only; no real provider data is connected.
- Build has not yet been executed in this environment. CI will validate compilation.

## Decisions to validate

- Exact AIOMetadata server API, auth mode and available endpoints.
- Whether AIOStreams exposes playable variants through the user's current Jellyfin-compatible setup, and in what response shape.
- Xtream provider API behavior and supported EPG/catch-up capabilities.
- AVPlayer vs MPV compatibility for the user's real stream formats.
- Build/signing workflow for iOS, iPadOS and tvOS from the available PC-based workflow.
