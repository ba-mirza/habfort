//
//  habfort_iosApp.swift
//  habfort-ios
//
//  Created by Almas Bisenali on 18.07.2026.
//

import SwiftUI

@main
struct habfort_iosApp: App {
    @State private var authManager: AuthManager
    @State private var apiClient: APIClient

    init() {
        let authManager = AuthManager(client: SupabaseService.shared)
        _authManager = State(initialValue: authManager)
        _apiClient = State(initialValue: APIClient(authManager: authManager))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(apiClient)
        }
    }
}
