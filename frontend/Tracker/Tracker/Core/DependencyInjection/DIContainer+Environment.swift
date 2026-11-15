//
//  DIContainer+Environment.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = DependencyContainer()
}

extension EnvironmentValues {
    var container: DependencyContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
