# Isolated VLCKit runtime spike

This directory is deliberately separate from the production NEXUS targets.

## What this proves

- SwiftPM can resolve the pinned VideoLAN binary XCFramework.
- XcodeGen can generate iOS and tvOS probe frameworks against the local binary package.
- Xcode can compile and link the imported `VLCMediaPlayer` API and external subtitle attachment API.
- The runtime host apps can be built for iOS and tvOS simulator and generic device destinations.

## Runtime host apps

The spike now includes two small host apps:

- `NEXUSVLCKitProbe-iOS` for iPhone/iPad.
- `NEXUSVLCKitProbe-tvOS` for Apple TV.

Enter a media URL and, optionally, a direct SRT/WebVTT subtitle URL. The app attaches the sidecar subtitle to `VLCMedia` before playback, then exposes play/pause/stop and state/buffering feedback. URLs are kept in transient view state and are not logged or persisted.

Use only test media and subtitle assets you own or are explicitly permitted to access. Do not paste provider credentials or secret-bearing Xtream stream URLs into screenshots, logs or issue reports.

## What this does not prove

A successful simulator or generic-device build is not proof of physical-device playback, external subtitle rendering/synchronization, codec coverage, performance, signing/distribution or LGPL compliance. Those remain separate gates. A successful `load` call only means VLCKit accepted media creation and the sidecar attachment call; it does not prove that subtitles were rendered.

## Runtime subtitle fixtures

- `Fixtures/swedish-test.srt`
- `Fixtures/swedish-test.vtt`

Both fixtures contain multiple cues and Swedish characters (`åäö`). Use them with a locally available short test video or a permitted test endpoint. Keep copyrighted video files out of the repository unless distribution rights are clear.

## Manual runtime checklist

1. Install the iOS host on a physical iPhone/iPad and the tvOS host on Apple TV when a signing path is available.
2. Enter a permitted media URL and an SRT or WebVTT URL.
3. Confirm that video/audio starts, buffering feedback changes and stop/reload releases the previous item.
4. Verify every subtitle cue at its expected timestamp, including Swedish characters, multiline text and pause/resume.
5. Repeat with both SRT and WebVTT, then test seek, background/foreground, network interruption and repeated channel changes.
6. Record device model, OS version, media codec/container, subtitle format and observed result.

## Binary pin

- Artifact: `VLCKit-4.0-20261109-1916.zip`
- SHA-256: `1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463`
- Upstream package source: VideoLAN's official VLCKit repository.
- The archive is approximately 910 MB. The spike is opt-in through its dedicated workflow and is not part of normal NEXUS builds.

## Run locally on macOS

```sh
cd Spikes/VLCKitSPM
xcodegen generate --spec project.yml
xcodebuild -resolvePackageDependencies -project VLCKitSpike.xcodeproj
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-iOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-tvOS -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Runtime integration research

See `RuntimeIntegrationPlan.md` for the verified drawable/delegate API surface, adapter lifecycle, test gates and limitations.

See `NEXUSPlaybackIntegrationMap.md` for the gaps between production AVPlayer UI/coordinator and a future engine-neutral VLCKit adapter. No production playback engine has been changed.
