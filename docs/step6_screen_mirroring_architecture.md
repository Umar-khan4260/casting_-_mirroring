# STEP 6 — Native iOS Screen Mirroring Investigation

## Executive Summary

Full-device screen mirroring from a third-party iOS app is **fundamentally constrained by Apple's APIs**. There is no way to programmatically initiate system-level AirPlay mirroring, and Google Cast has explicitly deprecated and removed screen mirroring support. The only viable path is a **Broadcast Upload Extension** that captures screen frames and streams them over WebRTC to a custom receiver. This requires significant native Swift code, a backend SFU, and custom receiver applications.

---

## 1. Apple iOS Screen Capture APIs

### A. RPScreenRecorder (ReplayKit)

| Capability | In-App Capture | System-Wide Capture |
|---|---|---|
| **API** | `RPScreenRecorder.shared().startCapture()` | `RPBroadcastSampleHandler` (Broadcast Upload Extension) |
| **Captures other apps / system** | **No** — only the app's own windows | **Yes** — entire device screen |
| **Survives backgrounding** | **No** — stops immediately when app backgrounds | **Yes** — extension runs independently |
| **Memory limit** | App-wide (~1-2 GB) | **50 MB hard cap** (jetsam kills on exceed) |
| **IPC to main app** | Not needed | Required (App Group + CFMessagePort / socket / SFU direct) |
| **Start UX** | In-app button | System Broadcast Picker (`RPSystemBroadcastPickerView`) |
| **Cold-start latency** | Instant | ~1-2 seconds to launch extension process |
| **Scope** | 1-2 developer days | 7-14 developer days incl. QA |

**Key limitations:**
- `RPScreenRecorder.startCapture()` **only captures the app's own screen** — it cannot capture other apps, the home screen, or system UI
- Only one app at a time can use the recorder
- Cannot record video from AVPlayer
- Enabling mic/camera after capture starts does NOT work on iOS (only macOS)

### B. ScreenCaptureKit (iOS 15+)

ScreenCaptureKit is Apple's newer framework offering more granular control:
- Can capture the **entire display** or **in-app content** via `SCContentSharingPicker`
- Delivers frames as `CMSampleBuffer` objects (IOSurface-backed on iOS)
- Supports camera overlay (in-app mode only, not full-display)
- Supports recording to MP4 via `SCRecordingOutput`
- Supports clipping via `SCClipBufferingOutput` (15-second rolling buffer)
- iOS 27 sample code available with full-display and in-app capture modes

**However:** ScreenCaptureKit does NOT provide AirPlay mirroring. It captures frames and delivers them to your app — you must handle encoding and transport yourself.

### C. Broadcast Upload Extension (BUE)

This is the **only way to capture the full device screen** on iOS:

