import Foundation

public struct UIState: Equatable {
    public var isLaunchOpen: Bool
    public var isAudioDevicesOpen: Bool
    public var isThemeOpen: Bool
    public var isBetaOpen: Bool
    public var isAboutOpen: Bool
    public var isEngineOpen: Bool
    public var isTranscriptionOutputOpen: Bool
    public var isUpdatesOpen: Bool
    public var isAppearanceOpen: Bool
    public var isDebugOpen: Bool
    public var useSystemAppearance: Bool
    public var betaEnabled: Bool

    public init(
        isLaunchOpen: Bool = false,
        isAudioDevicesOpen: Bool = false,
        isThemeOpen: Bool = false,
        isBetaOpen: Bool = false,
        isAboutOpen: Bool = false,
        isEngineOpen: Bool = false,
        isTranscriptionOutputOpen: Bool = false,
        isUpdatesOpen: Bool = false,
        isAppearanceOpen: Bool = false,
        isDebugOpen: Bool = false,
        useSystemAppearance: Bool = true,
        betaEnabled: Bool = false
    ) {
        self.isLaunchOpen = isLaunchOpen
        self.isAudioDevicesOpen = isAudioDevicesOpen
        self.isThemeOpen = isThemeOpen
        self.isBetaOpen = isBetaOpen
        self.isAboutOpen = isAboutOpen
        self.isEngineOpen = isEngineOpen
        self.isTranscriptionOutputOpen = isTranscriptionOutputOpen
        self.isUpdatesOpen = isUpdatesOpen
        self.isAppearanceOpen = isAppearanceOpen
        self.isDebugOpen = isDebugOpen
        self.useSystemAppearance = useSystemAppearance
        self.betaEnabled = betaEnabled
    }
}
