import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case hungarian = "hu"

    static let storageKey = "app.language"

    var id: String { rawValue }

    static func selected(in defaults: UserDefaults = .standard) -> AppLanguage {
        defaults.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:))
            ?? .system
    }

    var locale: Locale {
        self == .system ? .current : Locale(identifier: rawValue)
    }

    var bundle: Bundle {
        guard self != .system,
            let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }
}
