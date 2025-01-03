import SwiftUI
import EventKit

struct CalendarSyncView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCalendarId: String?
    @State private var isSyncing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                calendarSection
                shiftsSection
                loadingSection
            }
            .navigationTitle("Kalender Synchronisatie")
            .navigationBarItems(
                leading: cancelButton,
                trailing: syncButton
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Fout"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var calendarSection: some View {
        Section(header: Text("Selecteer Kalender")) {
            let calendars = CalendarManager.shared.availableCalendars()
            ForEach(calendars, id: \.calendarIdentifier) { calendar in
                CalendarRow(
                    calendar: calendar,
                    isSelected: calendar.calendarIdentifier == selectedCalendarId,
                    action: { selectedCalendarId = calendar.calendarIdentifier }
                )
            }
        }
    }
    
    private var shiftsSection: some View {
        Section(header: Text("Diensten")) {
            ForEach(viewModel.shifts) { shift in
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
                    
                    Text("\(countShifts(for: shift)) keer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var loadingSection: some View {
        Group {
            if isSyncing {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Annuleren") {
            dismiss()
        }
    }
    
    private var syncButton: some View {
        Button("Synchroniseren") {
            syncCalendar()
        }
        .disabled(selectedCalendarId == nil || isSyncing)
    }
    
    private func syncCalendar() {
        guard let calendarId = selectedCalendarId else { return }
        
        isSyncing = true
        
        Task {
            await viewModel.loadAssignmentsFromCalendar()
            
            await MainActor.run {
                isSyncing = false
                dismiss()
            }
        }
    }
    
    private func countShifts(for shift: Shift) -> Int {
        viewModel.assignments.filter { $0.shiftId == shift.id }.count
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CalendarRow: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: calendar.cgColor))
                .frame(width: 20, height: 20)
            
            Text(calendar.title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
