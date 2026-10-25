import SwiftData

@MainActor
class AppModelContainer {
    let modelContainer: ModelContainer

    var context: ModelContext {
        modelContainer.mainContext
    }

    init(isStoredInMemory: Bool = false) {
        let schema = AppSchema.schema

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemory
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            if isStoredInMemory {}

            try context.save()
        } catch {
            fatalError("Could not open the app's SwiftData store: \(error)")
        }
    }
}
