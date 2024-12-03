import AVFoundation
import AppKit
import ApplicationServices
import Carbon.HIToolbox.Events
import CoreGraphics
import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var permissionGranted = false
    @State private var showPermissionAlert = false
    @State private var accessibilityEnabled = false
    let audioFilename: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("recording.m4a")
        FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
        return tempFile
    }()

    var body: some View {
        Color(
            isRecording
                ? NSColor(red: 1, green: 0, blue: 0, alpha: 0.6)
                : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.6)
        )
        .cornerRadius(15)
        .frame(width: 40, height: 10)
        .animation(.easeInOut, value: isRecording)
        .onAppear {
            checkMicrophonePermission()
            monitorFnKey()
            accessibilityEnabled = checkAccessibilityPermissions()
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Accessibility Permission Required"),
                message: Text(
                    "Please allow this app to monitor the keyboard by enabling accessibility permission in System Preferences."
                ),
                primaryButton: .default(Text("Open System Preferences")) {
                    openSystemPreferences()
                },
                secondaryButton: .cancel()
            )
        }
    }

    func checkAccessibilityPermissions() -> Bool {
        let options =
            NSDictionary(
                object: kCFBooleanTrue!,
                forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString)
            as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        print(accessibilityEnabled ? "Accessibility enabled" : "Accessibility disabled")
        return accessibilityEnabled
    }

    func openSystemPreferences() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestMicrophonePermission()
        default:
            permissionGranted = false
        }
        print("Microphone permission: \(permissionGranted ? "granted" : "denied")")
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                permissionGranted = granted
            }
        }
    }

    func startRecording() {
        print("Start recording to: \(audioFilename)")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),  // Audio format
            AVSampleRateKey: 12000,  // Sample rate
            AVNumberOfChannelsKey: 1,  // Number of channels
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,  // Audio quality
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            print("Started recording to: \(audioFilename)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        print("Stop recording")
        audioRecorder?.stop()
        isRecording = false

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: audioFilename.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            print("Recording stopped")
            print("File exists: \(FileManager.default.fileExists(atPath: audioFilename.path))")
            print("File size: \(fileSize) bytes")
            print("File path: \(audioFilename.path)")
        } catch {
            print("Error getting file attributes: \(error.localizedDescription)")
        }

        sendAudioToGroqAPI()
    }

    func sendAudioToGroqAPI() {
        guard let audioData = try? Data(contentsOf: audioFilename) else {
            print("Failed to read audio file")
            return
        }

        print("Audio data size: \(audioData.count) bytes")

        let boundary = UUID().uuidString
        var request = URLRequest(
            url: URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer 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",
            forHTTPHeaderField: "Authorization")
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        // Add other form fields
        let parameters = [
            "model": "whisper-large-v3-turbo",
            "temperature": "0",
            "response_format": "json",
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            // Parse JSON response
            if let json = try? JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
                let text = json["text"] as? String
            {
                DispatchQueue.main.async {
                    print("Transcribed text: \(text)")
                    self.insertText(text)
                }
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response string: \(responseString)")
                }
                print("Failed to parse JSON response")
            }
        }

        task.resume()
    }

    func monitorFnKey() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if event.modifierFlags.contains(.function) {
                if !self.isRecording {
                    self.startRecording()
                }
            } else {
                if self.isRecording {
                    self.stopRecording()
                }
            }
        }
    }

    func insertTextAtCursor(_ text: String) -> Bool {
        // First check if we have accessibility permissions
        if !checkAccessibilityPermissions() {
            DispatchQueue.main.async {
                showPermissionAlert = true
            }
            return false
        }

        guard let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement? else {
            print("Failed to create system-wide accessibility element")
            return false
        }

        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success else {
            print("Failed to get focused element: \(focusResult)")
            return false
        }

        // Get the role of the focused element
        var roleRef: AnyObject?
        let roleResult = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            kAXRoleAttribute as CFString,
            &roleRef
        )

        if roleResult == .success,
            let role = roleRef as? String
        {
            print("Focused element role: \(role)")

            // Check if it's a text field or similar
            guard ["AXTextField", "AXTextArea"].contains(role) else {
                print("Focused element is not a text field")
                return false
            }
        }

        // Try to insert the text
        let insertResult = AXUIElementSetAttributeValue(
            focusedElement as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        if insertResult == .success {
            print("Successfully inserted text")
            return true
        } else {
            print("Failed to insert text: \(insertResult)")
            return false
        }
    }

    func insertTextViaPaste(_ text: String) {
        // Save previous clipboard content
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        // Insert new text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Command+V
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)

        vKeyDown?.flags = .maskCommand
        vKeyUp?.flags = .maskCommand

        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)

        // Wait a brief moment to ensure paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Restore previous clipboard content
            if let previousContent = previousContent {
                pasteboard.clearContents()
                pasteboard.setString(previousContent, forType: .string)
            }
        }
    }

    func insertText(_ text: String) {
        if insertTextAtCursor(text) {
            print("Used accessibility method to insert text")
        } else {
            print("Falling back to paste method")
            insertTextViaPaste(text)
        }
    }

}

// Extension to append strings to Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
