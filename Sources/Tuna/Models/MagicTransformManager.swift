import AppKit
import Foundation
import TunaCore
import TunaTypes

@MainActor
class MagicTransformManager: ObservableObject {
    static let shared = MagicTransformManager(settings: TunaSettings.shared)
    @Published var lastResult: String = ""
    private let settings: TunaSettings

    init(settings: TunaSettings) {
        self.settings = settings
    }

    func run(raw: String) async {
        guard self.settings.isMagicEnabled else { return }
        let style = self.settings.magicPreset
        let polished = try? await MagicTransformService.transform(raw, style: style)
        self.lastResult = polished ?? raw
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.lastResult, forType: .string)
    }
}
