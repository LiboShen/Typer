import Foundation

class SettingsManager: ObservableObject {
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "groqApiKey")
        }
    }
    
    static let shared = SettingsManager()
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "groqApiKey") ?? ""
    }
}
