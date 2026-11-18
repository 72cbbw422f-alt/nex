# Playback engine evaluation

Status: research gate; no engine selected or integrated.
Date: 2026-11-18
Scope: NEXUS iOS/iPadOS/tvOS, Xtream live streams, VOD, embedded and external subtitles.

## Executive conclusion

Keep the current AVPlayer adapter as the native baseline and preserve the engine-neutral PlaybackEngine boundary. Do not add a third-party engine yet.

The most practical candidates for a controlled technical spike are:

1. **VLCKit 4.x** — strongest first candidate to test. VideoLAN explicitly documents iOS and tvOS support, LGPL 2.1+, a Swift Package manifest using Swift tools 5.9, and a concrete API path for attaching external subtitle files. However, the current SPM manifest points to an unstable 4.0 binary build; package stability, binary slices, signing/distribution and actual device behavior must be validated.
2. **KSPlayer 5.6.2** — strongest feature-rich alternative, with documented iOS/tvOS support, text/image subtitles and subtitle search. The default distribution is GPL-3.0; the LGPL version is paid and must be obtained and reviewed. Its current Package.swift requires Swift tools 6.2 and pulls a separate FFmpegKit package. This is not a drop-in dependency for NEXUS's Swift 5.9 configuration.
3. **libmpv / mpv-ios** — technically capable and attractive for subtitle/format control, but the inspected mpv-ios project documents an iOS implementation, not a complete tvOS target. It requires building a Libmpv.xcframework with Apple's toolchain on macOS. The project wrapper is Apache-2.0, but libmpv and its dependency stack carry separate GPL/LGPL obligations depending on build options.
4. **AVPlayer only** — retain as native fallback for compatible HLS and embedded media-selection tracks. It does not solve general external SRT/VTT sidecar injection in the current custom VideoPlayer setup.

No candidate is cleared for production until the spike and license review pass.

## Comparison

| Criterion | AVPlayer | VLCKit | KSPlayer | libmpv / mpv-ios |
|---|---|---|---|---|
| iOS/iPadOS | Native | Explicitly supported | Explicitly supported | iOS implementation documented |
| tvOS | Native | Explicitly supported | Explicitly supported | Not established by inspected mpv-ios project |
| External SRT/VTT | No general sidecar injection in current implementation | VLC media slave API supports external subtitle URL/path; verify SRT/VTT on devices | Project advertises text/image subtitles and subtitle search; verify exact formats/API | mpv supports external subtitle tracks; validate iOS wrapper and tvOS port |
| Embedded tracks | Yes, AVMediaSelectionGroup | Yes | Yes | Yes |
| Broad container/codec coverage | Apple-supported formats only | libVLC broad format support | FFmpeg-backed; broad advertised support | FFmpeg/libmpv broad support |
| License | Apple SDK | LGPL 2.1+ | GPL default; paid LGPL/commercial route | mpv GPLv2+ by default; LGPL build possible only with exact dependency configuration; other dependencies vary |
| Swift/package fit | Excellent | Swift tools 5.9 manifest; binary XCFramework | Swift tools 6.2 currently | Requires custom-built XCFramework and wrapper |
| Current NEXUS Swift 5.9 | Yes | Manifest-level fit; binary must be verified | No, not without toolchain upgrade/fork | Potentially via custom package; build pipeline needed |
| Integration complexity | Low | Medium | Medium/high | High |
| Main risk | Format limitations | Unstable SPM binary release and device validation | Licensing and Swift toolchain | tvOS gap, complex native build and license stack |

## Evidence and technical notes

### AVPlayer

- Apple documents AVMediaSelectionGroup / AVMediaSelectionOption for alternative audio and subtitle tracks contained in the media asset. The current NEXUS adapter uses this supported path.
- Apple documentation lists the old externalSubtitleOptionLanguages and selectedExternalSubtitleOptionLanguage properties as deprecated. The AVKit delegate callback for an external subtitle language leaves subtitle rendering to the app. This is not a general drop-in mechanism for arbitrary downloaded SRT/VTT files in the current VideoPlayer view.
- Keep AVPlayer for compatible HLS and as a fallback, not as the sole engine if external subtitle files and wider container support are product requirements.

