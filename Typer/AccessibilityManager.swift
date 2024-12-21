import AppKit
import ApplicationServices

class AccessibilityManager {
    static let shared = AccessibilityManager()
    private let systemWideElement: AXUIElement

    private init() {
        systemWideElement = AXUIElementCreateSystemWide()
    }  // Singleton

    // MARK: - Public Methods

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

    func insertText(_ text: String) {
        let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        print("Current application: \(bundleIdentifier)")

        if AppBehavior.pastePreferred.contains(bundleIdentifier) {
            insertTextViaPaste(text)
        } else if !insertTextViaAX(text) {
            insertTextViaPaste(text)

        }
    }

    func getFocusedApplicationTitle() -> String? {
        guard let appElement = getFocusedApplication() else { return nil }

        return getElementTitle(from: appElement)
    }

    func getFocusedWindowTitle() -> String? {
        guard let appElement = getFocusedWindow() else { return nil }

        return getElementTitle(from: appElement)
    }

    func getTextContexts() -> (before: String, selected: String, after: String)? {
        guard let element = getFocusedElement() else { return nil }

        // Try to get selected text range
        var selectedRangeValue: AnyObject?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeValue
        )

        if let fullText = getElementText(from: element),
            rangeResult == .success
        {
            let selectedRange = selectedRangeValue as! AXValue
            var range = CFRange(location: 0, length: 0)
            AXValueGetValue(selectedRange, .cfRange, &range)

            let before = String(fullText.prefix(range.location))
            let selected = String(
                fullText[
                    fullText.index(
                        fullText.startIndex, offsetBy: range.location)..<(fullText.index(
                            fullText.startIndex, offsetBy: range.location + range.length))
                ])
            let after = String(fullText.suffix(fullText.count - (range.location + range.length)))

            return (before: before, selected: selected, after: after)
        }

        return nil
    }

    // MARK: - Insertion Methods

    private func insertTextViaAX(_ text: String) -> Bool {
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions not granted")
            return false
        }

        guard let element = getFocusedElement() else {
            return false
        }

        if AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        ) == .success {
            print("Successfully inserted text using AXSelectedText")
            return true
        }
        return false
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

    // MARK: - Context Methods

    private func getFocusedApplication() -> AXUIElement? {
        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )

        guard appResult == .success else {
            print("Failed to get focused application")
            return nil
        }
        let appElement = focusedApp as! AXUIElement
        return appElement

    }

    private func getFocusedWindow() -> AXUIElement? {
        guard let appElement = getFocusedApplication() else { return nil }

        var focusedWindow: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )

        guard windowResult == .success else {
            print("Failed to get focused window")
            return nil
        }

        let element = focusedWindow as! AXUIElement
        return element
    }

    private func getFocusedElement() -> AXUIElement? {
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

    private func getElementTitle(from element: AXUIElement) -> String? {
        var titleValue: AnyObject?
        if AXUIElementCopyAttributeValue(
            element,
            kAXTitleAttribute as CFString,
            &titleValue
        ) == .success,
            let title = titleValue as? String
        {
            return title
        }
        return nil
    }

    private func getElementText(from element: AXUIElement) -> String? {
        var valueResult: AnyObject?
        let valueStatus = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueResult
        )

        if valueStatus == .success,
            let fullText = valueResult as? String
        {
            return fullText
        }
        return nil
    }
}

// MARK: - App Behavior Configuration

private enum AppBehavior {
    static let pastePreferred = Set([
        //"com.microsoft.VSCode",
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        //"com.apple.Safari",
        //"com.google.Chrome",
        "md.obsidian",
        "net.whatsapp.WhatsApp",
    ])

    static let accessibilityPreferred = Set([
        "com.apple.TextEdit",
        "com.apple.Notes",
    ])
}
