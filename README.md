# NEXUS

**One library. All your streams.**

NEXUS is a native Apple streaming client for iPhone, iPad and Apple TV. It unifies a user's Xtream IPTV catalogue with a Jellyfin-compatible media catalogue powered by AIOMetadata/AIOStreams, while preserving source-specific playback capabilities.

## Product direction

- Platforms: iOS, iPadOS and tvOS
- UI: SwiftUI, Nuvio-inspired visual direction with an original implementation
- Library: unified movies and series, with source provenance and selectable playback variants
- Live TV: Xtream live channels, categories and EPG
- Playback: AVPlayer first; evaluate MPV as a separately integrated fallback
- Persistence: local database/cache; credentials in Keychain
- Repository: https://github.com/72cbbw422f-alt/nex

## Core principles

1. Unify presentation, not source protocols.
2. Never silently merge uncertain title matches.
3. Keep source IDs and playback URLs source-specific.
4. Do not commit credentials, tokens, provider URLs containing secrets, or personal data.
5. Build and test each Apple platform explicitly; shared Swift packages do not imply identical UI.
6. Treat playback compatibility as a measured capability, not an assumption.

## Documentation

- [Architecture](Documentation/Architecture.md)
- [Roadmap](Documentation/Roadmap.md)
- [Development log](Documentation/DevelopmentLog.md)
- [API and integration notes](Documentation/API.md)

## Current status

Project foundation and technical planning. No application implementation or playback integration has been completed yet.
