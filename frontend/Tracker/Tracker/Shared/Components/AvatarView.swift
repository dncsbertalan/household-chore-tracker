//
//  AvatarView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 06..
//

import SwiftUI

struct AvatarView: View {
    let firstName: String
    let lastName: String

    var imageURL: URL? = nil
    var size: CGFloat = 48

    private static let colors: [Color] = [
        .blue,
        .purple,
        .orange,
        .pink,
        .teal,
        .indigo,
        .green,
        .cyan,
        .mint,
        .brown,
    ]

    private var initials: String {
        [firstName, lastName]
            .compactMap {
                $0.split(whereSeparator: \.isWhitespace)
                    .first?
                    .prefix(1)
            }
            .joined()
            .uppercased()
    }

    private var avatarColor: Color {
        let name = "\(firstName)|\(lastName)".lowercased()

        let hash = name.unicodeScalars.reduce(UInt64(0)) {
            ($0 &* 31) &+ UInt64($1.value)
        }

        return Self.colors[Int(hash % UInt64(Self.colors.count))]
    }

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        avatarColor.opacity(0.75),
                        avatarColor,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Text(initials)
                    .font(
                        .system(
                            size: size * 0.38,
                            weight: .medium,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(size * 0.12)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    AvatarView(firstName: "Bertalan", lastName: "Dancs")
    AvatarView(firstName: "Ica", lastName: "Kukor", size: 104)
}
