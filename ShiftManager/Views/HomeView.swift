import SwiftUI
import EventKit

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedDates: Set<DateComponents> = []
    @State private var showingShiftSelector = false
    @State private var currentMonth = Calendar.current.dateComponents([.year, .month], from: Date())
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                CalendarView(
                    selectedDates: $selectedDates,
                    currentMonth: $currentMonth,
                    shifts: viewModel.getAssignmentsForDateRange(from: calendar.date(from: currentMonth) ?? Date(), to: calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: currentMonth) ?? Date()) ?? Date())
                )
                .onAppear {
                    Task {
                        await viewModel.loadAssignmentsFromCalendar()
                    }
                }
                
                if !selectedDates.isEmpty {
                    Button(action: {
                        showingShiftSelector = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Wijs dienst toe")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    SelectedDatesView(
                        selectedDates: selectedDates,
                        calendar: calendar,
                        viewModel: viewModel
                    )
                }
                
                MonthlyShiftsView(
                    currentMonth: currentMonth,
                    shifts: viewModel.getAssignmentsForDateRange(from: calendar.date(from: currentMonth) ?? Date(), to: calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: currentMonth) ?? Date()) ?? Date())
                )
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingShiftSelector) {
                ShiftSelectorView(
                    selectedDates: Array(selectedDates).compactMap { calendar.date(from: $0) }.sorted(),
                    onShiftSelected: { shift in
                        Task {
                            for dateComponents in selectedDates {
                                if let date = calendar.date(from: dateComponents) {
                                    await viewModel.assignShift(shift, to: date)
                                }
                            }
                            selectedDates.removeAll()
                            showingShiftSelector = false
                        }
                    },
                    viewModel: viewModel
                )
            }
            .refreshable {
                await viewModel.loadAssignmentsFromCalendar()
            }
        }
    }
    
    private func shiftsForCurrentMonth() -> [(date: Date, shift: Shift)] {
        guard let monthStart = calendar.date(from: currentMonth),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }
        
        return viewModel.getAssignmentsForDateRange(from: monthStart, to: monthEnd)
            .sorted { $0.date < $1.date }
    }
}

