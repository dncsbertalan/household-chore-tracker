import Foundation

/// Keeps strings created outside SwiftUI in the same language as the interface.
nonisolated enum AppLocalization {
    static func string(
        _ key: String.LocalizationValue,
        language: AppLanguage = .selected()
    ) -> String {
        String(localized: key, bundle: language.bundle, locale: language.locale)
    }

    static func string(
        _ key: StaticString,
        defaultValue: String.LocalizationValue,
        language: AppLanguage = .selected()
    ) -> String {
        String(
            localized: key,
            defaultValue: defaultValue,
            bundle: language.bundle,
            locale: language.locale
        )
    }
}
