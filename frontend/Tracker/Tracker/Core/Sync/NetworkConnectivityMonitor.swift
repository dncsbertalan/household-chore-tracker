import Foundation
import Network

@MainActor
protocol ConnectivityMonitoring {
    func start(_ update: @escaping @MainActor @Sendable (Bool) -> Void)
    func stop()
}

@MainActor
final class NetworkConnectivityMonitor: ConnectivityMonitoring {
    private var monitor: NWPathMonitor?
    private var generation: UUID?

    func start(_ update: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard monitor == nil else { return }
        let id = UUID()
        let monitor = NWPathMonitor()
        self.monitor = monitor
        generation = id
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard self?.generation == id else { return }
                update(connected)
            }
        }
        monitor.start(queue: DispatchQueue(label: "Tracker.sync.connectivity"))
    }

    func stop() {
        generation = nil
        monitor?.cancel()
        monitor = nil
    }
}
