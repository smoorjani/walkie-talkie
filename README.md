# WalkieTalkie

Use your iPhone's volume buttons to control your Mac remotely over UDP.

- **Volume Up** → Ctrl+` (switch windows)
- **Volume Down** → Fn key (trigger SuperWhisper voice-to-text) → auto-presses Enter when transcription is pasted

## How it works

The iPhone app detects volume button presses via `AVAudioSession` KVO and sends UDP packets to a Mac server. The server simulates keystrokes via `CGEvent`.

Auto-discovery via Bonjour (`_walkietalkie._udp`) — no manual IP entry needed on most networks.

## Setup

### Mac server

```bash
cd Mac/WalkieTalkieServer
swift run
```

First run: grant **Accessibility** permission when prompted (System Settings → Privacy & Security → Accessibility).

### iOS app

1. Open `WalkieTalkie/WalkieTalkie.xcodeproj` in Xcode
2. Select your iPhone as the build target
3. Sign with your Apple ID (Personal Team — free)
4. Run (▶)
5. On iPhone: Settings → General → VPN & Device Management → trust your developer profile
6. Open the app and hit Start

### Xcode project setup (first time only)

In the WalkieTalkie target → Info tab, ensure these keys exist:

- **Bonjour services**: `_walkietalkie._udp`
- **Privacy - Local Network Usage Description**: `Connect to WalkieTalkie server on your Mac`

## Connection modes

| Network | Method | IP to use |
|---------|--------|-----------|
| Home Wi-Fi | Both devices on same network | `ipconfig getifaddr en0` |
| Corporate Wi-Fi | USB-Lightning tethering | `ipconfig getifaddr en23` |
| Any | Bonjour auto-discovery | None needed |

Corporate networks often block device-to-device UDP. Plug in via USB and enable Personal Hotspot as a workaround.

## Project structure

```
Mac/WalkieTalkieServer/          # Swift Package — Mac server
├── Sources/
│   ├── main.swift               # UDP listener, clipboard watcher
│   ├── KeystrokeSimulator.swift # CGEvent: Ctrl+`, Fn, Enter
│   └── MicToggle.swift          # CoreAudio mic toggle (unused)
└── Package.swift

WalkieTalkie/WalkieTalkie/       # Xcode project — iOS app
├── WalkieTalkieApp.swift        # Entry point
├── ContentView.swift            # Dark-themed SwiftUI UI
├── Commander.swift              # Bonjour discovery + UDP sender
└── VolumeButtonDetector.swift   # Volume button detection via KVO
```

## Notes

- Volume detection only works on a real iPhone, not the simulator
- Free Apple developer signing expires every 7 days — re-run from Xcode to refresh
- The Fn key behavior is tailored for [SuperWhisper](https://superwhisper.com) — after stopping a recording, the server watches the clipboard and auto-presses Enter once text is pasted