### VLCKit

- VideoLAN's VLCKit page explicitly lists macOS, iOS and tvOS and LGPL 2.1 or later. It describes VLCKit as a libVLC wrapper and specifically calls out unsupported QuickTime/AVFoundation formats and subtitles beyond QuickTime closed captions.
- The current upstream Package.swift uses Swift tools 5.9 and declares iOS and tvOS platforms. It references the binary XCFramework ZIP VLCKit-4.0-20261109-1916.zip with checksum `1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463`. The URL is in VideoLAN's unstable download area; do not assume this is a stable production release. This current-manifest note supersedes the earlier August 31 artifact observation recorded in the audit history below.
- VideoLAN's older installation instructions still show CocoaPods 3.3.x products (MobileVLCKit for iOS and TVVLCKit for tvOS). The current SPM binary is 4.0 and must be evaluated independently of those older instructions.
- The official VideoLAN iOS app source calls addPlaybackSlave with VLCMediaPlaybackSlaveTypeSubtitle to attach an external subtitle URL. This is strong evidence of an integration route, but it does not prove every SRT/VTT encoding, tvOS UI behavior, or NEXUS-specific stream works.
- LGPL compliance still requires distribution review: notices, source offer/access for modifications, relinking/replacement requirements as applicable, and review of bundled codecs/dependencies. This is not legal advice.

### KSPlayer

- The upstream README explicitly supports iOS and tvOS and advertises text/image subtitles, online subtitle search, and FFmpeg-backed playback.
- The README states the default package is GPL and requires the user's project source to be opened; a paid LGPL version and other commercial licensing arrangements are offered by the maintainer. No paid licence or source grant has been obtained for NEXUS.
- The inspected current Package.swift declares swift-tools-version 6.2, includes a binary KSPlayer target, KSPlayerUI and MPVPlayer, and a dependency on FFmpegKit 9.0.2. FFmpegKit itself documents GPL by default and a paid LGPL version.
- Current NEXUS project settings use Swift 5.9. Raising the toolchain is a separate project-wide change and should not be done merely to consume this package.
- KSPlayer remains a candidate only if the maintainer provides written licence terms, matching binary/source distribution, dependency notices and a reproducible build that supports both iOS and tvOS.

### libmpv / mpv-ios

- mpv's own copyright file says mpv is GPLv2+ by default and can be built LGPLv2.1+ when GPL-only files are excluded; that switch alone is not a licence grant. FFmpeg and other linked dependencies can change the final obligations.
- The inspected mpv-ios project describes itself as an iOS implementation. Its documented build process compiles libmpv and dependencies into a Libmpv.xcframework using macOS/Xcode and patched build scripts. It explicitly says the XCFramework is not prebuilt.
- The wrapper project is Apache-2.0, but that does not relicense libmpv or its dependencies. The project itself warns about GPL/LGPL obligations.
- Do not select this route unless tvOS support is proven by a dedicated port/build and the complete dependency configuration is reviewed.

## Proposed technical spike (no production dependency yet)

Use a separate branch or isolated target; do not replace the working AVPlayer path.

1. **Package integrity**
   - Resolve exact pinned versions and checksums.
   - Inspect XCFramework slices for iOS device, iOS Simulator, Apple TV device and Apple TV Simulator.
   - Confirm minimum OS versions, architectures, module maps, embedded resources and transitive dependencies.
   - Build NEXUS iOS and tvOS simulator targets with the package linked.
2. **Playback proof**
   - Test HLS live, HLS VOD, MP4/H.264/AAC, MKV/H.264/AAC, HEVC, AC-3/E-AC-3 where hardware permits, and a provider-like HTTP stream.
   - Record start latency, buffering, seek, pause/resume, channel zapping, memory and thermal behavior.
   - Do not claim format support based only on a project README.