**Architecture:**
```
┌─────────────────────────────────┐
│         iOS System              │
│  ┌─────────────────────────┐   │
│  │  Broadcast Upload Ext   │   │
│  │  (RPBroadcastSampleHandler) │
│  │  - Separate process     │   │
│  │  - 50 MB memory cap     │   │
│  │  - Receives CMSampleBuffers│ │
│  │  - No UI surface        │   │
│  └────────────┬────────────┘   │
│               │ IPC            │
│  ┌────────────▼────────────┐   │
│  │     Main App            │   │
│  │  - Flutter/Dart code    │   │
│  │  - WebRTC peer connection│  │
│  │  - UI controls          │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**Critical constraints:**
- **50 MB hard memory limit** — one raw 2732×2048 BGRA frame is ~22 MB
- Must downsample to 1280×720 NV12 (~1.4 MB per frame)
- Must use H.264 hardware encoder via `VTCompressionSession` (VP8 is software-only and will blow memory)
- Recommended: 20-30 fps, 720p resolution
- User starts broadcast via `RPSystemBroadcastPickerView` (mandatory on iOS 12+, `RPBroadcastActivityViewController` deprecated since iOS 16)
- User stops broadcast via Control Center

**Two IPC Patterns:**

| Pattern | Description | Survives Backgrounding |
|---|---|---|
| **Pattern 1: Extension → Main App** | Extension forwards frames via CFMessagePort / IOSurface / App Group socket to main app, which owns the WebRTC connection | **No** — main app may be suspended |
| **Pattern 2: Extension → SFU Direct** | Extension runs its own mini WebRTC/WebSocket client, publishes screen track directly to SFU | **Yes** — extension runs independently |

**Pattern 2 is the production-recommended approach** (used by Zoom, LiveKit, GetStream, 100ms, Dyte, Agora).

---

## 2. Conceptual Breakdown

### A. Capturing the iPhone Screen

| Method | Scope | Feasibility |
|---|---|---|
| `RPScreenRecorder.startCapture()` | In-app only | ✅ Easy, but limited |
| `RPBroadcastSampleHandler` (BUE) | Full device | ✅ Possible, complex |
| `ScreenCaptureKit` (iOS 15+) | Full display or in-app | ✅ Newer API, more control |

**Verdict:** System-wide capture is possible via Broadcast Upload Extension. This is the only path for "mirror the complete iPhone screen."

### B. Encoding Captured Frames

- Must happen **inside the Broadcast Upload Extension** (50 MB limit)
- **H.264 via `VTCompressionSession`** — hardware encoder, stays within memory budget
- VP8/VP9: software-only on iOS, will exceed 50 MB limit within seconds
- HEVC/H.265: works but rarely worth the complexity for real-time
- Downsample to 720p NV12 using `VTPixelTransferSession` or `vImageScale_*`
- Throttle to 20-30 fps (60 fps will exhaust memory budget)

### C. Transporting the Stream

| Method | Latency | Reliability | Complexity |
|---|---|---|---|
| WebRTC (to SFU) | Low (~100-300ms) | High | High |
| WebSocket + HLS/DASH | High (~2-5s) | Medium | Medium |
| Custom protocol | Varies | Varies | Very High |

**Recommendation:** WebRTC via an SFU (Selective Forwarding Unit) is the industry standard for real-time screen sharing.

### D. Receiving/Decoding on a TV

| Target | Reception Method | Feasibility |
|---|---|---|
| **Apple TV** | AirPlay (system-level) | ⚠️ Cannot initiate from third-party app |
| **Chromecast** | Custom Web Receiver (HTML5) | ⚠️ Limited (~15fps on custom web apps) |
| **Smart TV (Samsung/LG)** | Custom receiver app | ⚠️ Platform-specific development |
| **Raspberry Pi / NUC** | Custom receiver app | ✅ Most flexible |

### E. System-Level AirPlay Mirroring

**Critical finding:** Third-party apps **cannot programmatically initiate** AirPlay mirroring.

- AirPlay mirroring is triggered by the user via **Control Center** only
- `AVRoutePickerView` provides an AirPlay picker, but this is for **media playback routing**, not full-device screen mirroring
- There is NO Apple API to start AirPlay mirroring from code
- The only programmatic AirPlay interaction is `AVPlayer` external playback routing (video content only)

---

## 3. What Our Flutter Application Can Do

| Capability | Possible? | How |
|---|---|---|
| Start full-device screen mirroring | ❌ **No** | Cannot initiate AirPlay; Cast Remote Display deprecated |
| Capture iPhone screen frames | ✅ **Yes** | Via Broadcast Upload Extension (RPBroadcastSampleHandler) |
| Encode captured frames | ✅ **Yes** | H.264 via VTCompressionSession inside extension |
| Stream to Google Cast | ⚠️ **Very Limited** | Google Cast SDK only supports media casting, not arbitrary video streams. Custom Web Receiver possible but ~15fps limit. |
| Stream to AirPlay receivers | ⚠️ **Very Limited** | Would need to stream to a custom AirPlay receiver app on Apple TV, which requires tvOS development |
| Work without a backend | ❌ **No** | WebRTC requires a signaling server at minimum; SFU recommended for reliability |

---

## 4. Required Components

| Layer | Technology | Responsibility |
|---|---|---|
| **Flutter** | Dart, Flutter widgets | UI, state management, navigation, cast connection UI |
| **Swift (Method Channel)** | ReplayKit, ScreenCaptureKit | Launch `RPSystemBroadcastPickerView`, communicate with extension |
| **Swift (Broadcast Extension)** | `RPBroadcastSampleHandler` | Capture screen frames, encode H.264, publish to SFU |
| **Backend SFU** | LiveKit / Janus / mediasoup / custom | Receive WebRTC stream, forward to receivers |
| **Receiver** | HTML5 (Chromecast) or native (Apple TV) | Decode and display the stream |
| **Infrastructure** | Server hosting SFU | Minimal: SFU server + signaling endpoint |

---

## 5. What Requires What

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER (Dart)                       │
│  - App UI (HomeScreen, MediaDetailScreen, etc.)        │
│  - Cast connection management                          │
│  - Method Channel calls to native iOS                  │
│  - State management (AppCastingController)             │
└────────────────────────┬────────────────────────────────┘
                         │ Method Channel
┌────────────────────────▼────────────────────────────────┐
│              NATIVE SWIFT (Main App)                    │
│  - ReplayKit integration                               │
│  - RPSystemBroadcastPickerView launch                  │
│  - WebRTC peer connection management                   │
│  - Signaling with SFU                                  │
└────────────────────────┬────────────────────────────────┘
                         │ App Group IPC
┌────────────────────────▼────────────────────────────────┐
│         NATIVE SWIFT (Broadcast Upload Extension)       │
│  - RPBroadcastSampleHandler                            │
│  - Frame capture (CMSampleBuffer)                      │
│  - Downsample to 720p NV12                             │
│  - H.264 encoding (VTCompressionSession)               │
│  - Direct publish to SFU (Pattern 2)                   │
│  - 50 MB memory budget management                      │
└────────────────────────┬────────────────────────────────┘
                         │ WebRTC
┌────────────────────────▼────────────────────────────────┐
│              SFU SERVER (Backend)                       │
│  - LiveKit Cloud / Self-hosted                         │
│  - Receive screen track from iOS extension             │
│  - Forward to connected receivers                      │
│  - Signaling (WebSocket)                               │
└────────────────────────┬────────────────────────────────┘
                         │ WebRTC / WebSocket
┌────────────────────────▼────────────────────────────────┐
│              RECEIVER (Target Device)                   │
│  - Chromecast: HTML5 Web Receiver (JavaScript)         │
│  - Apple TV: Native tvOS app (Swift)                   │
│  - Smart TV: Platform-specific receiver                │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Honest Assessment of "Mirror the Complete iPhone Screen"

**The user wants:** "mirror the complete iPhone screen, not just media."

**Reality check:**

1. **AirPlay mirroring** — This is exactly what AirPlay does (mirror complete iPhone screen to Apple TV). But **third-party apps cannot initiate it**. The user must manually go to Control Center → Screen Mirroring → select Apple TV. Our app cannot trigger this.

2. **Google Cast mirroring** — Google explicitly deprecated and removed the Cast Remote Display API. Their response: *"We decided to drop support... there is no alternative."* The Cast SDK only supports media casting (loading a video URL), not arbitrary screen mirroring.

3. **Custom approach** — The only path is:
   - Broadcast Upload Extension captures screen frames
   - Extension encodes H.264 and publishes via WebRTC to an SFU
   - A custom receiver on the target device subscribes to the WebRTC stream
   - This works, but requires: a backend SFU, custom receivers on each target platform, and significant native Swift development

**Bottom line:** True "mirror the complete iPhone screen" to a Chromecast or Apple TV is either impossible via third-party APIs (AirPlay) or requires a fully custom streaming pipeline (WebRTC + SFU + custom receiver).

---

## 7. Concrete Recommendation for First Supported Receiver Target

### Recommended: Chromecast with Custom Web Receiver

**Why Chromecast first:**
- Chromecast runs a web browser — we can build a receiver as a hosted HTML5 page
- No need to develop native tvOS/Android TV apps
- WebRTC client libraries exist for Chromecast (limited but functional)
- Lower barrier to entry than Apple TV (no tvOS developer account needed beyond existing Apple Developer)

**Architecture for Phase 1:**

```
iOS App (Flutter + Swift)
    │
    ├── In-App Capture (RPScreenRecorder.startCapture)
    │   └── Only captures own app screen
    │   └── Simple, fast to implement (1-2 days)
    │   └── Good for demos and showing app UI on TV
    │
    └── System-Wide Capture (Broadcast Upload Extension)
        └── Captures full device screen
        └── Complex, requires Swift extension (7-14 days)
        └── Production-quality screen mirroring
