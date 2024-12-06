

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var temporaryApiKey: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text("Groq API Key")
                    .font(.headline)
                SecureField("Enter your Groq API key", text: $temporaryApiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    settings.apiKey = temporaryApiKey
                    dismiss()
                }
                .disabled(temporaryApiKey.isEmpty)
            }
        }
        .padding()
        .onAppear {
            temporaryApiKey = settings.apiKey
        }
    }
}
