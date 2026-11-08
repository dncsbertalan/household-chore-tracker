//
//  LanguageSettingsView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct LanguageSettingsView: View {
    @AppStorage(AppLanguage.storageKey)
    private var language = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Picker("app.language.selector", selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName)
                        .tag(option.rawValue)
                }
            }
        }
        .navigationTitle("app.language.selector")
    }
}

#Preview {
    LanguageSettingsView()
}
