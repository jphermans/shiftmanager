import EventKit
import Foundation

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("Failed to request calendar access: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        print("Failed to request calendar access: \(error)")
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [EKEvent] {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    func addShiftToCalendar(shift: Shift, date: Date, calendarIdentifier: String) async throws -> String? {
        guard let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw CalendarError.calendarNotFound
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = shift.name
        
        if shift.isAllDay {
            event.isAllDay = true
            event.startDate = Calendar.current.startOfDay(for: date)
            event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: event.startDate)!
        } else {
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.hour, .minute], from: shift.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: shift.endTime)
            
            event.startDate = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                         minute: startComponents.minute ?? 0,
                                         second: 0,
                                         of: date) ?? date
            
            event.endDate = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                       minute: endComponents.minute ?? 0,
                                       second: 0,
                                       of: date) ?? date
        }
        
        // Store the shift ID in the notes field for later reference
        event.notes = shift.id.uuidString
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Failed to save event: \(error)")
            throw CalendarError.failedToSaveEvent
        }
    }
    
    func availableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }
    
    func removeShiftFromCalendar(eventId: String) throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarError.deleteFailed(error)
        }
    }
    
    func verifyCalendarEvents(assignments: [ShiftAssignment]) async -> [ShiftAssignment] {
        var validAssignments: [ShiftAssignment] = []
        
        for assignment in assignments {
            if let eventId = assignment.calendarEventId,
               eventStore.event(withIdentifier: eventId) != nil {
                validAssignments.append(assignment)
            }
        }
        
        return validAssignments
    }
}

extension CalendarManager {
    func defaultCalendarIdentifier() -> String? {
        return eventStore.defaultCalendarForNewEvents?.calendarIdentifier
    }
}

enum CalendarError: Error {
    case calendarNotFound
    case eventNotFound
    case failedToSaveEvent
    case deleteFailed(Error)
}
