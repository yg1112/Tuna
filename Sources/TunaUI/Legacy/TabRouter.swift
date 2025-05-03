import SwiftUI
import TunaTypes

@MainActor
public final class TabRouter: ObservableObject {
    public static let shared = TabRouter()
    @Published public var current: TunaTypes.Tab = .dictation
    public func switchTo(_ tab: TunaTypes.Tab) { self.current = tab }
    private init() {}
}