struct ShiftSelectorView: View {
    let selectedDates: [Date]
    let onShiftSelected: (Shift) -> Void
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.shifts) { shift in
                    Button(action: {
                        onShiftSelected(shift)
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: shift.color))
                                .frame(width: 20, height: 20)
                            
                            VStack(alignment: .leading) {
                                Text(shift.name)
                                
                                if shift.isAllDay {
                                    Text("Hele dag")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(shift.startTime, formatter: timeFormatter) - \(shift.endTime, formatter: timeFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Selecteer Dienst")
            .navigationBarItems(trailing: Button("Annuleren") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CalendarView: View {
    @Binding var selectedDates: Set<DateComponents>
    @Binding var currentMonth: DateComponents
    let shifts: [(date: Date, shift: Shift)]
    
    var body: some View {
        VStack {
            MultiDatePicker(
                "Selecteer data",
                selection: $selectedDates
            )
            .datePickerStyle(.graphical)
            .onChange(of: selectedDates) { _ in
                updateCurrentMonth()
            }
            .tint(.blue)
            
            ShiftOverlay(shifts: shifts)
        }
    }
    
    private func updateCurrentMonth() {
        if let firstDate = selectedDates.compactMap({ Calendar.current.date(from: $0) }).min() {
            currentMonth = Calendar.current.dateComponents([.year, .month], from: firstDate)
        }
    }
}

struct ShiftOverlay: View {
    let shifts: [(date: Date, shift: Shift)]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(shifts.indices, id: \.self) { index in
                ShiftCircle(shiftInfo: shifts[index], geometry: geometry)
            }
        }
    }
}

struct ShiftCircle: View {
    let shiftInfo: (date: Date, shift: Shift)
    let geometry: GeometryProxy
    
    var body: some View {
        if let dayFrame = Calendar.current.dayFrame(for: shiftInfo.date, in: geometry.frame(in: .local)) {
            Circle()
                .fill(Color(hex: shiftInfo.shift.color).opacity(0.3))
                .frame(width: dayFrame.width * 0.8, height: dayFrame.width * 0.8)
                .position(x: dayFrame.midX, y: dayFrame.midY)
        }
    }
}

struct SelectedDatesView: View {
    let selectedDates: Set<DateComponents>
    let calendar: Calendar
    let viewModel: HomeViewModel
    
    var body: some View {
        List {
            ForEach(Array(selectedDates).compactMap { calendar.date(from: $0) }.sorted(), id: \.self) { date in
                if let assignment = viewModel.getAssignment(for: date) {
                    HStack {
                        Text(date, style: .date)
                        Spacer()
                        Text(assignment.shift.name)
                            .foregroundColor(Color(hex: assignment.shift.color))
                    }
                } else {
                    HStack {
                        Text(date, style: .date)
                        Spacer()
                        Text("Geen dienst")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

struct MonthlyShiftsView: View {
    let currentMonth: DateComponents
    let shifts: [(date: Date, shift: Shift)]
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
    
    var body: some View {
        List {
            Section(header: Text(monthYearString(from: currentMonth))) {
                ForEach(shifts, id: \.date) { shiftInfo in
                    HStack {
                        Text(dayFormatter.string(from: shiftInfo.date))
                            .font(.headline)
                            .frame(width: 40, alignment: .leading)
                        
                        Text(weekdayFormatter.string(from: shiftInfo.date))
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                        
                        Text(shiftInfo.shift.name)
                            .foregroundColor(Color(hex: shiftInfo.shift.color))
                    }
                }
            }
        }
    }
    
    private func monthYearString(from components: DateComponents) -> String {
        guard let date = Calendar.current.date(from: components) else { return "" }
        return monthYearFormatter.string(from: date)
    }
}

extension Calendar {
    func dayFrame(for date: Date, in rect: CGRect) -> CGRect? {
        let firstWeekday = self.component(.weekday, from: date)
        let dayOfMonth = self.component(.day, from: date)
        
        let weekWidth = rect.width / 7
        let weekHeight = rect.height / 6
        
        let row = (dayOfMonth + firstWeekday - 2) / 7
        let col = (dayOfMonth + firstWeekday - 2) % 7
        
        let x = CGFloat(col) * weekWidth + weekWidth / 2
        let y = CGFloat(row) * weekHeight + weekHeight / 2
        
        return CGRect(
            x: x - weekWidth / 2,
            y: y - weekHeight / 2,
            width: weekWidth,
            height: weekHeight
        )
    }
}

class HomeViewModel: ObservableObject {
    @Published var assignments: [ShiftAssignment] = []
    private let assignmentsKey = "assignments"
    
    private let shiftStore = ShiftStore.shared
    
    var shifts: [Shift] {
        shiftStore.shifts
    }
    
    init() {
        loadAssignments()
    }
    
    func loadAssignmentsFromCalendar() async {
        // Eerst toegang tot kalender controleren
        guard await CalendarManager.shared.requestAccess() else {
            print("No calendar access")
            return
        }
        
        print("Loaded shifts: \(shifts)")
        
        // Haal alle events op uit de kalender
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        do {
            let events = try await CalendarManager.shared.fetchEvents(from: startDate, to: endDate)
            print("Fetched events: \(events.count)")
            
            var newAssignments: [ShiftAssignment] = []
            
            // Groepeer events per datum
            let groupedEvents = Dictionary(grouping: events) { event in
                Calendar.current.startOfDay(for: event.startDate)
            }
            
            // Voor elke datum, neem alleen het meest recente event
            for (date, dateEvents) in groupedEvents {
                // Filter events met geldige shift IDs
                let validEvents = dateEvents.compactMap { event -> (EKEvent, UUID)? in
                    guard let shiftId = event.notes,
                          let uuid = UUID(uuidString: shiftId),
                          shifts.contains(where: { $0.id == uuid }) else {
                        return nil
                    }
                    return (event, uuid)
                }
                
                // Sorteer op laatst gewijzigd en neem de meest recente
                if let mostRecent = validEvents.sorted(by: { $0.0.lastModifiedDate ?? Date.distantPast > $1.0.lastModifiedDate ?? Date.distantPast }).first {
                    let assignment = ShiftAssignment(
                        shiftId: mostRecent.1,
                        date: date,
                        calendarEventId: mostRecent.0.eventIdentifier
                    )
                    newAssignments.append(assignment)
                }
            }
            
            await MainActor.run {
                self.assignments = newAssignments
                self.saveAssignments()
                print("Updated assignments: \(self.assignments)")
            }
        } catch {
            print("Failed to fetch events: \(error)")
        }
    }
    
    func assignShift(_ shift: Shift, to date: Date) async {
        print("Assigning shift: \(shift) to date: \(date)")
        guard let calendarId = shift.calendarId else {
            print("No calendar ID for shift")
            return
        }
        
        // Controleer of er al een shift is op deze datum
        if let existingAssignment = assignments.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            print("Found existing assignment: \(existingAssignment)")
            // Verwijder bestaande shift uit kalender
            if let eventId = existingAssignment.calendarEventId {
                try? CalendarManager.shared.removeShiftFromCalendar(eventId: eventId)
            }
            // Verwijder bestaande assignment
            assignments.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        }
        
        // Voeg nieuwe shift toe
        let assignment = ShiftAssignment(shiftId: shift.id, date: date)
        
        do {
            if let eventId = try await CalendarManager.shared.addShiftToCalendar(
                shift: shift,
                date: date,
                calendarIdentifier: calendarId
            ) {
                print("Created calendar event with ID: \(eventId)")
                await MainActor.run {
                    var updatedAssignment = assignment
                    updatedAssignment.calendarEventId = eventId
                    self.assignments.append(updatedAssignment)
                    self.saveAssignments()
                    print("Saved assignment: \(updatedAssignment)")
                }
            }
        } catch {
            print("Failed to add shift to calendar: \(error)")
        }
    }
    
    private func loadAssignments() {
        if let data = UserDefaults.standard.data(forKey: assignmentsKey),
           let decodedAssignments = try? JSONDecoder().decode([ShiftAssignment].self, from: data) {
            assignments = decodedAssignments
        }
    }
    
    private func saveAssignments() {
        if let encoded = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(encoded, forKey: assignmentsKey)
        }
    }
    
    func getAssignment(for date: Date) -> (date: Date, shift: Shift)? {
        guard let assignment = assignments.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
              let shift = shifts.first(where: { $0.id == assignment.shiftId }) else {
            return nil
        }
        return (assignment.date, shift)
    }
    
    func getAssignmentsForDateRange(from startDate: Date, to endDate: Date) -> [(date: Date, shift: Shift)] {
        return assignments
            .filter { assignment in
                let date = assignment.date
                return date >= startDate && date <= endDate
            }
            .compactMap { assignment -> (date: Date, shift: Shift)? in
                guard let shift = shifts.first(where: { $0.id == assignment.shiftId }) else {
                    return nil
                }
                return (assignment.date, shift)
            }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: HomeViewModel())
    }
}
