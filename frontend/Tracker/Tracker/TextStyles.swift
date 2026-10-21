import SwiftUI

struct TextStyles: View {
    var body: some View {
        Text("Hello, World!").font(.largeTitle)
        Text("Hello, World!").font(.title)
        Text("Hello, World!").font(.title2)
        Text("Hello, World!").font(.title3)
        Text("Hello, World!").font(.headline)
        Text("Hello, World!").font(.callout)
        Text("Hello, World!").font(.caption)
        Text("Hello, World!").font(.caption2)
        Text("Hello, World!").font(.default)
        Text("Hello, World!").font(.footnote)
        Text("Hello, World!").font(.subheadline)
        //---
        Text("Hello, World!").font(.largeTitle).fontWeight(.bold)
        Text("Hello, World!").font(.title).fontWeight(.bold)
        Text("Hello, World!").font(.title2).fontWeight(.bold)
        Text("Hello, World!").font(.title3).fontWeight(.bold)
        Text("Hello, World!").font(.headline).fontWeight(.bold)
        Text("Hello, World!").font(.callout).fontWeight(.bold)
        Text("Hello, World!").font(.caption).fontWeight(.bold)
        Text("Hello, World!").font(.caption2).fontWeight(.bold)
        Text("Hello, World!").font(.default).fontWeight(.bold)
        Text("Hello, World!").font(.footnote).fontWeight(.bold)
        Text("Hello, World!").font(.subheadline).fontWeight(.bold)
    }
}

#Preview {
    TextStyles()
}
