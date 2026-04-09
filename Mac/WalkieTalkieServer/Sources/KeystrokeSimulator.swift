import CoreGraphics

enum KeystrokeSimulator {
    private static let kVK_Tab: CGKeyCode = 0x30
    private static let kVK_Grave: CGKeyCode = 0x32
    private static let kVK_Function: CGKeyCode = 0x3F

    static func simulateCtrlGrave() {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Grave, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Grave, keyDown: false) else {
            print("Failed to create CGEvent")
            return
        }
        keyDown.flags = .maskControl
        keyDown.post(tap: .cghidEventTap)
        // Clear control flag on key-up so it doesn't stick
        keyUp.flags = []
        keyUp.post(tap: .cghidEventTap)
        // Post a bare flags-changed event to ensure modifiers are fully released
        if let clearFlags = CGEvent(source: source) {
            clearFlags.type = .flagsChanged
            clearFlags.flags = []
            clearFlags.post(tap: .cghidEventTap)
        }
    }

    static func simulateEnter() {
        let source = CGEventSource(stateID: .hidSystemState)
        let kVK_Return: CGKeyCode = 0x24
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Return, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Return, keyDown: false) else {
            print("Failed to create CGEvent")
            return
        }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    static func simulateFunction() {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Function, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Function, keyDown: false) else {
            print("Failed to create CGEvent")
            return
        }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
