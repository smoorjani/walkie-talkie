import AVFoundation
import MediaPlayer
import UIKit
import Combine

final class VolumeButtonDetector: ObservableObject {
    @Published var lastAction: String = "None"
    @Published var pressCount: Int = 0

    var onVolumeUp: (() -> Void)?
    var onVolumeDown: (() -> Void)?

    private let audioSession = AVAudioSession.sharedInstance()
    private var volumeObservation: NSKeyValueObservation?
    private var lastVolume: Float = -1
    private var resetTimer: Timer?

    /// Hidden MPVolumeView — needed to suppress the volume HUD
    lazy var volumeView: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        view.alpha = 0.01
        return view
    }()

    func start() {
        do {
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("AudioSession setup error: \(error)")
        }

        lastVolume = audioSession.outputVolume

        volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, let newVal = change.newValue else { return }
            let oldVal = self.lastVolume
            guard newVal != oldVal else { return }

            let wentUp = newVal > oldVal
            self.lastVolume = newVal

            DispatchQueue.main.async {
                self.pressCount += 1
                if wentUp {
                    self.lastAction = "UP #\(self.pressCount)"
                    self.onVolumeUp?()
                } else {
                    self.lastAction = "DOWN #\(self.pressCount)"
                    self.onVolumeDown?()
                }

                // Schedule a volume reset after 1 second of no presses
                self.resetTimer?.invalidate()
                self.resetTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    self.resetVolume()
                }
            }
        }
    }

    func stop() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        resetTimer?.invalidate()
    }

    private func resetVolume() {
        // Try multiple methods to reset volume to 0.5
        let slider = findSlider()
        if let slider = slider {
            let oldObservation = volumeObservation
            volumeObservation = nil  // temporarily stop observing to avoid feedback loop
            slider.setValue(0.5, animated: false)
            slider.sendActions(for: .valueChanged)
            slider.sendActions(for: .touchUpInside)
            lastVolume = 0.5
            // Re-enable observation after a beat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self else { return }
                self.volumeObservation = oldObservation
                self.lastVolume = self.audioSession.outputVolume
            }
        }
    }

    private func findSlider() -> UISlider? {
        func search(_ view: UIView) -> UISlider? {
            for sub in view.subviews {
                if let s = sub as? UISlider { return s }
                if let s = search(sub) { return s }
            }
            return nil
        }
        return search(volumeView)
    }
}
