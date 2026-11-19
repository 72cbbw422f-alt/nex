# Isolated VLCKit SwiftPM link spike

This directory is deliberately separate from the production NEXUS targets.

## What this proves

- SwiftPM can resolve the pinned VideoLAN binary XCFramework.
- XcodeGen can generate iOS and tvOS probe frameworks against the local binary package.
- Xcode can compile and link the imported `VLCMediaPlayer` API and external subtitle attachment API for iOS and tvOS.
- CI builds both simulator and generic device destinations; these are link/build checks, not physical-device runtime tests.

## What this does not prove

A successful simulator build is not proof of physical-device playback, external SRT/VTT behavior, codec coverage, performance, signing/distribution, or LGPL compliance. Those remain separate gates.

## Runtime subtitle fixtures

- `Fixtures/swedish-test.srt`
- `Fixtures/swedish-test.vtt`

Both fixtures contain multiple cues and Swedish characters (`åäö`). They are intended for manual runtime testing with a locally available, short test video. Keep the video outside the repository unless distribution rights are clear.

### Manual runtime checklist

1. Open the probe in a small host app on a physical iPhone/iPad or Apple TV.
2. Copy the test video and one subtitle fixture to a location the app can read.
3. Call `VLCKitProbeSession.load(mediaURL:subtitleURL:autoplay:)` with the local file URLs.
4. Confirm that playback starts and each cue appears at the expected timestamp.
5. Repeat with both SRT and WebVTT; check å, ä and ö, multiline text, pause/resume, seek, and stop/reload.
6. Repeat on each target device class. Record device model, OS version, media codec/container, subtitle format, and observed result.

Do not treat a successful `load` return value as proof that subtitles rendered correctly; it only confirms media creation and that VLCKit accepted the sidecar attachment call.

## Binary pin

- Artifact: `VLCKit-4.0-20261109-1916.zip`
- SHA-256: `1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463`
- Upstream package source: VideoLAN's official VLCKit repository.
- The archive is approximately 910 MB. The spike is opt-in through its dedicated workflow and does not add the binary to the normal NEXUS build.

## Run locally on macOS

```sh
cd Spikes/VLCKitSPM
xcodegen generate --spec project.yml
xcodebuild -resolvePackageDependencies -project VLCKitSpike.xcodeproj
xcodebuild -project VLCKitSpike.xcodeproj -scheme VLCKitProbe-iOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VLCKitSpike.xcodeproj -scheme VLCKitProbe-tvOS -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Runtime integration research

See [RuntimeIntegrationPlan.md](RuntimeIntegrationPlan.md) for the verified drawable/delegate API surface, proposed engine-adapter lifecycle, test gates, and limitations.

See [NEXUSPlaybackIntegrationMap.md](NEXUSPlaybackIntegrationMap.md) for the gaps between the existing production AVPlayer UI/coordinator and a future engine-neutral VLCKit adapter. This is an architecture assessment, not an implemented player.
