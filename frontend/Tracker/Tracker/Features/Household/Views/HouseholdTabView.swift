//
//  HouseholdTabView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 16..
//

import SwiftUI

struct HouseholdTabView: View {
    @State private var router = HouseholdRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HouseholdListView()
                .navigationDestination(for: HouseholdRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetDestination(for: sheet)
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func destination(for route: HouseholdRoute) -> some View {
        switch route {
        case .main:
            Text("faza")
        }
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: HouseholdSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .forgotPassword:
                Text("faza")
            }
        }
    }
}

#Preview {
    HouseholdTabView()
}
