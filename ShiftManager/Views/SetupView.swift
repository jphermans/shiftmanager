import SwiftUI
import EventKit

struct SetupView: View {
    @StateObject private var viewModel = SetupViewModel()
    @State private var showingShiftEditor = false
    @State private var selectedShift: Shift?
    @State private var notificationsEnabled = false
    @State private var notificationTime: TimeInterval = 3600 // 1 hour
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.shiftConfiguration.localized())) {
                    ForEach(viewModel.shifts) { shift in
                        ShiftRow(shift: shift)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("Selected shift for editing: \(shift)")
                                selectedShift = shift
                                showingShiftEditor = true
                            }
                    }
                    
                    Button(action: {
                        print("Creating new shift")
                        selectedShift = nil
                        showingShiftEditor = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                            Text(LocalizedString.add.localized())
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text(LocalizedString.notifications.localized())) {
                    Toggle(LocalizedString.enableNotifications.localized(), isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Picker(LocalizedString.notificationTime.localized(), selection: $notificationTime) {
                            Text("30 minutes").tag(TimeInterval(1800))
                            Text("1 hour").tag(TimeInterval(3600))
                            Text("2 hours").tag(TimeInterval(7200))
                            Text("4 hours").tag(TimeInterval(14400))
                        }
                    }
                }
            }
            .navigationTitle(LocalizedString.setup.localized())
            .sheet(isPresented: $showingShiftEditor) {
                ShiftEditorView(
                    shift: selectedShift,
                    onSave: { shift in
                        print("Saving shift: \(shift)")
                        if selectedShift != nil {
                            viewModel.updateShift(shift)
                        } else {
                            viewModel.addShift(shift)
                        }
                        showingShiftEditor = false
                    },
                    onDelete: {
                        if let shift = selectedShift {
                            print("Deleting shift: \(shift)")
                            viewModel.deleteShift(shift)
                            showingShiftEditor = false
                        }
                    }
                )
            }
        }
    }
}

struct ShiftRow: View {
    let shift: Shift
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: shift.color))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading) {
                Text(shift.name)
                    .font(.headline)
                
                if shift.isAllDay {
                    Text("Hele dag")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(shift.startTime, formatter: timeFormatter) - \(shift.endTime, formatter: timeFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
}

struct ShiftEditorView: View {
    let shift: Shift?
    let onSave: (Shift) -> Void
    let onDelete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedColor = "#FF0000"
    @State private var selectedCalendarId: String?
    @State private var isAllDay = false
    @State private var showingDeleteAlert = false
    
    private let availableColors = [
        "#4285F4", "#34A853", "#FBBC05", "#EA4335",
        "#9C27B0", "#FF9800", "#795548", "#607D8B"
    ]
    
    init(shift: Shift? = nil, onSave: @escaping (Shift) -> Void, onDelete: @escaping () -> Void) {
        print("ShiftEditorView init with shift: \(String(describing: shift))")
        self.shift = shift
        self.onSave = onSave
        self.onDelete = onDelete
        
        _name = State(initialValue: shift?.name ?? "")
        _startTime = State(initialValue: shift?.startTime ?? Date())
        _endTime = State(initialValue: shift?.endTime ?? Date())
        _selectedColor = State(initialValue: shift?.color ?? "#4285F4")
        _selectedCalendarId = State(initialValue: shift?.calendarId)
        _isAllDay = State(initialValue: shift?.isAllDay ?? false)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("SHIFT DETAILS")) {
                    TextField("Naam", text: $name)
                    Toggle("Hele dag", isOn: $isAllDay)
                    if !isAllDay {
                        DatePicker("Start tijd", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Eind tijd", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("KLEUR")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay(Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0))
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if shift != nil {
                    Section {
                        Button(action: {
                            print("Delete button tapped")
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Verwijder Shift")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(shift == nil ? "Nieuwe Shift" : "Bewerk Shift")
            .navigationBarItems(
                leading: Button("Annuleren") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Opslaan") {
                    let newShift = Shift(
                        id: shift?.id ?? UUID(),
                        name: name,
                        startTime: startTime,
                        endTime: endTime,
                        color: selectedColor,
                        calendarId: selectedCalendarId ?? CalendarManager.shared.defaultCalendarIdentifier(),
                        isAllDay: isAllDay
                    )
                    onSave(newShift)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
            )
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Verwijder Shift"),
                    message: Text("Weet je zeker dat je deze shift wilt verwijderen?"),
                    primaryButton: .destructive(Text("Verwijder")) {
                        onDelete()
                    },
                    secondaryButton: .cancel(Text("Annuleren"))
                )
            }
        }
    }
}

class SetupViewModel: ObservableObject {
    @Published private(set) var shifts: [Shift] = []
    private let shiftStore = ShiftStore.shared
    
    init() {
        // Subscribe to changes in ShiftStore
        shifts = shiftStore.shifts
    }
    
    func addShift(_ shift: Shift) {
        print("SetupViewModel: Adding shift")
        shiftStore.addShift(shift)
        shifts = shiftStore.shifts
    }
    
    func updateShift(_ shift: Shift) {
        print("SetupViewModel: Updating shift")
        shiftStore.updateShift(shift)
        shifts = shiftStore.shifts
    }
    
    func deleteShift(_ shift: Shift) {
        print("SetupViewModel: Deleting shift")
        shiftStore.deleteShift(shift)
        shifts = shiftStore.shifts
    }
}