3. **Subtitle proof**
   - Attach local SRT and WebVTT files.
   - Test UTF-8 BOM, Swedish å/ä/ö, multiline cues, timestamps, forced subtitles, track switching, Off, and sync offset.
   - Test an external subtitle downloaded to app cache, not just a bundled sample.
   - Test embedded + external track coexistence and ensure the selected state matches what is actually rendered.
4. **Platform proof**
   - iPhone and iPad physical-device playback.
   - Apple TV physical-device playback and Siri Remote focus/navigation.
   - AirPlay, background/foreground and audio route changes as relevant.
   - Simulator builds are necessary but are not proof of codec/hardware behavior.
5. **License and distribution gate**
   - Obtain exact licence text for the exact binary and all transitive libraries.
   - For KSPlayer, obtain written confirmation of LGPL/commercial package terms, source/binary availability, update rights and redistribution rights.
   - For VLCKit, verify LGPL obligations for the exact binary and included codec/dependency configuration.
   - Generate a third-party notices and source-compliance checklist before distribution.
6. **Decision scorecard**
   - A candidate must pass iOS and tvOS builds, external SRT/VTT tests, real-device playback, acceptable performance and a documented distribution licence.
   - If no candidate passes, keep AVPlayer and limit the supported format promise rather than ship a fragile player.

## Current recommendation

Start the isolated spike with **VLCKit 4.0**, while retaining KSPlayer as a feature-rich alternative pending written licence and toolchain clearance. This is a recommendation for testing order only, not a final engine selection.

Do not add any playback package to the production NEXUS targets until the spike passes.


## 2026-11-18 — VLCKit distribution artifact audit

- Rechecked the official VideoLAN upstream Package.swift and the live VideoLAN unstable download index.
- The upstream manifest currently pins the binary URL VLCKit-4.0-20260831-1526.zip with checksum c61a42052ec4c1315325fba81f8893f4ccf639d92bf61dd1b3c37c3a2f26b8e3.
- The official unstable directory also lists newer 4.0 builds dated 2026-09-29 and 2026-11-09. The manifest therefore does not point at the newest artifact visible in the directory. Do not silently substitute the newer archive: it needs its own verified checksum and compatibility audit.
- The manifest's August 31 archive is listed at approximately 920.6 MB. The November 9 archive is approximately 910.2 MB. This is a substantial dependency download and increases CI/cache, distribution and update costs.
- The public index confirms the artifacts exist and their approximate sizes, but does not prove their XCFramework contents or platform slices. iOS device/simulator and tvOS device/simulator support still must be inspected from the actual archive.
- Current conclusion: VLCKit remains the best candidate for an isolated test, but the SPM artifact is not yet cleared for integration. Next gate is archive integrity/checksum plus XCFramework slice inspection and a minimal CI package-resolution/build spike. Keep AVPlayer untouched.


## 2026-11-18 — Additional libVLC wrapper candidate: SwiftVLC

- Identified harflabs/SwiftVLC, a newer native-Swift wrapper around libVLC, advertising iOS, tvOS, macOS, visionOS and Mac Catalyst support. This is a separate project from VideoLAN's Objective-C VLCKit wrapper; it still uses libVLC and does not remove libVLC licensing obligations.
- Inspected its current Package.swift: Swift tools 6.3, Swift language mode 6, and minimum iOS/tvOS 18.0. NEXUS currently targets Swift 5.9 and iOS/tvOS 17.0, so this package is not compatible with the current project baseline without a significant toolchain and deployment-target change.
- Its v1.1.0-rc.1 binary is a static libVLC XCFramework with a published checksum. The package index explicitly labels the artifact not release-qualified because its physical-device matrix and required feature policy have not both been satisfied. It must not be treated as production-ready merely because it has a package and binary release.
- The repository is actively maintained (latest visible update in November 2026) and has a substantial qualification harness. It is worth retaining as a watch-list candidate, but not as the immediate NEXUS spike while our baseline remains Swift 5.9 / iOS 17.
- This reinforces the current decision: keep VLCKit 4.x as the first candidate to validate against our existing deployment baseline; keep SwiftVLC as a possible future alternative only if NEXUS deliberately raises its baseline and the upstream artifact completes device qualification.
- No player package has been added to NEXUS. No engine decision has changed.


