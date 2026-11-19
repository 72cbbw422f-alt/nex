# VLCKit runtime integration plan

Status: research note only. No production playback code has been changed.

## Verified against the pinned upstream VLCKit source

Source revision inspected: `3d0f0fa7031eab1a67c817c98a495e1c68fc998c` (VideoLAN/vlckit).

- `VLCMediaPlayer.drawable` accepts a `UIView` on iOS/tvOS, or an object conforming to `VLCDrawable`.
- `VLCMediaPlayer.delegate` is weak; the owner must retain its delegate.
- The delegate protocol exposes callbacks for player state, buffering, and track add/remove/update/selection.
- The player state enum includes opening, playing, paused, stopped, stopping, and error.
- VideoLAN's Swift sample assigns the delegate and drawable, sets `mediaPlayer.media`, then calls `play()`.
- External subtitles are attached to `VLCMedia` with `VLCMediaSlave(url:type:priority:)` and `media.addSlave(...)`; attach before parsing/playback.

## Proposed NEXUS adapter lifecycle

1. Create and retain one VLC player instance for the active playback session.
2. Attach a platform video surface to `drawable` before starting playback.
3. Create `VLCMedia` from the resolved stream URL.
4. If a sidecar subtitle URL exists, attach it to the media before assigning/starting it.
5. Assign media, start playback, and translate VLC state/buffering/track callbacks into NEXUS engine-neutral events.
6. On teardown, stop playback, detach the drawable, release media/player, and invalidate callbacks.

## Adapter boundary

Keep VLCKit behind the existing playback-engine abstraction. UI code should not import VLCKit or inspect VLC-specific enums. Normalize at least:

- lifecycle: idle, preparing, ready, playing, paused, ended, failed
- buffering progress
- current time and duration
- seekability and pause capability
- audio and subtitle track inventory/selection
- external subtitle attachment result

## Runtime test gates

- Local fixture playback on iOS and tvOS, including start/pause/seek/stop.
- HLS live and VOD using test streams controlled by the project.
- External SRT and WebVTT with UTF-8 Swedish characters (å, ä, ö), multiline cues, timing, and track selection.
- Track discovery and selection for alternate audio and embedded subtitles.
- Repeated open/close, background/foreground, and network interruption.
- Physical-device performance, memory, thermal behavior, and codec coverage.
- Licensing and binary distribution review before any production adoption.

## Important limitations

The current CI checks compile/link the framework for generic device and simulator destinations. They do not execute playback, render video, prove subtitle appearance/synchronization, or validate real provider streams. The pinned upstream archive is an unstable build and must not be treated as a production dependency without a separate release and licensing review.

## Sources

- VideoLAN VLCKit `VLCMediaPlayer.h` at the source revision above.
- VideoLAN `SwiftSimplePlayback/PlaybackViewController.swift` at the same revision.
- Existing isolated probe: `Sources/VLCKitLinkProbe.swift`.
