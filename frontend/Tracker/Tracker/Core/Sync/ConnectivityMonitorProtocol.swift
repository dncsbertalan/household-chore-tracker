@MainActor
protocol ConnectivityMonitorProtocol {
    func start(_ update: @escaping @MainActor @Sendable (Bool) -> Void)
    func stop()
}
