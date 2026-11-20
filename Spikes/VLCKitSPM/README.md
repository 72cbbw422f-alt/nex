# Isolated VLCKit runtime spike

This spike is separate from all production NEXUS targets.

- Pinned upstream artifact: VLCKit-4.0-20261109-1916.zip
- SHA-256: 1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463
- Approximate archive size: 910 MB (unstable upstream build)
- Targets: iOS/iPadOS and tvOS, Swift 5.9, deployment baseline 17.0

The probe host accepts a permitted media URL and optional SRT/WebVTT sidecar URL. It exposes play, pause, stop and basic player/buffering feedback.

## Build locally on macOS

```sh
xcodegen generate --spec project.yml
xcodebuild -resolvePackageDependencies -project VLCKitSpike.xcodeproj
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-iOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-tvOS -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Compile/link does not prove physical playback, subtitle rendering/synchronization, provider compatibility, performance, signing or LGPL compliance. Do not add this binary to production targets until those gates pass. AVPlayer remains the production engine.
