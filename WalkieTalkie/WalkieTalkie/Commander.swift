import Foundation
import Network
import Combine

final class Commander: ObservableObject {
    @Published var isConnected = false
    @Published var statusText: String = "Idle"

    private var connection: NWConnection?
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "udp-sender")
    private var manualHost: String?

    // MARK: - Auto-discovery via Bonjour

    func startAuto() {
        statusText = "Searching..."
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_walkietalkie._udp", domain: nil), using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            if let result = results.first {
                DispatchQueue.main.async {
                    self.statusText = "Found server"
                }
                self.browser?.cancel()
                self.browser = nil
                self.connectTo(endpoint: result.endpoint)
            } else {
                DispatchQueue.main.async {
                    self.statusText = "Searching..."
                }
            }
        }

        browser?.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                DispatchQueue.main.async { self?.statusText = "Discovery failed" }
            }
        }

        browser?.start(queue: queue)

        // Timeout after 5 seconds — prompt user to use manual IP
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.browser != nil, !self.isConnected else { return }
            self.statusText = "Not found — try manual IP"
        }
    }

    // MARK: - Manual IP

    func startManual(host: String, port: UInt16 = 9876) {
        manualHost = host
        statusText = "Connecting to \(host)..."
        let endpoint = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        connectTo(host: endpoint, port: nwPort)
    }

    // MARK: - Connection

    private func connectTo(endpoint: NWEndpoint) {
        connection?.cancel()
        connection = NWConnection(to: endpoint, using: .udp)
        setupConnection()
    }

    private func connectTo(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        connection?.cancel()
        connection = NWConnection(host: host, port: port, using: .udp)
        setupConnection()
    }

    private func setupConnection() {
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                guard let self else { return }
                switch state {
                case .ready:
                    self.isConnected = true
                    self.statusText = "Connected"
                case .failed:
                    self.isConnected = false
                    self.statusText = "Connection failed"
                case .cancelled:
                    self.isConnected = false
                default:
                    break
                }
            }
        }
        connection?.start(queue: queue)
    }

    // MARK: - Disconnect

    func disconnect() {
        connection?.cancel()
        connection = nil
        browser?.cancel()
        browser = nil
        manualHost = nil
        isConnected = false
        statusText = "Idle"
    }

    // MARK: - Send

    func send(byte: UInt8) {
        guard let connection else { return }
        connection.send(content: Data([byte]), completion: .contentProcessed { error in
            if let error {
                print("UDP send error: \(error)")
            }
        })
    }
}
