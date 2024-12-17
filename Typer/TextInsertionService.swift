import AppKit
import ApplicationServices

class TextInsertionService {
    static let shared = TextInsertionService()

    private init() {}  // Singleton

    // MARK: - Public Methods

    func insertText(_ text: String) {
        let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        print("Current application: \(bundleIdentifier)")

        if AppBehavior.pastePreferred.contains(bundleIdentifier) {
            insertTextViaPaste(text)
        } else if !insertTextAtCursor(text) {
            insertTextViaPaste(text)

        }
    }

    func checkAccessibilityPermissions() -> Bool {
        let options =
            NSDictionary(
                object: kCFBooleanTrue!,
                forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
            ) as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        print(accessibilityEnabled ? "Accessibility enabled" : "Accessibility disabled")
        return accessibilityEnabled
    }

    func getFocusedWindowInfo() {
        guard let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement? else { return }

        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )

        guard appResult == .success else {
            print("Failed to get focused application")
            return
        }
        let appElement = focusedApp as! AXUIElement

        printWindowInfo(for: appElement)
    }

    // MARK: - Private Methods

    private func insertTextAtCursor(_ text: String) -> Bool {
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions not granted")
            return false
        }

        guard let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement?,
            let element = getFocusedElement(from: systemWideElement)
        else {
            return false
        }

        return tryMultipleInsertionMethods(text: text, element: element)
    }

    private func insertTextViaPaste(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        simulateCommandV()

        // Restore previous clipboard content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let previousContent = previousContent {
                pasteboard.clearContents()
                pasteboard.setString(previousContent, forType: .string)
            }
        }
    }

    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)

        vKeyDown?.flags = .maskCommand
        vKeyUp?.flags = .maskCommand

        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)
    }

    private func getFocusedElement(from systemWideElement: AXUIElement) -> AXUIElement? {
        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success else {
            print("Failed to get focused element: \(focusResult)")
            return nil
        }

        let element = focusedElement as! AXUIElement
        return element
    }

    private func tryMultipleInsertionMethods(text: String, element: AXUIElement) -> Bool {
        // Method 1: Direct value setting
        if AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            text as CFTypeRef
        ) == .success {
            print("Successfully inserted text using AXValue")
            return true
        }

        // Method 2: Selected text setting
        if AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        ) == .success {
            print("Successfully inserted text using AXSelectedText")
            return true
        }

        // Method 3: Append to current value
        if tryAppendingText(text, to: element) {
            return true
        }

        return false
    }

    private func tryAppendingText(_ text: String, to element: AXUIElement) -> Bool {
        var currentValue: AnyObject?
        let getCurrentResult = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &currentValue
        )

        guard getCurrentResult == .success else {
            return false
        }

        let currentText = currentValue as! String
        let newValue = currentText + text
        return AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            newValue as CFTypeRef
        ) == .success
    }

    private func printWindowInfo(for appElement: AXUIElement) {
        var focusedWindow: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )

        guard windowResult == .success else {
            print("Failed to get focused window")
            return
        }

        let windowElement = focusedWindow as! AXUIElement
        printWindowAttributes(windowElement)
    }

    private func printWindowAttributes(_ windowElement: AXUIElement) {
        // Print title
        var titleValue: AnyObject?
        if AXUIElementCopyAttributeValue(
            windowElement,
            kAXTitleAttribute as CFString,
            &titleValue
        ) == .success,
            let title = titleValue as? String
        {
            print("Focused window title: \(title)")
        }

        // Print position
        var positionValue: AnyObject?
        if AXUIElementCopyAttributeValue(
            windowElement,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success {
            let position = positionValue as! AXValue
            var point = CGPoint.zero
            AXValueGetValue(position, .cgPoint, &point)
            print("Window position: \(point)")
        }

        // Print size
        var sizeValue: AnyObject?
        if AXUIElementCopyAttributeValue(
            windowElement,
            kAXSizeAttribute as CFString,
            &sizeValue
        ) == .success {
            let size = sizeValue as! AXValue
            var sizeStruct = CGSize.zero
            AXValueGetValue(size, .cgSize, &sizeStruct)
            print("Window size: \(sizeStruct)")
        }
    }
}

// MARK: - App Behavior Configuration

private enum AppBehavior {
    static let pastePreferred = Set([
        "com.microsoft.VSCode",
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.apple.Safari",
        "com.google.Chrome",
    ])

    static let accessibilityPreferred = Set([
        "com.apple.TextEdit",
        "com.apple.Notes",
    ])
}
