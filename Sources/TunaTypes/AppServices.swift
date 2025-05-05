//
//  AppServices.swift
//  @module: TunaTypes
//
//  Cross-platform service container used by app targets
//
import Foundation

/// Dependency-injection hub that groups all live services
/// (Audio, Speech, Settings, etc.).  Extend this in each app.
public struct AppServices: Sendable {
    public let audioService: any AudioServiceProtocol
    // ‼️ 在需要时继续加入其它服务，例如 settingsService

    public init(audioService: any AudioServiceProtocol) {
        self.audioService = audioService
    }
}
