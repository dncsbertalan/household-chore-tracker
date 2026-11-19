import SwiftUI

struct ChoreStatusCapsule: View {
    let status: ChoreResponse.Status
    
    private var color: Color {
        switch status {
        case .pending: .orange
        case .inProgress: .blue
        case .awaitingApproval: .purple
        case .completed: .green
        case .skipped: .secondary
        case .cancelled: .red
        }
    }
    
    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
    }
}
