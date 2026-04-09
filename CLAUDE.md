# WalkieTalkie

iPhone volume button remote control for Mac. Volume up sends Ctrl+`, volume down sends Fn (for SuperWhisper) with auto-Enter after clipboard change.

## Architecture

- **iOS app** (`WalkieTalkie/WalkieTalkie/`): SwiftUI app that detects volume button presses via AVAudioSession KVO and sends UDP packets to the Mac server.
- **Mac server** (`Mac/WalkieTalkieServer/`): Swift Package CLI that listens on UDP port 9876, simulates keystrokes via CGEvent, and watches clipboard for SuperWhisper auto-Enter.

## Running the Server

```bash
cd ~/walkie-talkie/Mac/WalkieTalkieServer && swift run
```

The server requires **Accessibility permission** (System Settings > Privacy & Security > Accessibility).

## Connection Types

### Home Wi-Fi (or any open network)

Both devices on the same Wi-Fi. Use the Mac's Wi-Fi IP.

```bash
ipconfig getifaddr en0
# e.g. 10.0.0.69
```

Enter this IP in the app's manual IP field and hit Start.

### Work Wi-Fi / Restricted Networks (USB-Lightning)

Corporate networks (e.g. databricks-corp, databricks-guest) block device-to-device UDP traffic. Use USB tethering instead:

1. Plug iPhone into Mac via USB/Lightning cable
2. On iPhone: Settings > Personal Hotspot > "Allow Others to Join" ON
3. Find the USB link-local IP:

```bash
ipconfig getifaddr en23
# e.g. 169.254.151.205
```

4. Enter this IP in the app's manual IP field

**Note:** The `en23` IP changes every time you reconnect the USB cable. Always re-check with `ipconfig getifaddr en23`.

### Auto-Discovery (Bonjour)

The server advertises via Bonjour (`_walkietalkie._udp`). Toggle "Manual IP" off in the app to use auto-discovery. Works on home Wi-Fi and USB, but not on networks with AP isolation.

## Key Behaviors

- **Volume UP** → sends `0x01` → Mac simulates **Ctrl+`**
- **Volume DOWN** → sends `0x02` → Mac simulates **Fn key** (starts/stops SuperWhisper)
  - After Fn, the server watches the clipboard for changes (SuperWhisper pasting transcribed text)
  - Once clipboard changes (after 0.5s debounce), auto-presses **Enter**
  - 2-second dedup guard prevents double Enter

## Known Issues

- Volume detection relies on AVAudioSession KVO — only works on a real iPhone, not the simulator
- Volume resets to 0.5 after each press, but the reset can fail on some iOS versions, causing detection to stop after ~8 presses in one direction
- Free Apple developer signing expires every 7 days — re-run from Xcode to refresh
- A zombie simulator process (PID 82831) may persist in `lsof` output — it's harmless
