//
//  StyleumApp.swift
//  Styleum
//
//  Created by Sameer Akhtar on 1/3/26.
//

import SwiftUI
import GoogleSignIn

@main
struct StyleumApp: App {
    // Initialize managers at app launch
    private let supabase = SupabaseManager.shared
    private let haptics = HapticManager.shared

    init() {
        // Configure Google Sign-In with client ID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
        print("✅ Google Sign-In configured with client ID")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    print("📱 Received URL: \(url)")
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
