import CoreGraphics
import Foundation

struct EmulatorWindowSize: Equatable {
    let width: Int
    let height: Int
}

enum EmulatorAudioRecoveryReason: Equatable {
    case startup
    case windowResize
    case halWriteFailure

    var logDescription: String {
        switch self {
        case .startup:
            return "game startup"
        case .windowResize:
            return "game window resize"
        case .halWriteFailure:
            return "repeated Audio HAL write failures"
        }
    }
}

enum EmulatorAudioFailureClassifier {
    static func isHALWriteFailure(_ line: String) -> Bool {
        let isWriteFailure = line.contains("pcmWrite:") || line.contains("pcm_writei")
        return isWriteFailure
            && (line.contains("failure: -1")
                || line.contains("I/O error")
                || line.contains("failed"))
    }
}

struct EmulatorAudioRecoveryPolicy {
    private let startupDelay: TimeInterval
    private let settleDelay: TimeInterval
    private let cooldown: TimeInterval
    private let failureThreshold: Int
    private let failureWindow: TimeInterval
    private var startedAt: TimeInterval?
    private var startupRecoveryPending = true
    private var lastSize: EmulatorWindowSize?
    private var resizeSettledAt: TimeInterval?
    private var lastRecoveryAt: TimeInterval?
    private var failureBurstStartedAt: TimeInterval?
    private var failureCount = 0

    init(
        startupDelay: TimeInterval = 1.5,
        settleDelay: TimeInterval = 0.75,
        cooldown: TimeInterval = 5,
        failureThreshold: Int = 6,
        failureWindow: TimeInterval = 1.5
    ) {
        self.startupDelay = startupDelay
        self.settleDelay = settleDelay
        self.cooldown = cooldown
        self.failureThreshold = failureThreshold
        self.failureWindow = failureWindow
    }

    mutating func observe(
        size: EmulatorWindowSize?,
        at now: TimeInterval
    ) -> EmulatorAudioRecoveryReason? {
        if startedAt == nil { startedAt = now }

        if startupRecoveryPending,
           let startedAt,
           now - startedAt >= startupDelay {
            return requestRecovery(for: .startup, at: now)
        }

        guard let size else { return nil }
        guard let lastSize else {
            self.lastSize = size
            return nil
        }
        if size != lastSize {
            self.lastSize = size
            resizeSettledAt = now + settleDelay
            return nil
        }
        guard let resizeSettledAt, now >= resizeSettledAt else { return nil }
        self.resizeSettledAt = nil
        return requestRecovery(for: .windowResize, at: now)
    }

    mutating func observeHALWriteFailure(at now: TimeInterval) -> EmulatorAudioRecoveryReason? {
        if failureBurstStartedAt.map({ now - $0 > failureWindow }) ?? true {
            failureBurstStartedAt = now
            failureCount = 1
            return nil
        }
        failureCount += 1
        guard failureCount >= failureThreshold else { return nil }
        failureBurstStartedAt = nil
        failureCount = 0
        return requestRecovery(for: .halWriteFailure, at: now)
    }

    private mutating func requestRecovery(
        for reason: EmulatorAudioRecoveryReason,
        at now: TimeInterval
    ) -> EmulatorAudioRecoveryReason? {
        if let lastRecoveryAt, now - lastRecoveryAt < cooldown { return nil }
        startupRecoveryPending = false
        lastRecoveryAt = now
        failureBurstStartedAt = nil
        failureCount = 0
        return reason
    }
}

private struct EmulatorAudioRecoveryConfiguration {
    let targetPID: pid_t
    let adb: URL
    let log: URL
}

private final class EmulatorAudioRecoverySession {
    private static let pollInterval: TimeInterval = 0.25

    private let configuration: EmulatorAudioRecoveryConfiguration
    private let queue = DispatchQueue(label: "dev.sergeinaumov.mactician.audio-recovery")
    private let lock = NSLock()
    private var policy = EmulatorAudioRecoveryPolicy()
    private var stopped = false
    private var timer: DispatchSourceTimer?
    private var recoveryProcess: Process?
    private var monitorProcess: Process?
    private var monitorPipe: Pipe?
    private var monitorBuffer = Data()

    init(configuration: EmulatorAudioRecoveryConfiguration) {
        self.configuration = configuration
    }

    func start() {
        queue.async { [self] in
            installAudioMonitor()
            installTimer()
        }
    }

    func stop() {
        let (timer, recoveryProcess, monitorProcess, monitorPipe) = withLock {
            stopped = true
            let timer = self.timer
            self.timer = nil
            let recoveryProcess = self.recoveryProcess
            self.recoveryProcess = nil
            let monitorProcess = self.monitorProcess
            self.monitorProcess = nil
            let monitorPipe = self.monitorPipe
            self.monitorPipe = nil
            return (timer, recoveryProcess, monitorProcess, monitorPipe)
        }
        timer?.setEventHandler {}
        timer?.cancel()
        monitorPipe?.fileHandleForReading.readabilityHandler = nil
        if recoveryProcess?.isRunning == true { recoveryProcess?.terminate() }
        if monitorProcess?.isRunning == true { monitorProcess?.terminate() }
    }

