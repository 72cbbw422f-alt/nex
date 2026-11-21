# Isolated VLCKit runtime spike

This spike is separate from all production NEXUS targets.

- Pinned upstream artifact: VLCKit-4.0-20261109-1916.zip
- SHA-256: 1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463
- Approximate archive size: 910 MB (unstable upstream build)
- Targets: iOS/iPadOS and tvOS, Swift 5.9, deployment baseline 17.0

The probe host accepts a permitted media URL and optional SRT/WebVTT sidecar URL. It exposes play, pause, stop, basic player/buffering feedback, audio-track selection and subtitle-track selection. The VLCKit adapter sources are compiled directly into each isolated host target so the package module is linked without an intermediate framework target.

## Build locally on macOS

```sh
xcodegen generate --spec project.yml
xcodebuild -resolvePackageDependencies -project VLCKitSpike.xcodeproj
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-iOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VLCKitSpike.xcodeproj -scheme NEXUSVLCKitProbe-tvOS -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## FlareStore test packages

The dedicated workflow `.github/workflows/vlckit-spm-spike.yml` archives both device targets, packages them as unsigned IPA files, validates the ZIP structure and uploads them as the GitHub Actions artifact `nexus-vlckit-probe-unsigned-ipas`.

1. Open the successful workflow run for the current PR head.
2. Download `nexus-vlckit-probe-unsigned-ipas` and extract the artifact ZIP.
3. Import `NEXUS-VLCKit-iOS-unsigned.ipa` into FlareStore, select the iPhone/iPad certificate and provisioning profile, sign, then install.
4. Import `NEXUS-VLCKit-tvOS-unsigned.ipa`, select the Apple TV certificate and provisioning profile, sign, then send it to the paired Apple TV.

The two packages are unsigned build outputs, not install-ready signed applications. FlareStore signing is required. The Apple TV certificate must be registered to the target Apple TV; Apple TV installation through FlareStore is currently documented as beta. Keep the bundle identifiers stable when updating an installed test build.

## Runtime test protocol

Use owned or explicitly permitted test media. Record the exact device model, OS version, stream/container/codec, audio format, subtitle format/language, startup time, buffering, playback stability and observed A/V or subtitle offset.

- iPhone/iPad: H.264 and HEVC where available; AAC/AC3/E-AC3 test streams; external SRT and WebVTT.
- Apple TV: repeat the same media and subtitle cases independently; do not infer tvOS behavior from iOS results.
- Swedish text fixture: verify å, ä, ö, Å, Ä, Ö and punctuation; compare subtitle timing at start, middle and end.
- Audio/subtitle track controls now use the pinned VLCKit 4.0 API: `audioTracks`, `textTracks`, `trackName`, `trackId`, `isSelected`, `isSelectedExclusively` (Swift import of the Objective-C `selectedExclusively` property), `selectTextTracks` and `deselectAllTextTracks`. The controls are compile/link- and package-verified by GitHub Actions run #82 (commit `8bed9be3c42b29418c4887a77515ede7292dff71`); all 16 workflow steps passed. The resulting unsigned artifact is `nexus-vlckit-probe-unsigned-ipas` (artifact ID `14667903769`, SHA-256 `a646f51c935d1c81bd55370d7b826214fa64ad559e5f16f05f4c24151d943a12`, expires 2026-12-04 20:46:37 UTC). Physical-device runtime tests are still pending.
- Compare each test case against the existing AVPlayer path using the same source and device.

Compile/link does not prove physical playback, subtitle rendering/synchronization, provider compatibility, performance, signing or LGPL compliance. Do not add this binary to production targets until those gates pass. AVPlayer remains the production engine.
