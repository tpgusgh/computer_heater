import SwiftUI

// Shared knobs read by worker threads.
final class Control: @unchecked Sendable {
    private let lock = NSLock()
    private var _gen = 0, _duty = 0.5, _paused = false
    func set(gen: Int? = nil, duty: Double? = nil, paused: Bool? = nil) {
        lock.lock(); defer { lock.unlock() }
        if let gen { _gen = gen }; if let duty { _duty = duty }; if let paused { _paused = paused }
    }
    func read() -> (gen: Int, duty: Double, paused: Bool) {
        lock.lock(); defer { lock.unlock() }
        return (_gen, _duty, _paused)
    }
}

@MainActor
final class Heater: ObservableObject {
    @Published var on = false { didSet { on ? start() : stop() } }
    @Published var level = 50.0 { didSet { ctl.set(duty: level / 100) } }      // % of each 100ms slice spent burning
    @Published var cores = Double(ProcessInfo.processInfo.activeProcessorCount) { didSet { if on { start() } } }
    @Published var thermal = ProcessInfo.processInfo.thermalState
    let maxCores = Double(ProcessInfo.processInfo.activeProcessorCount)
    private let ctl = Control()
    private var gen = 0

    init() {
        ctl.set(duty: level / 100)
        // Safety: pause when macOS reports serious/critical thermal pressure.
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.thermal = ProcessInfo.processInfo.thermalState
                self.ctl.set(paused: self.thermal.rawValue >= ProcessInfo.ThermalState.serious.rawValue)
            }
        }
    }

    private func start() {
        gen += 1
        ctl.set(gen: gen)
        let (myGen, ctl) = (gen, ctl)
        for _ in 0..<Int(cores) {
            let t = Thread { burn(gen: myGen, ctl: ctl) }
            t.qualityOfService = .userInitiated
            t.start()
        }
    }

    private func stop() { gen += 1; ctl.set(gen: gen) }

    var thermalText: String {
        switch thermal {
        case .nominal: "정상"
        case .fair: "따뜻함"
        case .serious: "뜨거움 — 일시정지"
        case .critical: "위험 — 일시정지"
        @unknown default: "?"
        }
    }
}

// Duty-cycled busy loop: burn `duty` of each slice, sleep the rest. Exits when generation changes.
nonisolated func burn(gen: Int, ctl: Control) {
    let slice = 0.1
    var x = 1.0
    while true {
        let s = ctl.read()
        if s.gen != gen { break }
        if s.paused { Thread.sleep(forTimeInterval: 1); continue }
        let end = Date().addingTimeInterval(slice * s.duty)
        while Date() < end { for _ in 0..<5_000 { x = x * 1.000_000_1 + 1e-9 } }
        if x == .infinity { print(x) } // keep optimizer from deleting the loop
        if s.duty < 1 { Thread.sleep(forTimeInterval: slice * (1 - s.duty)) }
    }
}

@main
struct HeaterApp: App {
    @StateObject private var h = Heater()

    var body: some Scene {
        Window("Heater", id: "main") { panel }
            .windowResizability(.contentSize)
        MenuBarExtra { panel } label: {
            Image(systemName: h.on ? "flame.fill" : "flame")
        }
        .menuBarExtraStyle(.window)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("히터 켜기", isOn: $h.on).toggleStyle(.switch)
            Text("세기 \(Int(h.level))%")
            Slider(value: $h.level, in: 5...100, step: 5)
            Text("코어 \(Int(h.cores)) / \(Int(h.maxCores))")
            Slider(value: $h.cores, in: 1...h.maxCores, step: 1)
            Text("온도 상태: \(h.thermalText)").foregroundStyle(h.thermal.rawValue >= 2 ? .red : .secondary)
            Divider()
            Button("종료") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 240)
    }
}
