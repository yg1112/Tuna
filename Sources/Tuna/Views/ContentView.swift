import SwiftUI
import TunaCore
import TunaSpeech
import TunaTypes
import TunaUI

struct ContentView: View {
    @EnvironmentObject var settings: TunaSettings
    @EnvironmentObject var dictationManager: DictationManager
    @EnvironmentObject var tabRouter: TabRouter

    var body: some View {
        TabView(selection: self.$tabRouter.current) {
            TunaDictationView()
                .tabItem {
                    Label("Dictation", systemImage: "mic")
                }
                .tag(Tab.dictation)

            TunaSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .frame(minWidth: 400, minHeight: 600)
    }
}
