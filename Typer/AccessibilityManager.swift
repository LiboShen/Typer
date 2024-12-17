//
//  AccessibilityManager.swift
//  Typer
//
//  Created by Wenyu on 12/7/24.
//

import Cocoa

class AccessibilityManager {
    class func getAllRunningApplicationsWithAXContent() -> [NSRunningApplication: [AXUIElement]] {
        var result: [NSRunningApplication: [AXUIElement]] = [:]

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var value: AnyObject?
            let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
            if error == .success, let windows = value as? [AXUIElement] {
                result[app] = windows
            }
        }

        return result
    }

    class func printAXUIElementTree(_ element: AXUIElement, level: Int = 0) {
        var attributeNames: CFArray?
        let error = AXUIElementCopyAttributeNames(element, &attributeNames)

        if error == .success, let names = attributeNames as? [String] {
            for name in names {
                var value: AnyObject?
                let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)

                if error == .success {
                    let indent = String(repeating: "  ", count: level)
                    print("\(indent)\(name): \(value ?? "nil" as AnyObject)")
                    if name == kAXChildrenAttribute as String, let children = value as? [AXUIElement] {
                        for child in children {
                            printAXUIElementTree(child, level: level + 1)
                        }
                    }
                }
            }
        }
    }
}