```

**Phase 1 (MVP): In-App Capture → WebRTC → Chromecast**

1. Use `RPScreenRecorder.startCapture()` to capture the app's own screen
2. Encode frames as H.264 via `VTCompressionSession`
3. Publish to a lightweight SFU (LiveKit Cloud recommended, $50/mo)
4. Chromecast loads a custom Web Receiver page
5. Web Receiver subscribes to the WebRTC stream
6. Display on TV

**Limitations of Phase 1:**
- Only captures the app's own screen (not home screen, other apps)
- Stops when app backgrounds
- Good for: fitness apps, presentations, in-app content sharing
- NOT good for: "mirror everything on my phone"

**Phase 2 (Full Mirroring): Broadcast Upload Extension → WebRTC → Chromecast**

1. Add Broadcast Upload Extension target
2. Implement `RPBroadcastSampleHandler` in Swift
3. Downsample to 720p, encode H.264, publish directly to SFU from extension
4. Survives backgrounding
5. Captures entire device screen

**Estimated effort:** 2-3 sprints for a senior iOS engineer (including memory tuning, QA across iPhone models)

---

## 8. What NOT to Build

1. **Do NOT try to use Google Cast Remote Display API** — it's deprecated and removed
2. **Do NOT try to programmatically start AirPlay mirroring** — Apple provides no API for this
3. **Do NOT try to send raw pixel buffers over Google Cast** — the SDK only handles media URLs
4. **Do NOT try to run WebRTC inside a Broadcast Upload Extension without SFU** — the extension cannot host a persistent connection to a Chromecast directly
5. **Do NOT assume ScreenCaptureKit provides AirPlay** — it captures frames, it doesn't mirror
6. **Do NOT use VP8/VP9 in the extension** — will exceed 50 MB memory limit

---

## 9. Flutter Plugin Options

For launching the Broadcast Upload Extension from Flutter:

| Plugin | Purpose | Notes |
|---|---|---|
| `replay_kit_launcher` | Launch `RPSystemBroadcastPickerView` | Lightweight, handles picker UI |
| `flutter_webrtc` | WebRTC + ReplayKit integration | Full WebRTC stack, supports broadcast extension |
| `livekit_client` | WebRTC via LiveKit with built-in ReplayKit | Production-ready, includes `LKSampleHandler` |

**Recommendation:** Use `livekit_client` if choosing LiveKit as SFU. It provides a complete `LKSampleHandler` subclass that handles the Broadcast Upload Extension, memory management, and direct SFU publishing. This avoids building the extension from scratch.

---

## 10. Decision Points for the Team

Before proceeding to implementation, confirm:

1. **Receiver target priority:** Chromecast first? Apple TV first? Both?
2. **Scope:** In-app capture only (Phase 1) or full device mirroring (Phase 2)?
3. **SFU choice:** LiveKit Cloud, self-hosted, or another provider?
4. **Backend:** Will we host a signaling/SFU server, or use a managed service?
5. **Budget:** LiveKit Cloud starts at $50/mo; self-hosted requires server infrastructure
6. **Timeline:** Phase 1 (in-app only): ~1 week. Phase 2 (full mirroring): ~3-4 weeks.

---

*This investigation was completed without writing production screen-mirroring code. All findings are based on Apple documentation, Google Cast documentation, and production experiences from video platforms (LiveKit, GetStream, 100ms, Zoom, Agora).*
