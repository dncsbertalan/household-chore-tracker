//
//  ConnectionStatusView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 06..
//

import SwiftUI

struct ConnectionStatusView: View {
    let isOnline: Bool

    var color: Color { isOnline ? .green : .red }
    var title: LocalizedStringKey {
        isOnline
            ? "profile.connection.connected" : "profile.connection.notConnected"
    }

    var body: some View {
        Label(title, systemImage: isOnline ? "wifi" : "wifi.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityIdentifier("profile.connectionStatus")
    }
}

#Preview {
    ConnectionStatusView(isOnline: true)
    ConnectionStatusView(isOnline: false)
}
