import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()

        window = NSPanel(
            contentRect: NSRect(x: 20, y: 20, width: 40, height: 10),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)

        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.level = .floating
        window.backgroundColor = NSColor.clear
        window.backgroundColor = .clear
        window.isOpaque = false
        window.alphaValue = 0.8
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        //window.center()
        window.titleVisibility = .hidden
    }
}
