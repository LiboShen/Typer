import AVFoundation
import AppKit
import ApplicationServices
import Carbon.HIToolbox.Events
import Cocoa
import CoreGraphics
import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var permissionGranted = false
    @State private var showPermissionAlert = false
    @State private var accessibilityEnabled = false
    @StateObject private var settings = SettingsManager.shared
    let audioFilename: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("recording.m4a")
        FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
        return tempFile
    }()

    var body: some View {
        Color(
            isRecording
                ? NSColor(red: 1, green: 0.23, blue: 0.19, alpha: 0.6)
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
        let recordingDuration = audioRecorder?.currentTime ?? 0
        audioRecorder?.stop()
        isRecording = false

        // Dismiss if recording is too short
        if recordingDuration < 0.5 {
            print("Recording too short, discarding")
            return
        }

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

        // TODO: prepare the context and format the result based on it
        getFocusedWindowInfo()

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
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
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

    func insertText(_ text: String) {
        AccessibilityManager.shared.insertText(text)
    }

    func checkAccessibilityPermissions() -> Bool {
        AccessibilityManager.shared.checkAccessibilityPermissions()
    }

    func getFocusedWindowInfo() {
        AccessibilityManager.shared.getFocusedWindowInfo()
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
