import Foundation

class ShiftStore: ObservableObject {
    static let shared = ShiftStore()
    
    @Published var shifts: [Shift] = []
    private let shiftsKey = "shifts"
    
    private init() {
        loadShifts()
    }
    
    func loadShifts() {
        print("Loading shifts from UserDefaults")
        if let data = UserDefaults.standard.data(forKey: shiftsKey),
           let decodedShifts = try? JSONDecoder().decode([Shift].self, from: data) {
            shifts = decodedShifts
            print("Loaded shifts: \(shifts)")
        }
    }
    
    func saveShifts() {
        print("Saving shifts to UserDefaults")
        if let encoded = try? JSONEncoder().encode(shifts) {
            UserDefaults.standard.set(encoded, forKey: shiftsKey)
            print("Saved shifts: \(shifts)")
        }
    }
    
    func addShift(_ shift: Shift) {
        print("Adding shift: \(shift)")
        shifts.append(shift)
        saveShifts()
    }
    
    func updateShift(_ shift: Shift) {
        print("Updating shift: \(shift)")
        if let index = shifts.firstIndex(where: { $0.id == shift.id }) {
            shifts[index] = shift
            saveShifts()
        }
    }
    
    func deleteShift(_ shift: Shift) {
        print("Deleting shift: \(shift)")
        shifts.removeAll(where: { $0.id == shift.id })
        saveShifts()
        print("Remaining shifts: \(shifts)")
    }
}
