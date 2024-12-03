import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var audioRecorder: AVAudioRecorder?
    @State private var permissionGranted = false
    let audioFilename: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("recording.m4a")
        FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
        return tempFile
    }()

    var body: some View {
        VStack {
            if permissionGranted {
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    Text(isRecording ? "Recording..." : "Tap to Record")
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Text("Transcribed Text:")
                    .font(.headline)
                    .padding(.top)

                ScrollView {
                    Text(transcribedText)
                        .padding()
                }
            } else {
                Text("Microphone access is required")
                    .foregroundColor(.red)
                Button("Request Microphone Access") {
                    requestMicrophonePermission()
                }
            }
        }
        .padding()
        .onAppear {
            checkMicrophonePermission()
        }
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
            "language": "en",
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
                    self.transcribedText = text
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
}

// Extension to append strings to Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