## 2026-11-18 — VLCKit manifest recheck (latest upstream)

- Re-fetched VideoLAN's current upstream Package.swift on 2026-11-18. It now points to VLCKit-4.0-20261109-1916.zip, not the August 31 archive recorded in the initial audit.
- Current upstream checksum: 1fec7232f88e706f44d9a015133e08d742166eb2666cb44915c9f570bf339463.
- The VideoLAN unstable index lists this November 9 archive at 910,171,154 bytes (about 910 MB). It is still an unstable build, not a stable release.
- This supersedes the earlier note that the current manifest pointed at the August 31 build. The August artifact/checksum remain historical observations only.
- The upstream manifest declares Swift tools 5.9 and iOS/tvOS minimum 12, so its manifest-level toolchain/platform declaration is compatible with NEXUS's Swift 5.9 / iOS and tvOS 17 baseline.
- Manifest declarations do not prove the archive contains all required XCFramework variants. The archive's actual iOS device, iOS Simulator, tvOS device and tvOS Simulator slices remain unverified.
- Do not make CI download the 910 MB archive until a lightweight metadata/range check establishes a sensible inspection path. Do not add the package to production targets. AVPlayer remains untouched.


## 2026-11-19 — Bounded remote ZIP inspector added

- Added `Scripts/inspect_remote_zip.py` to inspect the remote archive's ZIP central directory without saving the full binary.
- The tool requests only the final ZIP metadata window (at most 65,557 bytes) and then the central directory (hard-capped at 32 MiB).
- Every response must be HTTP 206 with a matching `Content-Range`, exact body length and consistent total archive size. A server that ignores Range and returns HTTP 200 is rejected immediately; the response is closed after reading no more than the requested window plus one byte. There is no fallback to a full download.
- ZIP64 and multi-disk archives are explicitly rejected rather than guessed. The first-stage inventory lists XCFramework-related paths; the successful CI audit below confirms the four required device/simulator directory variants are present, but the archive's `Info.plist` metadata and binary architectures still need direct validation.
- Usage: `python3 Scripts/inspect_remote_zip.py`. An alternate URL can be supplied with `--url`.
- The exact pinned VideoLAN endpoint has now passed the bounded CI inspection. GitHub Actions successfully received valid HTTP 206 responses, checked `Content-Range` and total-size consistency, and indexed the ZIP without downloading the full 910 MB archive.
- The ZIP central directory contains `ios-arm64`, `ios-arm64_x86_64-simulator`, `tvos-arm64` and `tvos-arm64_x86_64-simulator`, as well as macOS, watchOS and visionOS variants. This establishes that the archive contains entries for all four NEXUS device/simulator targets; it does not yet verify the XCFramework `Info.plist` platform metadata or inspect the binary Mach-O architectures.
- Added `.github/workflows/vlckit-audit.yml`, a separate five-minute, path-filtered audit workflow. It keeps the archive inspection out of normal iOS/tvOS build jobs and reruns when the inspector or audit workflow changes.
- Corrected the ZIP64 sentinel test so it uses the actual EOCD signature rather than a literal backslash sequence.
- The inspector now fetches only the compressed XCFramework `Info.plist` member by reading the central-directory local-header offset, validates the local/central header agreement, and inflates only bounded metadata members (1 MiB compressed / 4 MiB uncompressed caps). The actual archive's `AvailableLibraries` declares iOS device arm64, iOS simulator arm64+x86_64, tvOS device arm64 and tvOS simulator arm64+x86_64. It also declares macOS, watchOS and visionOS variants.
- This verifies XCFramework manifest metadata, not the Mach-O contents of each binary. Next gate: inspect binary architecture headers or perform a minimal SwiftPM package-resolution/build spike on CI. Keep the 910 MB archive out of normal build CI and do not add VLCKit to production targets.
