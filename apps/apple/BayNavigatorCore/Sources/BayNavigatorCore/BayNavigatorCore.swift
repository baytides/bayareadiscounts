// BayNavigatorCore - Shared Swift Package for Bay Navigator Apps
//
// This package contains all the shared code for iOS, macOS, and visionOS apps:
// - Models: Program, Category, Group, Area, etc.
// - ViewModels: ProgramsViewModel, SettingsViewModel, etc.
// - Services: APIService, CacheService, LocationService, etc.
// - Extensions: Color theme, accessibility helpers
// - Data: Location lookup tables

// Re-export all public types
@_exported import Foundation
@_exported import SwiftUI

// MARK: - Version Info
public enum BayNavigatorCore {
    public static let version = "1.0.0"
    public static let bundleIdentifier = "org.baytides.navigator"
}
