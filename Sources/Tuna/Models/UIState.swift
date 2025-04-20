import SwiftUI

/// Manages all UI-related state for the Tuna app
/// This class centralizes all transient UI state that doesn't need persistence
@MainActor
final class UIState: ObservableObject {
    // MARK: - Window States
    @Published var isAudioDevicesOpen = false
    @Published var isAppearanceOpen = false
    @Published var isDebugOpen = false
    @Published var isAboutOpen = false
    @Published var isThemeOpen = false
    @Published var isBetaOpen = false
    @Published var isShortcutOpen = false
    @Published var isLaunchOpen = false
    @Published var isSmartSwapOpen = false
    @Published var isUpdatesOpen = false
    @Published var isMagicTransformOpen = false
    @Published var isEngineOpen = false
    @Published var isTranscriptionOutputOpen = false
    @Published var isSmartSwapsOpen = false
    
    // MARK: - Section Enum for Automated Testing
    enum Section: String, CaseIterable {
        case audioDevices = "isAudioDevicesOpen"
        case appearance = "isAppearanceOpen"
        case debug = "isDebugOpen"
        case about = "isAboutOpen"
        case theme = "isThemeOpen"
        case beta = "isBetaOpen"
        case shortcut = "isShortcutOpen"
        case launch = "isLaunchOpen"
        case smartSwap = "isSmartSwapOpen"
        case updates = "isUpdatesOpen"
        case magicTransform = "isMagicTransformOpen"
        case engine = "isEngineOpen"
        case transcriptionOutput = "isTranscriptionOutputOpen"
        case smartSwaps = "isSmartSwapsOpen"
        
        var keyPath: ReferenceWritableKeyPath<UIState, Bool> {
            switch self {
            case .audioDevices: return \.isAudioDevicesOpen
            case .appearance: return \.isAppearanceOpen
            case .debug: return \.isDebugOpen
            case .about: return \.isAboutOpen
            case .theme: return \.isThemeOpen
            case .beta: return \.isBetaOpen
            case .shortcut: return \.isShortcutOpen
            case .launch: return \.isLaunchOpen
            case .smartSwap: return \.isSmartSwapOpen
            case .updates: return \.isUpdatesOpen
            case .magicTransform: return \.isMagicTransformOpen
            case .engine: return \.isEngineOpen
            case .transcriptionOutput: return \.isTranscriptionOutputOpen
            case .smartSwaps: return \.isSmartSwapsOpen
            }
        }
    }
} 