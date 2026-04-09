import SwiftUI

struct ContentView: View {
    @StateObject private var commander = Commander()
    @StateObject private var detector = VolumeButtonDetector()
    @AppStorage("macIP") private var macIP: String = ""
    @AppStorage("useManualIP") private var useManualIP: Bool = true
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(isActive ? .green : .gray)

                    Text("WalkieTalkie")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)

                // Status pill
                HStack(spacing: 8) {
                    Circle()
                        .fill(commander.isConnected ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 8, height: 8)
                    Text(commander.statusText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .padding(.bottom, 24)

                // Connection mode picker
                Picker("Mode", selection: $useManualIP) {
                    Text("Auto").tag(false)
                    Text("Manual IP").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

                // Manual IP input
                if useManualIP {
                    TextField("192.168.1.x", text: $macIP)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)
                }

                // Big start/stop button
                Button {
                    toggleConnection()
                } label: {
                    Text(isActive ? "STOP" : "START")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isActive ? Color.red : Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)

                // Last action display
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        ActionCard(
                            icon: "arrow.left.arrow.right",
                            label: "Vol Up",
                            shortcut: "Ctrl + `"
                        )
                        ActionCard(
                            icon: "mic.fill",
                            label: "Vol Down",
                            shortcut: "Fn → Enter"
                        )
                    }
                    .padding(.horizontal, 24)

                    // Live feedback
                    Text(detector.lastAction)
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)

                    Text("\(detector.pressCount) presses")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer()
            }

            // Hidden volume view
            VolumeHUDHider(volumeView: detector.volumeView)
                .frame(width: 0, height: 0)
        }
        .preferredColorScheme(.dark)
    }

    private func toggleConnection() {
        if isActive {
            detector.stop()
            commander.disconnect()
            isActive = false
        } else {
            if useManualIP {
                guard !macIP.isEmpty else { return }
                commander.startManual(host: macIP)
            } else {
                commander.startAuto()
            }
            detector.onVolumeUp = { commander.send(byte: 0x01) }
            detector.onVolumeDown = { commander.send(byte: 0x02) }
            detector.start()
            isActive = true
        }
    }
}

struct ActionCard: View {
    let icon: String
    let label: String
    let shortcut: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
            Text(shortcut)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

struct VolumeHUDHider: UIViewRepresentable {
    let volumeView: UIView
    func makeUIView(context: Context) -> UIView { volumeView }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
