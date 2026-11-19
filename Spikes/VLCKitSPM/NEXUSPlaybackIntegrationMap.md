# NEXUS playback adapter integration map

Date: 2026-11-19
Status: analysis of `project-foundation`; no production code changed by this note.

## Existing production boundary

Inspected files on `project-foundation`:

- `Sources/Services/PlaybackCoordinator.swift`
- `Sources/Features/Playback/PlaybackView.swift`
- `Sources/Services/SubtitleService.swift`
- `Tests/iOS/PlaybackCoordinatorTests.swift`

The current `PlaybackEngine` protocol is already `@MainActor` and engine-neutral. It exposes current time, playing state, lifecycle state, embedded audio/subtitle track lists, load/play/pause/seek and track selection. `PlaybackCoordinator` forwards those operations without exposing third-party types.

The production UI is not yet fully engine-neutral: `PlaybackView` constructs and owns an `AVPlayer`, renders it through SwiftUI `VideoPlayer`, and observes AVPlayer/AVPlayerItem KVO directly. `PlaybackCoordinator.avPlayer` also exposes the concrete AVPlayer for that view. A third-party engine cannot be substituted by changing only the coordinator initializer.

## Integration gaps to resolve before a production engine switch

1. **Video surface abstraction** — move rendering behind a platform-specific playback surface contract. AVPlayer can continue to use SwiftUI `VideoPlayer`; VLCKit needs a UIKit drawable surface on iOS/iPadOS and a tvOS-compatible surface. Keep engine-specific rendering out of shared feature UI.
2. **State delivery** — add a common state/buffering/time event channel. Today PlaybackView observes AVPlayer KVO directly; VLCKit reports state and buffering through its delegate.
3. **Duration and capabilities** — the current protocol has current time but no duration, seekable range, or can-pause/can-seek capabilities. Add only where the UI needs them and cover them with fake-engine tests.
4. **External subtitle lifecycle** — `SubtitleService` models search/download and `SubtitleAsset` models a local file, but `PlaybackEngine` has no operation to attach an external subtitle asset. Add an engine-neutral operation and report success/failure; AVPlayer should explicitly report unsupported rather than pretending to render it.
5. **Track identity** — normalize engine track identifiers and preserve selected/off state when embedded and external subtitle tracks coexist.
6. **Teardown and replacement** — define stop/dispose semantics so switching channels cannot leave an old player, drawable, delegate callback, or subtitle asset alive.

## Recommended implementation order

1. Extract a small `PlaybackSurface` boundary while keeping AVPlayer as the only production implementation.
2. Move loading/error/buffering observation from AVPlayer-specific KVO in `PlaybackView` into engine events.
3. Extend the engine contract for duration/capabilities and external subtitle attachment; add fake-engine unit tests.
4. Implement a VLCKit adapter only in the isolated spike target and compile it for iOS/tvOS.
5. Add an isolated playable harness with a known local media fixture and UTF-8 SRT/VTT fixtures.
6. Only after physical-device testing, compare the adapter against AVPlayer and decide whether to integrate.

## Verified VLCKit API facts used in the plan

At VideoLAN source revision `3d0f0fa7031eab1a67c817c98a495e1c68fc998c`, `VLCMediaPlayer.drawable` accepts a UIView on iOS-family platforms; `delegate` is weak; the delegate protocol reports state, buffering and track events. The official Swift sample assigns delegate, drawable and media before calling play. The subtitle slave API is documented in the separate `RuntimeIntegrationPlan.md`.

## Guardrails

- Do not change the production AVPlayer path as part of the VLCKit experiment.
- Do not claim external subtitle support until rendered SRT and WebVTT cues have been checked on physical iOS and tvOS devices.
- Do not select the unstable pinned binary for production without release stability and LGPL/distribution review.
