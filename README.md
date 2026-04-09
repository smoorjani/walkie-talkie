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

## iOS development guide

### Prerequisites

- **Xcode** (free from the Mac App Store)
- **Apple ID** — any free Apple account works for signing
- **iPhone** connected via USB (volume buttons don't work in the simulator)

### Creating the Xcode project from scratch

If you're setting up from the source files (not opening the included `.xcodeproj`):

1. Open Xcode → File → New → Project → **iOS App**
2. Product Name: `WalkieTalkie`
3. Interface: **SwiftUI**, Language: **Swift**
4. Team: select your Apple ID (**Personal Team**)
5. Organization Identifier: anything (e.g. `com.yourname`)
6. Testing System: **None**, Storage: **None**
7. Save the project
8. Delete the auto-generated `ContentView.swift` and `WalkieTalkieApp.swift`
9. Drag the Swift files from `WalkieTalkie/WalkieTalkie/` into the Xcode project navigator
10. If prompted about an Objective-C bridging header, select **Don't Create**

### Signing (free)

1. In Xcode, click the project in the sidebar → select the **WalkieTalkie** target
2. Go to **Signing & Capabilities** tab
3. Team → select your Apple ID (Personal Team)
4. Xcode will auto-create a provisioning profile

Free signing expires every **7 days**. When it expires, just plug in and hit Run again from Xcode.

### Required Info.plist keys

In the target → **Info** tab → Custom iOS Target Properties, add:

| Key | Type | Value |
|-----|------|-------|
| Bonjour services | Array | Item 0: `_walkietalkie._udp` |
| Privacy - Local Network Usage Description | String | `Connect to WalkieTalkie server on your Mac` |
| Privacy - Microphone Usage Description | String | `Needed for push-to-talk` |

Without the Bonjour and Local Network keys, auto-discovery will silently fail.

### Building and installing

1. Plug your iPhone in via USB
2. At the top of Xcode, select your iPhone as the build target (not a simulator)
3. Hit **Run** (▶) or Cmd+R
4. First time: Xcode may say "device not ready" — wait for it to process symbol files
5. On iPhone: if you see "Untrusted Developer", go to **Settings → General → VPN & Device Management** → tap your developer profile → **Trust**

### Troubleshooting

| Issue | Fix |
|-------|-----|
| "iOS X.X is not installed" | Click **Get** in Xcode's toolbar to download device support |
| "Untrusted Developer" on iPhone | Settings → General → VPN & Device Management → Trust |
| App expires after 7 days | Plug in and hit Run in Xcode again |
| `Multiple commands produce Info.plist` | Delete any manually added `Info.plist` from the project — use Xcode's Info tab instead |
| `does not conform to ObservableObject` | Ensure `import Combine` is at the top of the file |
| White screen / no UI | Check for duplicate `ContentView.swift` files — delete the Xcode-generated one |
| Volume buttons don't work | Must run on a real iPhone, not the simulator |
| Bonjour discovery stuck on "Searching" | Check that Bonjour services and Local Network keys are in Info.plist |

## Notes

- Volume detection only works on a real iPhone, not the simulator
- Free Apple developer signing expires every 7 days — re-run from Xcode to refresh
- The Fn key behavior is tailored for [SuperWhisper](https://superwhisper.com) — after stopping a recording, the server watches the clipboard and auto-presses Enter once text is pasted
