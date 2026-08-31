# STEP 10 — Testing and Validation Plan

## Test Categories

### Automated Tests (flutter test)
These tests run without physical hardware and validate models, state logic, and widget rendering.

### Manual Tests (Physical iPhone + Real Receiver Required)
These tests require a real iPhone on the same Wi-Fi network as a Google Cast device (Chromecast, Android TV, etc.) and/or an AirPlay receiver (Apple TV, HomePod).

---

## A. Google Cast Discovery

### Automated (unit tests)
- `test/models/cast_device_test.dart` — CastDevice model, capabilities, copyWith
- `test/providers/device_discovery_provider_test.dart` — Provider state transitions (idle → loading → loaded), stream updates

### Manual (Physical iPhone)
**Prerequisites:**
- iPhone connected to Wi-Fi
- At least one Chromecast or Google Cast device powered on same network
- Local network permission granted to the app

**Steps:**
1. Launch app, navigate to Devices tab
2. Verify loading spinner appears during discovery
3. Verify discovered devices appear in the list
4. Verify each device shows name, icon (cast icon), and capability badges (Media Casting ✓, Screen Mirroring ✗)
5. Pull down to refresh → verify re-discovery works
6. Turn off Chromecast → pull to refresh → verify device disappears or moves to "Other devices"
7. Turn Chromecast back on → pull to refresh → verify device reappears

**Expected:** No crashes. Devices appear/disappear correctly. Error state shown if discovery fails.

---

## B. Google Cast Connection

### Automated (unit tests)
- `test/providers/device_discovery_provider_test.dart` — connectTo() calls service, error handling

### Manual (Physical iPhone)
**Steps:**
1. Discover devices, tap on a Chromecast
2. Verify connecting state (spinner on device card)
3. Verify connected state (green checkmark)
4. Verify connection timeout handling (disconnect Wi-Fi during connection attempt)
5. Verify error message shown if connection fails

**Expected:** Smooth state transitions: disconnected → connecting → connected. No crashes on timeout.

---

## C. Media Loading

### Automated (unit tests)
- `test/models/media_player_state_test.dart` — State transitions (idle → loading → casting → error)
- `test/models/cast_media_status_test.dart` — CastMediaStatus copyWith, error states

### Manual (Physical iPhone)
**Steps:**
1. Connect to Chromecast
2. Navigate to Media tab, select a video
3. Tap "Cast to Device"
4. Verify media loads on the receiver
5. Verify mini player appears at bottom of screen
6. Verify player shows correct title, duration, and playback state

**Expected:** Media starts playing on TV. Mini player updates in real-time.

---

## D. Play/Pause

### Automated (unit tests)
- `test/models/media_player_state_test.dart` — isPlaying, status transitions

### Manual (Physical iPhone)
**Steps:**
1. Cast media to Chromecast
2. Tap pause in the player
3. Verify playback pauses on receiver
4. Tap play to resume
5. Verify playback resumes

**Expected:** Play/pause toggles correctly on receiver.

---

## E. Seek

### Automated (unit tests)
- `test/models/media_player_state_test.dart` — progress, formattedPosition

### Manual (Physical iPhone)
**Steps:**
1. Cast media playing on Chromecast
2. Drag seek bar to 50%
3. Verify playback position jumps to ~50%
4. Drag to near end
5. Verify playback position updates

**Expected:** Seek works without crashes. Position updates correctly.

---

## F. Volume

### Automated (unit tests)
- `test/models/media_player_state_test.dart` — volume, isMuted

### Manual (Physical iPhone)
**Steps:**
1. Cast media playing on Chromecast
2. Adjust volume slider
3. Verify receiver volume changes
4. Toggle mute
5. Verify mute state reflected

**Expected:** Volume changes on receiver. Mute toggles correctly.

---

## G. Queue

### Automated (unit tests)
- `test/models/cast_media_status_test.dart` — CastQueueState: hasNextItem, hasPreviousItem, currentItem, itemAt, formattedItemCount

### Manual (Physical iPhone)
**Steps:**
1. Cast a queue of 3+ videos
2. Verify queue screen shows all items
3. Verify current item highlighted
4. Tap next → verify next item plays
5. Tap previous → verify previous item plays
6. Add item to queue → verify it appears in list
7. Remove item from queue → verify it disappears
8. Reorder items → verify order changes

**Expected:** Queue operations work without crashes. State stays consistent.

---

## H. Disconnect/Reconnect

### Automated (unit tests)
- `test/providers/device_discovery_provider_test.dart` — disconnect calls service
- `test/models/cast_device_test.dart` — isAnyConnected states

### Manual (Physical iPhone)
**Steps:**
1. Connect to Chromecast, cast media
2. Tap disconnect in device action sheet
3. Verify disconnected state, mini player disappears
4. Reconnect to same device
5. Verify connection restores
6. Force disconnect: turn off Chromecast while connected
7. Verify error state shown, app doesn't crash

**Expected:** Clean disconnection. No crashes on forced disconnect.

---

## I. Screen Mirroring Discovery

### Automated (unit tests)
- `test/models/cast_device_test.dart` — AirPlay device capabilities, mirroringConnectionState

### Manual (Physical iPhone)
**Prerequisites:**
- iPhone with AirPlay support
- Apple TV or AirPlay-capable device on same network

**Steps:**
1. Navigate to Devices tab
2. Verify AirPlay device appears when available
3. Verify AirPlay device shows Screen Mirroring ✓, Media Casting ✗
4. Navigate to Screen Mirror screen
5. Verify status card shows "AirPlay Available" when no active mirroring

