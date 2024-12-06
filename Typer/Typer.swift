import SwiftUI

@main
struct TyperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SettingsView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
