//
//  Bundle+Version.swift
//  Styleum
//
//  App version and build number utilities
//

import Foundation

extension Bundle {
    /// The app's marketing version (e.g., "1.0.0")
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// The app's build number (e.g., "42")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string (e.g., "1.0.0 (42)")
    var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }
}
