//
//  VoiceTranscriberApp.swift
//  VoiceTranscriber
//
//  Created by Libo Shen on 28/11/2024.
//

import SwiftUI

@main
struct VoiceTranscriberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
