import Foundation

struct Shift: Identifiable, Codable {
    let id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var color: String
    var calendarId: String?
    var isAllDay: Bool
    
    init(id: UUID = UUID(), name: String = "", startTime: Date = Date(), endTime: Date = Date(), color: String = "#FF0000", calendarId: String? = nil, isAllDay: Bool = false) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
        self.calendarId = calendarId
        self.isAllDay = isAllDay
    }
}

struct ShiftAssignment: Identifiable, Codable {
    var id: UUID
    var shiftId: UUID
    var date: Date
    var calendarEventId: String?
    
    init(id: UUID = UUID(), shiftId: UUID, date: Date, calendarEventId: String? = nil) {
        self.id = id
        self.shiftId = shiftId
        self.date = date
        self.calendarEventId = calendarEventId
    }
}
