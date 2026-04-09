import Foundation
import Network
import ApplicationServices
import AppKit

// Check Accessibility permission
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
if !AXIsProcessTrustedWithOptions(options) {
    print("⚠️  Accessibility permission not granted.")
    print("   Go to System Settings → Privacy & Security → Accessibility")
    print("   and add this application to the allowed list.")
    print("   The app will continue running but Cmd+Tab simulation will fail.")
}

setbuf(stdout, nil) // Disable output buffering

let listener = try! NWListener(using: .udp, on: 9876)

// Advertise via Bonjour so iPhone can find us automatically
listener.service = NWListener.Service(name: "WalkieTalkie", type: "_walkietalkie._udp")

listener.newConnectionHandler = { connection in
    print("[server] New connection from \(connection.endpoint)")
    connection.start(queue: .main)
    receiveMessage(on: connection)
}

listener.stateUpdateHandler = { state in
    switch state {
    case .ready:
        print("[server] Listening on UDP :9876")
        print("[server] Bonjour: advertising as _walkietalkie._udp")
    case .failed(let error):
        print("[server] Listener failed: \(error)")
        exit(1)
    case .waiting(let error):
        print("[server] Listener waiting: \(error)")
    default:
        print("[server] Listener state: \(state)")
    }
}

listener.start(queue: .main)

func receiveMessage(on connection: NWConnection) {
    connection.receiveMessage { data, _, _, error in
        if let error = error {
            print("Receive error: \(error)")
            return
        }
        if let data = data, let firstByte = data.first {
            switch firstByte {
            case 0x01:
                print("→ Ctrl+`")
                KeystrokeSimulator.simulateCtrlGrave()
            case 0x02:
                print("→ Function key")
                KeystrokeSimulator.simulateFunction()
                // Always watch clipboard — if SuperWhisper pastes, auto-Enter
                waitForClipboardChangeThenEnter()
            default:
                print("Unknown command: 0x\(String(firstByte, radix: 16))")
            }
        }
        receiveMessage(on: connection)
    }
}

var clipboardWatcherID: UInt64 = 0

var enterFiredRecently = false

func waitForClipboardChangeThenEnter() {
    clipboardWatcherID &+= 1
    let myID = clipboardWatcherID
    let pasteboard = NSPasteboard.general
    let initialCount = pasteboard.changeCount
    let startTime = DispatchTime.now()
    DispatchQueue.global().async {
        for _ in 0..<100 {
            usleep(100_000)
            if myID != clipboardWatcherID { return }
            if pasteboard.changeCount != initialCount {
                // Ignore clipboard changes within first 0.5s (likely just the Fn press itself)
                let elapsed = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
                if elapsed < 500_000_000 { continue }
                // Don't fire Enter if we just fired one recently
                if enterFiredRecently { return }
                enterFiredRecently = true
                usleep(300_000)
                KeystrokeSimulator.simulateEnter()
                print("→ Clipboard changed, Enter pressed")
                // Reset the guard after 2 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    enterFiredRecently = false
                }
                return
            }
        }
    }
}

dispatchMain()
