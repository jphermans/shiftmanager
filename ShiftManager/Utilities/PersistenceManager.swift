import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let defaults = UserDefaults.standard
    
    private let shiftsKey = "savedShifts"
    private let assignmentsKey = "savedAssignments"
    
    private init() {}
    
    // MARK: - Shifts
    func saveShifts(_ shifts: [Shift]) {
        if let encoded = try? JSONEncoder().encode(shifts) {
            defaults.set(encoded, forKey: shiftsKey)
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        }
    }
    
    func loadShifts() -> [Shift] {
        guard let data = defaults.data(forKey: shiftsKey),
              let shifts = try? JSONDecoder().decode([Shift].self, from: data) else {
            return []
        }
        return shifts
    }
    
    // MARK: - Assignments
    func saveAssignments(_ assignments: [ShiftAssignment]) {
        if let encoded = try? JSONEncoder().encode(assignments) {
            defaults.set(encoded, forKey: assignmentsKey)
        }
    }
    
    func loadAssignments() -> [ShiftAssignment] {
        guard let data = defaults.data(forKey: assignmentsKey),
              let assignments = try? JSONDecoder().decode([ShiftAssignment].self, from: data) else {
            return []
        }
        return assignments
    }
}
