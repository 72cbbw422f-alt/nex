# Isolated VLCKit SwiftPM link spike

This directory is deliberately separate from the production NEXUS targets.

## What this proves

- SwiftPM can resolve the pinned VideoLAN binary XCFramework.
- XcodeGen can generate iOS and tvOS probe frameworks against the local binary package.
- Xcode can compile and link the imported `VLCMediaPlayer` API and external subtitle attachment API for iOS and tvOS.
- CI builds both simulator and generic device destinations; these are link/build checks, not physical-device runtime tests.

## What this does not prove

A successful simulator build is not proof of physical-device playback, external SRT/VTT behavior, codec coverage, performance, signing/distribution, or LGPL compliance. Those remain separate gates.

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
