# VLCKit runtime integration plan

Status: isolated runtime host apps added; production NEXUS playback remains AVPlayer-only.
Date: 2026-11-19

## Verified against the pinned upstream VLCKit source

Source revision inspected: `3d0f0fa7031eab1a67c817c98a495e1c68fc998c` (VideoLAN/vlckit).

- `VLCMediaPlayer.drawable` accepts a `UIView` on iOS/tvOS, or an object conforming to `VLCDrawable`.
- `VLCMediaPlayer.delegate` is weak; the owner must retain its delegate.
- The delegate protocol exposes callbacks for player state, buffering and track events.
- The player state enum includes opening, playing, paused, stopped, stopping and error.
- VideoLAN's Swift sample assigns the delegate and drawable, sets `mediaPlayer.media`, then calls `play()`.
- External subtitles are attached to `VLCMedia` with `VLCMediaSlave(url:type:priority:)` and `media.addSlave(...)`; attach before parsing/playback.

## Isolated implementation

- `VLCKitProbeSession` retains the player delegate and drawable view for the active session.
- Media creation and optional sidecar attachment happen before playback starts.
- Stop clears the active media item but keeps the drawable available for the next channel; view teardown explicitly detaches the drawable.
- A small SwiftUI host app is defined for iOS/iPadOS and a separate host app for tvOS.
- The host accepts media and optional subtitle URLs, exposes load/play/pause/stop, and displays state/buffering feedback.
- The host is a diagnostic harness only. It does not contain production provider credentials, does not call the production Xtream/Jellyfin connectors, and is not included in normal app targets.

## Build verification

The first isolated SwiftPM link spike completed successfully for iOS Simulator, tvOS Simulator, iOS device and tvOS device framework destinations. The runtime host app targets have been added after that successful run and require a fresh CI build.

## Runtime test gates

- Build and launch the host on physical iPhone/iPad and Apple TV.
- Local fixture playback on iOS and tvOS, including start/pause/stop/reload.
- HLS live and VOD using test streams controlled by the project or otherwise explicitly permitted.
- External SRT and WebVTT with UTF-8 Swedish characters (å, ä, ö), multiline cues and timing.
- Track discovery and selection for alternate audio and embedded subtitles.
- Repeated open/close, background/foreground and network interruption.
- Physical-device performance, memory, thermal behavior and codec coverage.
- LGPL and binary distribution review before any production adoption.

## Important limitations

The CI checks compile/link the framework and host apps for simulator and generic device destinations. They do not execute playback, render video, prove subtitle appearance/synchronization or validate real provider streams. The pinned upstream archive is an unstable build and must not be treated as a production dependency without a separate release and licensing review.

## Sources

- VideoLAN VLCKit `VLCMediaPlayer.h` at the source revision above.
- VideoLAN `SwiftSimplePlayback/PlaybackViewController.swift` at the same revision.
- Isolated probe: `Sources/VLCKitLinkProbe.swift`.
