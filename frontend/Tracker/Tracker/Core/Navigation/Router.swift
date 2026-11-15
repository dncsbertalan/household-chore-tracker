//
//  Router.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

@MainActor
@Observable
final class Router<Route: Hashable, Sheet: Identifiable> {

    // MARK: - Navigation State

    var path = NavigationPath()
    var sheet: Sheet?

    // MARK: - Navigation

    /// Pushes a new route onto the navigation stack.
    func navigate(to route: Route) {
        path.append(route)
    }

    /// Removes the current screen from the navigation stack.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Removes all screens and returns to the root.
    func popToRoot() {
        path = NavigationPath()
    }

    /// Replaces the current screen with another route.
    func replace(with route: Route) {
        pop()
        navigate(to: route)
    }

    /// Clears the navigation stack and navigates to a route.
    func setRoot(_ route: Route) {
        popToRoot()
        navigate(to: route)
    }

    // MARK: - Sheets

    /// Presents a sheet.
    func present(_ sheet: Sheet) {
        self.sheet = sheet
    }

    /// Dismisses the currently presented sheet.
    func dismissSheet() {
        sheet = nil
    }
}
