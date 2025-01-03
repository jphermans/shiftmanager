import Foundation

struct AppSettings: Codable {
    var selectedCalendarIdentifier: String?
    var enableNotifications: Bool
    var notificationTimeBeforeShift: TimeInterval // in minutes
    var language: Language
    var shifts: [Shift]
    
    enum Language: String, Codable {
        case dutch = "nl"
        case english = "en"
        
        static var systemLanguage: Language {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
            return Language(rawValue: languageCode) ?? .english
        }
    }
    
    init() {
        self.selectedCalendarIdentifier = nil
        self.enableNotifications = true
        self.notificationTimeBeforeShift = 30 * 60 // 30 minutes
        self.language = .systemLanguage
        self.shifts = []
    }
}

// Singleton for managing app settings
class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    var settings: AppSettings {
        get {
            if let data = defaults.data(forKey: settingsKey),
               let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                return settings
            }
            return AppSettings()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: settingsKey)
            }
        }
    }
    
    private init() {}
}
