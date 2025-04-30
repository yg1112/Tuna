import AppKit
import Foundation
import TunaCore

@MainActor
final class MagicTransformManager: ObservableObject {
    static let shared = MagicTransformManager()
    @Published var lastResult: String = ""

    func run(raw: String) async {
        guard TunaSettings.shared.magicEnabled else { return }
        let style = TunaSettings.shared.magicPreset
        let tpl = PromptTemplate.library[style]!
        let polished = try? await MagicTransformService.transform(raw, template: tpl)
        self.lastResult = polished ?? raw
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.lastResult, forType: .string)
    }
}
