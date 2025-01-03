import Foundation

enum LocalizedString: String {
    // Tab Items
    case home = "home"
    case setup = "setup"
    case calendar = "calendar"
    
    // Setup Screen
    case shiftConfiguration = "shift_configuration"
    case shiftName = "shift_name"
    case startTime = "start_time"
    case endTime = "end_time"
    case selectCalendar = "select_calendar"
    case notifications = "notifications"
    case enableNotifications = "enable_notifications"
    case notificationTime = "notification_time"
    case shiftDetails = "shift_details"
    case allDay = "all_day"
    
    // Home Screen
    case selectDates = "select_dates"
    case selectShift = "select_shift"
    case assignShift = "assign_shift"
    case noShiftsConfigured = "no_shifts_configured"
    
    // Calendar Screen
    case syncStatus = "sync_status"
    case lastSync = "last_sync"
    
    // General
    case save = "save"
    case cancel = "cancel"
    case delete = "delete"
    case edit = "edit"
    case add = "add"
    
    func localized() -> String {
        let language = SettingsManager.shared.settings.language
        
        let translations: [AppSettings.Language: [String: String]] = [
            .dutch: [
                "home": "Home",
                "setup": "Instellingen",
                "calendar": "Agenda",
                "shift_configuration": "Shift Configuratie",
                "shift_name": "Shift Naam",
                "start_time": "Starttijd",
                "end_time": "Eindtijd",
                "select_calendar": "Selecteer Agenda",
                "notifications": "Meldingen",
                "enable_notifications": "Meldingen Inschakelen",
                "notification_time": "Melding Tijd",
                "shift_details": "Shift Details",
                "all_day": "Hele Dag",
                "select_dates": "Selecteer Datums",
                "select_shift": "Selecteer Shift",
                "assign_shift": "Shift Toewijzen",
                "no_shifts_configured": "Geen Shifts Geconfigureerd",
                "sync_status": "Synchronisatie Status",
                "last_sync": "Laatste Synchronisatie",
                "save": "Opslaan",
                "cancel": "Annuleren",
                "delete": "Verwijderen",
                "edit": "Bewerken",
                "add": "Toevoegen"
            ],
            .english: [
                "home": "Home",
                "setup": "Setup",
                "calendar": "Calendar",
                "shift_configuration": "Shift Configuration",
                "shift_name": "Shift Name",
                "start_time": "Start Time",
                "end_time": "End Time",
                "select_calendar": "Select Calendar",
                "notifications": "Notifications",
                "enable_notifications": "Enable Notifications",
                "notification_time": "Notification Time",
                "shift_details": "Shift Details",
                "all_day": "All Day",
                "select_dates": "Select Dates",
                "select_shift": "Select Shift",
                "assign_shift": "Assign Shift",
                "no_shifts_configured": "No Shifts Configured",
                "sync_status": "Sync Status",
                "last_sync": "Last Sync",
                "save": "Save",
                "cancel": "Cancel",
                "delete": "Delete",
                "edit": "Edit",
                "add": "Add"
            ]
        ]
        
        return translations[language]?[self.rawValue] ?? self.rawValue
    }
}
