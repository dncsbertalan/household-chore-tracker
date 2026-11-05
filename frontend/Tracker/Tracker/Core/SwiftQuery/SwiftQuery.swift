// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import SwiftUI
import Observation

@Observable
public final class QueryClient: @unchecked Sendable {
    private var cache: [AnyHashable: Any] = [:]

    public init() {}

    public func get<Value>(_ key: AnyHashable) -> Value? {
        cache[key] as? Value
    }

    public func set<Value>(_ value: Value, for key: AnyHashable) {
        cache[key] = value
    }

    public func update<Value>(_ key: AnyHashable, _ transform: (inout Value) -> Void) {
        guard var current: Value = get(key) else { return }
        transform(&current)
        set(current, for: key)
    }

    public func invalidate(_ key: AnyHashable) {
        cache.removeValue(forKey: key)
    }
}

extension QueryClient {
    public static let shared = QueryClient()
}

public struct QueryClientKey: EnvironmentKey {
    public static let defaultValue = QueryClient.shared
}

public extension EnvironmentValues {
    var queryClient: QueryClient {
        get { self[QueryClientKey.self] }
        set { self[QueryClientKey.self] = newValue }
    }
}

public struct QueryCacheKey<F: QueryFunc>: Hashable where F.Variables: Hashable {
    let variables: F.Variables

    public init(variables: F.Variables) {
        self.variables = variables
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(reflecting: F.self))
        hasher.combine(variables)
    }
}
