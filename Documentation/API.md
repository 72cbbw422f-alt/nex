# API and integration notes

This document records verified integration behavior. Do not place real credentials, tokens, private URLs or personally identifying data here.

## Xtream

Expected integration areas (must be validated against the provider):
- Authentication / account status
- Live stream categories and channels
- VOD categories and items
- Series categories, series details, seasons and episodes
- EPG / short EPG
- Catch-up capability
- Stream URL construction and format behavior

Record sanitized example responses and endpoint behavior here after validation.

## Jellyfin-compatible AIOMetadata

Validate:
- Base URL and TLS behavior
- Authentication method and token handling
- Server information and user/session identity
- Library and item endpoints
- Search and item detail responses
- Image URL behavior
- Playback information and available media sources
- Resume/progress endpoints
- Next Up / continue watching behavior

## AIOStreams

Treat AIOStreams as a stream-discovery/variant provider behind the configured integration. Verify whether the current setup returns variants through standard Jellyfin playback-info responses or through a custom extension. Do not assume that a metadata catalogue item always has a directly playable URL.

## Sanitization

Before committing fixtures:
- Remove credentials and authorization headers.
- Replace hostnames and user IDs with placeholders.
- Remove secret query parameters from stream URLs.
- Keep only the fields needed for decoding and normalization.
