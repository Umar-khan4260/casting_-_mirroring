# iOS Screen Mirroring — Platform Limitations

## Critical: Third-Party Apps Cannot Initiate Full-Device AirPlay Mirroring

iOS **does not provide any API** for third-party applications to programmatically start full-device screen mirroring. This is a platform restriction enforced by Apple.

### What This Means

When a user wants to mirror their entire iPhone screen (home screen, other apps, system UI) to an AirPlay receiver like Apple TV, they **must**:

1. Open Control Center (swipe down from top-right)
2. Tap the Screen Mirroring button (two overlapping rectangles)
3. Select their AirPlay receiver from the list

**No code in our app can trigger this.** The user must do it manually.

### What Our App CAN Do

| Capability | Supported | How |
|---|---|---|
| Detect AirPlay availability | ✅ Yes | `AVAudioSession` route monitoring |
| Show AirPlay route picker | ✅ Yes | `AVRoutePickerView` system UI |
| Route media to AirPlay | ✅ Yes | Via route picker or `AVPlayer.externalPlayback` |
| Detect active mirroring | ✅ Yes | `UIScreen.isMirrored` + route monitoring |
| Start full-device mirroring | ❌ **No** | iOS platform restriction |
| Capture screen frames | ⚠️ Limited | Only own app via `RPScreenRecorder` (no Broadcast Extension in this module) |

### Why This Restriction Exists

Apple enforces this restriction for several reasons:

1. **Privacy**: Screen mirroring exposes the user's entire screen, including notifications, messages, and personal content
2. **Security**: Allowing apps to capture and stream the screen could enable surveillance
3. **Battery**: Continuous screen capture and streaming is power-intensive
4. **UX Control**: Apple wants to ensure users explicitly consent to screen sharing

### What About ReplayKit / ScreenCaptureKit?

These frameworks allow screen **capture**, but with significant limitations:

- `RPScreenRecorder.startCapture()` — Only captures the app's own screen, stops when app backgrounds
- `RPBroadcastSampleHandler` (Broadcast Upload Extension) — Can capture system-wide screen, but requires a separate extension target with 50MB memory limit, and cannot initiate AirPlay mirroring
- `ScreenCaptureKit` — Newer API with more control, but still captures frames, doesn't provide AirPlay mirroring

None of these frameworks can **start** AirPlay mirroring. They capture frames that must be transported via a custom pipeline (WebRTC + SFU + custom receiver) — which requires backend infrastructure.

### Our Implementation

Given these restrictions, our screen mirroring module provides:

1. **AirPlay Media Routing** — Present the system `AVRoutePickerView` to route AVPlayer content to Apple TV / AirPlay speakers
2. **Mirroring Detection** — Detect when the user has manually started screen mirroring via Control Center
3. **User Guidance** — Clear step-by-step instructions for enabling full-device mirroring
4. **Modular Architecture** — The interface is designed so a future Broadcast Upload Extension + WebRTC pipeline can be added without changing the Flutter UI

### Testing

To test AirPlay functionality:
1. You need a physical iPhone (simulator does not support AirPlay)
2. You need an AirPlay receiver (Apple TV, AirPlay-enabled speaker, or Mac with AirPlay)
3. Both devices must be on the same Wi-Fi network
4. Full-device screen mirroring requires the user to use Control Center

### References

- [Apple: Supporting AirPlay in your app](https://developer.apple.com/documentation/avfoundation/supporting-airplay-in-your-app)
- [Apple: AVRoutePickerView](https://developer.apple.com/documentation/avkit/avroutepickerview)
- [Apple: ReplayKit](https://developer.apple.com/documentation/replaykit)
- [Apple: ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [STEP 6 Investigation Report](step6_screen_mirroring_architecture.md)