    private func installTimer() {
        guard !isStopped else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in self?.poll() }
        timer.schedule(
            deadline: .now(),
            repeating: Self.pollInterval,
            leeway: .milliseconds(75)
        )
        timer.resume()
        let installed = withLock {
            guard !stopped else { return false }
            self.timer = timer
            return true
        }
        if !installed { timer.cancel() }
    }

    private func poll() {
        guard !isStopped else { return }
        ensureAudioMonitor()
        let size = Self.mainWindowSize(for: configuration.targetPID)
        if let reason = policy.observe(
            size: size,
            at: ProcessInfo.processInfo.systemUptime
        ) {
            recoverAudio(reason: reason)
        }
    }

    private func installAudioMonitor() {
        guard !isStopped else { return }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = configuration.adb
        process.arguments = [
            "-P", "5038", "-s", "emulator-5582",
            "logcat", "-v", "brief", "-T", "1",
            "android.hardware.audio@7.1-impl.ranchu:E",
            "AudioSystem:E",
            "*:S"
        ]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.environment = Self.adbEnvironment
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.queue.async { self?.consumeMonitorOutput(data) }
        }
        process.terminationHandler = { [weak self] finishedProcess in
            self?.queue.async {
                self?.monitorDidTerminate(finishedProcess)
            }
        }

        let registered = withLock {
            guard !stopped, monitorProcess == nil else { return false }
            monitorProcess = process
            monitorPipe = pipe
            return true
        }
        guard registered else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return
        }

        do {
            try process.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            withLock {
                if monitorProcess === process {
                    monitorProcess = nil
                    monitorPipe = nil
                }
            }
            guard !isStopped else { return }
            SystemServices.appendLog(
                "Emulator audio monitor could not start: \(error.localizedDescription)",
                to: configuration.log
            )
        }
    }

    private func ensureAudioMonitor() {
        let isRunning = withLock { monitorProcess?.isRunning == true }
        if !isRunning { installAudioMonitor() }
    }

    private func monitorDidTerminate(_ process: Process) {
        withLock {
            guard monitorProcess === process else { return }
            monitorPipe?.fileHandleForReading.readabilityHandler = nil
            monitorProcess = nil
            monitorPipe = nil
        }
    }

    private func consumeMonitorOutput(_ data: Data) {
        guard !isStopped else { return }
        monitorBuffer.append(data)
        while let newline = monitorBuffer.firstIndex(of: 0x0A) {
            let lineData = monitorBuffer[..<newline]
            monitorBuffer.removeSubrange(...newline)
            let line = String(decoding: lineData, as: UTF8.self)
            guard EmulatorAudioFailureClassifier.isHALWriteFailure(line) else { continue }
            if let reason = policy.observeHALWriteFailure(
                at: ProcessInfo.processInfo.systemUptime
            ) {
                recoverAudio(reason: reason)
            }
        }
    }

    private func recoverAudio(reason: EmulatorAudioRecoveryReason) {
        let process = Process()
        process.executableURL = configuration.adb
        process.arguments = [
            "-P", "5038", "-s", "emulator-5582",
            "shell", "su", "0", "killall", "audioserver"
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.environment = Self.adbEnvironment

        let registered = withLock {
            guard !stopped, recoveryProcess == nil else { return false }
            recoveryProcess = process
            return true
        }
        guard registered else { return }
        defer {
            withLock {
                if recoveryProcess === process { recoveryProcess = nil }
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
            guard !isStopped else { return }
            if process.terminationStatus == 0 {
                SystemServices.appendLog(
                    "Emulator audio recovery completed after \(reason.logDescription).",
                    to: configuration.log
                )
            } else {
                SystemServices.appendLog(
                    "Emulator audio recovery exited with status \(process.terminationStatus).",
                    to: configuration.log
                )
            }
        } catch {
            guard !isStopped else { return }
            SystemServices.appendLog(
                "Emulator audio recovery could not start: \(error.localizedDescription)",
                to: configuration.log
            )
        }
    }

    private var isStopped: Bool { withLock { stopped } }

    private static var adbEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.merging([
            "ANDROID_ADB_SERVER_PORT": "5038",
            "ADB_MDNS_AUTO_CONNECT": ""
        ]) { _, new in new }
    }

    private static func mainWindowSize(for targetPID: pid_t) -> EmulatorWindowSize? {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            CGWindowID(kCGNullWindowID)
        ) as? [[CFString: Any]] else { return nil }

        var best: (size: EmulatorWindowSize, area: Int)?
        for window in windows {
            guard (window[kCGWindowOwnerPID] as? NSNumber)?.int32Value == targetPID,
                  (window[kCGWindowLayer] as? NSNumber)?.intValue == 0,
                  let bounds = window[kCGWindowBounds] as? NSDictionary,
                  let rawWidth = bounds["Width"] as? NSNumber,
                  let rawHeight = bounds["Height"] as? NSNumber else {
                continue
            }
            let width = Int(rawWidth.doubleValue.rounded())
            let height = Int(rawHeight.doubleValue.rounded())
            guard width >= 500, height >= 300, width > height else { continue }
            let area = width * height
            if best.map({ area > $0.area }) ?? true {
                best = (EmulatorWindowSize(width: width, height: height), area)
            }
        }
        return best?.size
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

final class EmulatorAudioRecoveryService {
    private let lock = NSLock()
    private var session: EmulatorAudioRecoverySession?

    deinit {
        stop()
    }

    func start(targetPID: pid_t, adb: URL, log: URL) {
        stop()
        let session = EmulatorAudioRecoverySession(configuration: .init(
            targetPID: targetPID,
            adb: adb,
            log: log
        ))
        withLock { self.session = session }
        session.start()
    }

    func stop() {
        let session = withLock {
            defer { self.session = nil }
            return self.session
        }
        session?.stop()
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
