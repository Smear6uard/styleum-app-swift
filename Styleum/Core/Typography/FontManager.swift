//
//  FontManager.swift
//  Styleum
//
//  Font registration for custom fonts stored in asset catalog
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import CoreText

/// Handles registration of custom fonts from asset catalog data sets
enum FontManager {

    /// Font asset names in the asset catalog
    private static let fontAssets = [
        "ClashDisplay-Extralight",
        "ClashDisplay-Light",
        "ClashDisplay-Regular",
        "ClashDisplay-Medium",
        "ClashDisplay-Semibold",
        "ClashDisplay-Bold"
    ]

    /// Registers all custom fonts. Call once at app launch.
    static func registerFonts() {
        for fontName in fontAssets {
            registerFont(named: fontName)
        }
    }

    /// Registers a single font from asset catalog data set
    private static func registerFont(named assetName: String) {
        guard let dataAsset = NSDataAsset(name: assetName) else {
            print("⚠️ [Font] Could not load data asset: \(assetName)")
            return
        }

        guard let provider = CGDataProvider(data: dataAsset.data as CFData) else {
            print("⚠️ [Font] Could not create data provider for: \(assetName)")
            return
        }

        guard let cgFont = CGFont(provider) else {
            print("⚠️ [Font] Could not create CGFont for: \(assetName)")
            return
        }

        // Create CTFont from CGFont, then get its descriptor for modern registration
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, 0, nil, nil)
        let fontDescriptor = CTFontCopyFontDescriptor(ctFont)
        let fontDescriptors = [fontDescriptor] as CFArray

        // Track registration success
        var registrationSucceeded = true
        CTFontManagerRegisterFontDescriptors(
            fontDescriptors,
            .process,
            true
        ) { errors, done -> Bool in
            if let errors = errors as? [CFError], !errors.isEmpty {
                registrationSucceeded = false
            }
            return true
        }

        if registrationSucceeded {
            print("✅ [Font] Registered: \(assetName)")
        } else {
            // Font might already be registered, which is fine
            print("⚠️ [Font] Could not register \(assetName) (may already be registered)")
        }
    }

    #if canImport(UIKit)
    /// Debug: Lists all available font families (useful for finding exact font names)
    static func listAvailableFonts() {
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }
    #endif
}