**Expected:** AirPlay device detected and shown with correct capabilities.

---

## J. Screen Mirroring Start

### Manual (Physical iPhone)
**Steps:**
1. Navigate to Screen Mirror screen
2. Tap "Select AirPlay Device"
3. Select Apple TV from route picker
4. Verify status changes to "AirPlay Connected"
5. Verify connected device name shown

**Expected:** AirPlay route picker opens. Connection detected correctly.

**Note:** Full-device screen mirroring requires Control Center. The app can only route media to AirPlay, not mirror the full screen.

---

## K. Screen Mirroring Stop

### Manual (Physical iPhone)
**Steps:**
1. Start AirPlay media routing
2. Tap Disconnect on Screen Mirror screen
3. Verify status returns to "AirPlay Available" or "No Mirroring Active"
4. Disconnect from Control Center
5. Verify app detects disconnection

**Expected:** Clean disconnection. State updates correctly.

---

## L. Screen Mirroring Failure Cases

### Automated (unit tests)
- `test/models/media_player_state_test.dart` — error status handling
- `test/widgets/error_state_test.dart` — ErrorState widget displays messages

### Manual (Physical iPhone)
**Steps:**
1. Start AirPlay, then turn off Apple TV
2. Verify app shows disconnection state (no crash)
3. Attempt to show route picker with AirPlay disabled in Settings
4. Verify error message shown
5. Kill app during active mirroring
6. Relaunch → verify clean state (no stale mirroring state)

**Expected:** No crashes. Graceful degradation. Error messages shown.

---

## M. Device Capability Detection

### Automated (unit tests)
- `test/models/cast_device_test.dart` — supportsMediaCasting, supportsScreenMirroring, isAnyConnected

### Manual (Physical iPhone)
**Steps:**
1. Discover a Chromecast → verify it shows "Media Casting ✓, Screen Mirroring ✗"
2. Discover an Apple TV → verify it shows "Media Casting ✗, Screen Mirroring ✓"
3. On a connected device, tap to open action sheet
4. Verify only supported actions shown (Cast Media for Chromecast, Mirror Screen for AirPlay)
5. Verify Disconnect always shown for connected devices

**Expected:** Capabilities correctly detected and displayed.

---

## N. Local Network Permission

### Manual (Physical iPhone)
**Steps:**
1. Fresh install, deny local network permission
2. Navigate to Devices tab
3. Verify error message: "Local network access is required. Please enable it in Settings."
4. Go to Settings → Privacy → Local Network → enable for app
5. Return to app, pull to refresh
6. Verify devices discovered

**Expected:** Clear permission error message. Recovery after granting permission.

---

## O. App Background/Foreground

### Manual (Physical iPhone)
**Steps:**
1. Cast media playing on Chromecast
2. Press home button (background)
3. Wait 10 seconds
4. Return to app (foreground)
5. Verify mini player still shown, playback state correct
6. Verify no duplicate subscriptions or state glitches
7. Cast media, put app in background for 5+ minutes
8. Return → verify state is consistent

**Expected:** State survives background/foreground transitions. No crashes.

---

## P. Physical iPhone Testing

### Comprehensive Integration Test
**Prerequisites:**
- iPhone with iOS 16+
- Chromecast connected to same Wi-Fi
- Apple TV on same network (optional, for AirPlay tests)
- App installed on physical device

**Full Test Sequence:**
1. Launch app → verify Home screen loads
2. Navigate to Media tab → verify media grid loads
3. Tap a video → verify Media Detail screen
4. Tap "Cast to Device" → verify Devices tab or connection flow
5. Connect to Chromecast → verify connected state
6. Verify media starts playing on TV
7. Use player controls (play/pause/seek/volume)
8. Open queue → verify queue operations
9. Navigate to Screen Mirror tab
10. Verify AirPlay detection (if Apple TV available)
11. Disconnect from Chromecast → verify clean disconnect
12. Put app in background → return → verify state
13. Kill app → relaunch → verify clean state

**Expected:** No crashes. All features work as documented. Error messages are user-friendly.

---

## Platform Limitations Documented

| Limitation | Status |
|------------|--------|
| iOS does not allow third-party apps to initiate full-device screen mirroring | Documented in ScreenMirrorScreen, AirPlayChannel |
| Screen mirroring can only detect system-level mirroring state | Documented in ScreenMirrorManager |
| Media routing to AirPlay uses system route picker | Documented in AirPlayChannel |
| Google Cast SDK handles all Cast protocol communication | Encapsulated in GoogleCastManager |
| Third-party apps cannot enumerate AirPlay devices programmatically | AirPlay route picker is the only mechanism |

---

## Test Results Summary

### Automated Tests
| File | Tests | Status |
|------|-------|--------|
| cast_device_test.dart | 11 | ✓ |
| media_player_state_test.dart | 13 | ✓ |
| cast_media_status_test.dart | 10 | ✓ |
| media_item_test.dart | 6 | ✓ |
| cast_logger_test.dart | 5 | ✓ |
| device_card_test.dart | 10 | ✓ |
| error_state_test.dart | 5 | ✓ |
| device_action_sheet_test.dart | 10 | ✓ |
| device_discovery_provider_test.dart | 8 | ✓ |

### Manual Tests Required
All 16 scenarios (A-P) require physical iPhone testing.
Simulator tests DO NOT validate screen mirroring or real Cast connections.
