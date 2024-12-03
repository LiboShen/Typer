//
//  Typer.swift
//  Typer
//
//  Created by Libo Shen on 28/11/2024. Hello, hello, hey, yo.
//

import SwiftUI

@main
struct TyperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
