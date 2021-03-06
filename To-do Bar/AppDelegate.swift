//
//  AppDelegate.swift
//  To-do Bar
//
//  Created by Zhexiong Liu on 3/1/20.
//  Copyright © 2020 Zhexiong Liu. All rights reserved.
//


import Cocoa
import SwiftUI
import EventKit
import NaturalLanguage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var statusBarItem: NSStatusItem!

    var eventStore = EKEventStore()
    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var calendarGrant = false
    var remindersGrant = false
    var reminderCount = 0

    let defaultWidth = 200
    let maxStringLength = 30

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let group = DispatchGroup()

        group.enter()
        eventStore.requestAccess(to: .event) {
            (granted, error) in
            if let error = error {
                print(error)
                return
            }
            if granted {
                self.calendarGrant = true
            }
            group.leave()
        }


        group.enter()
        eventStore.requestAccess(to: .reminder) {
            (granted, error) in
            if let error = error {
                print(error)
                return
            }
            if granted {
                self.remindersGrant = true
            }
            group.leave()
        }


        group.wait()
        print(calendarGrant, remindersGrant)


        if let button = self.statusItem.button {
            DispatchQueue.main.async {
                button.image = NSImage(named: "BarIcon")
                if self.reminderCount > 0 {
                    button.imagePosition = NSControl.ImagePosition.imageLeft
                    button.title = String(self.reminderCount)
//                    print(self.reminderCount)
                }
            }
        }

//        calendarGrant = false
//        remindersGrant = true
        if !calendarGrant && !remindersGrant {
            defaultMenu()
        }


        if calendarGrant || remindersGrant {

            let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fetchItems), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
            
        }
    }


    @ objc func defaultMenu() {

        let statusBarMenu = NSMenu(title: "TodoMenuBar")
        statusBarMenu.minimumWidth = CGFloat(defaultWidth)
        self.statusItem.menu = statusBarMenu


        statusBarMenu.addItem(NSMenuItem.separator())

        statusBarMenu.addItem(
                withTitle: "Please Grant APP Access",
                action: nil,
                keyEquivalent: "")

        statusBarMenu.addItem(
                withTitle: "to Reminders or Calendar",
                action: nil,
                keyEquivalent: "")

        statusBarMenu.addItem(
                withTitle: "Open System Preferences",
                action: #selector(AppDelegate.OpenSystemPreferencesAPP),
                keyEquivalent: ",")

        statusBarMenu.addItem(
                withTitle: "Quit",
                action: #selector(AppDelegate.QuitAPP),
                keyEquivalent: "q")
    }


    @objc func calendarMenu(statusBarMenu: NSMenu) {

//        statusBarMenu.addItem(NSMenuItem.separator())
        if calendarGrant {
            statusBarMenu.addItem(
                    withTitle: "Calendar",
                    action: #selector(AppDelegate.OpenCalendar),
                    keyEquivalent: "c")
        }
//        statusBarMenu.addItem(NSMenuItem.separator())

        var allEvents: [EKEvent] = []
        let calendars = eventStore.calendars(for: .event)
        for calendar in calendars {
            let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date.tomorrow, calendars: [calendar])
            let events = eventStore.events(matching: predicate)
            allEvents.append(contentsOf: events)
        }

        var startDateString = ""
        var endDateString = ""
        var Datestring = ""
        var EventSring = ""
        var allDayEvent: [EKEvent] = []
        for event in allEvents {
            startDateString = event.startDate.toString(dateFormat: "h:mm a")
            endDateString = event.endDate.toString(dateFormat: "h:mm a")

            if event.isAllDay {
                allDayEvent.append(event)
            }

            if Date().toLocalTime() < event.startDate.toLocalTime() {

                Datestring = startDateString + "-" + endDateString
                EventSring = event.title as String
                if EventSring.count >= self.maxStringLength {
                    EventSring = String(EventSring.prefix(self.maxStringLength)) + "..."
                }

                statusBarMenu.addItem(NSMenuItem.separator())

                statusBarMenu.addItem(
                        withTitle: Datestring,
                        action: #selector(AppDelegate.DoNothingAPP),
                        keyEquivalent: "")

                statusBarMenu.addItem(
                        withTitle: EventSring,
                        action: #selector(AppDelegate.DoNothingAPP),
                        keyEquivalent: "")

            }

            if !event.isAllDay && Date().toLocalTime() > event.startDate.toLocalTime() && Date().toLocalTime() < event.endDate.toLocalTime() {

                Datestring = "Now" + "-" + endDateString

                EventSring = event.title as String
                if EventSring.count >= self.maxStringLength {
                    EventSring = String(EventSring.prefix(self.maxStringLength)) + "..."
                }

                statusBarMenu.addItem(NSMenuItem.separator())

                statusBarMenu.addItem(
                        withTitle: Datestring,
                        action: #selector(AppDelegate.DoNothingAPP),
                        keyEquivalent: "")

                statusBarMenu.addItem(
                        withTitle: EventSring,
                        action: #selector(AppDelegate.DoNothingAPP),
                        keyEquivalent: "")
            }
        }

        for event in allDayEvent {

            Datestring = "All Day"
            EventSring = event.title as String
            if EventSring.count >= self.maxStringLength {
                EventSring = String(EventSring.prefix(self.maxStringLength)) + "..."
            }

            statusBarMenu.addItem(NSMenuItem.separator())

            statusBarMenu.addItem(
                    withTitle: Datestring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")

            statusBarMenu.addItem(
                    withTitle: EventSring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")
        }
    }


    @objc func remindersMenu(statusBarMenu: NSMenu) {


        let textView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 25))
        let textField = TextInput()
        textField.frame = NSRect(x: 10, y: 0, width: textView.frame.width - 20, height: textView.frame.height)
        textView.addSubview(textField)
//        textView.becomeFirstResponder()


        let textFieldInMenutest = NSMenuItem()
        statusBarMenu.addItem(textFieldInMenutest)
        textFieldInMenutest.view = textView

        self.reminderCount = 0

        statusBarMenu.addItem(NSMenuItem.separator())
        if remindersGrant {
            statusBarMenu.addItem(
                    withTitle: "Reminders",
                    action: #selector(AppDelegate.OpenReminders),
                    keyEquivalent: "r")
        }
        statusBarMenu.addItem(NSMenuItem.separator())

        let predicated: NSPredicate? = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        if let aPredicate = predicated {
            eventStore.fetchReminders(matching: aPredicate, completion: {
                (_ reminders: [Any]?) -> Void in
                for reminder: EKReminder? in reminders as? [EKReminder?] ?? [EKReminder?]() {

                    //                                        print(reminder?.dueDateComponents?.date)
                    //                                        print(reminder?.dueDateComponents?.date?.toLocalTime())
                    //                                        print(Date())
                    //                                        print(Date().toLocalTime())
                    //                                        print(Date.tomorrow.toLocalTime())

                    if reminder?.dueDateComponents?.date?.toLocalTime() ?? Date().toLocalTime() <= Date.tomorrow.toLocalTime() {
                        self.reminderCount = self.reminderCount + 1
                        //                        print(self.reminderCount)
                        var ReminderString = reminder!.title as String
                        if ReminderString.count >= self.maxStringLength {
                            ReminderString = String(ReminderString.prefix(self.maxStringLength)) + "..."
                        }
                        statusBarMenu.addItem(
                                withTitle: ReminderString,
                                action: #selector(AppDelegate.removeItems(sender:)),
                                keyEquivalent: "")
                    }
                }

                statusBarMenu.addItem(NSMenuItem.separator())

                self.calendarMenu(statusBarMenu: statusBarMenu)
                self.referenceMenu(statusBarMenu: statusBarMenu)

                self.updateMenuBar()
            })
        }
    }

    @objc func updateMenuBar() {
        if let button = self.statusItem.button {
            DispatchQueue.main.async {
                button.image = NSImage(named: "BarIcon")
                if self.reminderCount > 0 {
                    button.imagePosition = NSControl.ImagePosition.imageLeft
                    button.title = String(self.reminderCount)
                    //                    print(self.reminderCount)
                } else {
                    button.imagePosition = NSControl.ImagePosition.imageOnly
                }
            }
        }
    }

    @objc func referenceMenu(statusBarMenu: NSMenu) {
        
        statusBarMenu.addItem(NSMenuItem.separator())

        statusBarMenu.addItem(
                withTitle: "Reference",
                action: #selector(AppDelegate.OpenReferenceURL),
                keyEquivalent: ",")

        statusBarMenu.addItem(
                withTitle: "Quit",
                action: #selector(AppDelegate.QuitAPP),
                keyEquivalent: "q")
    }

    
    @objc func fetchItems() {


        let statusBarMenu = NSMenu(title: "TodoMenuBar ")
        statusBarMenu.minimumWidth = 200
        statusItem.menu = statusBarMenu

//        statusBarMenu.addItem(
//                withTitle: "Tasks for " + Date().toString(dateFormat: "EEE MMM d, yyyy"),
//                action: nil,
//                keyEquivalent: "")

        statusBarMenu.addItem(NSMenuItem.separator())

        remindersMenu(statusBarMenu: statusBarMenu)

    }


    @objc func removeItems(sender: Any) {
        let statusBarMenu = NSMenu(title: "TodoMenuBar")
        statusItem.menu = statusBarMenu

        let item = (sender as! NSMenuItem).title

        let predicated: NSPredicate? = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        if let aPredicate = predicated {
            eventStore.fetchReminders(matching: aPredicate, completion: {
                (_ reminders: [Any]?) -> Void in

                for reminder: EKReminder? in reminders as? [EKReminder?] ?? [EKReminder?]() {

                    if reminder?.dueDateComponents?.date?.toLocalTime() ?? Date().toLocalTime() <= Date.tomorrow.toLocalTime() {
                        let target_item = reminder?.title!
//                        print(item.prefix(self.maxStringLength), target_item?.prefix(self.maxStringLength))
                        if item.prefix(self.maxStringLength) == target_item?.prefix(self.maxStringLength) {
                            reminder?.isCompleted = true
                            do {
//                                self.reminderCount = self.reminderCount - 1
                                try self.eventStore.save(reminder!, commit: true)
                                print("completed reminder successed")
//                                self.fetchItems()
                            } catch {
                                print("error \(error)")
                            }
                        }
                    }
                }
            })
        }
    }


    @objc func QuitAPP(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }


    @objc func RefreshAPP(_ sender: Any) {
        fetchItems()
    }

    @objc func DoNothingAPP(_ sender: Any) {
    }

    @objc func OpenReminders(_ sender: Any) {
        let url = NSURL(fileURLWithPath: "/System/Applications/Reminders.app", isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }


    @objc func OpenCalendar(_ sender: Any) {
        let url = NSURL(fileURLWithPath: "/System/Applications/Calendar.app", isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }

    @objc func OpenSystemPreferencesAPP(_ sender: Any) {
        let url = NSURL(fileURLWithPath: "/System/Applications/System Preferences.app", isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }

    @objc func OpenReferenceURL() {
        let url = URL(string: "https://github.com/ZhexiongLiu/TodoBar")!
        NSWorkspace.shared.open(url)
    }

    @objc func OpenContentWindow() {

        let alert = NSAlert.init()
        alert.messageText = "To-do Bar"
        alert.informativeText = "Grant access to Reminders/Calendar in Privacy Preference if you'd like to show tasks in menu bar. @ZhexiongLiu"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }


}


class TextInput: NSTextField, NSTextFieldDelegate {

    override func viewDidChangeBackingProperties() {
        self.delegate = self
        self.placeholderString = "Enter your reminders here..."
        self.isEditable = true
        self.textColor = .black
        self.selectText(nil)
        self.isSelectable = true
        self.drawsBackground = false
        self.font = NSFont.systemFont(ofSize: 14)
        self.cell?.usesSingleLineMode = true
        self.bezelStyle = NSTextField.BezelStyle.roundedBezel
//        _ = self.becomeFirstResponder()
        self.window?.makeFirstResponder(self)
    }


    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            // hit enter key
            if let textField = control as? NSTextField {
                let data = getDateString(thisString: textField.stringValue as NSString)
                let dateString = data[0] as NSString
                let text = data[1]

                var date = Date()
                if dateString != "" {
                    let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
                    if let tcr: NSTextCheckingResult = dateDetector?.firstMatch(in: dateString as String, options: [], range: NSMakeRange(0, dateString.length)), let this_date = tcr.date {
                        date = this_date
                    }

                    let eventStore = EKEventStore()
                    let reminder = EKReminder(eventStore: eventStore)
                    let alarm = EKAlarm(absoluteDate: date)
                    
                    reminder.title = text
                    reminder.addAlarm(alarm)
                    reminder.dueDateComponents = dateComponentFromNSDate(date: date as NSDate) as DateComponents
                    reminder.calendar = eventStore.defaultCalendarForNewReminders()
                    do {
                        try eventStore.save(reminder, commit: true)
                        print("saved")
                    } catch {
                        print("error: \(error)")
                    }

                } else {
                    let eventStore = EKEventStore()
                    let reminder = EKReminder(eventStore: eventStore)
                    reminder.title = text
                    reminder.calendar = eventStore.defaultCalendarForNewReminders()
                    do {
                        try eventStore.save(reminder, commit: true)
                        print("saved")
                    } catch {
                        print("error: \(error)")
                    }
                }
                textField.stringValue = ""
            }
            return true
        }
        return false
    }

    func dateComponentFromNSDate(date: NSDate) -> NSDateComponents {
        let calendarUnit = Set<Calendar.Component>([.minute, .hour, .day, .month, .year])
        let dateComponents = Calendar.current.dateComponents(calendarUnit,
                from: date as Date)
        return dateComponents as NSDateComponents
    }


    func getDateString(thisString: NSString) -> Array<String> {

        var newString = thisString as String
        var newDateString = ""

        let types: NSTextCheckingResult.CheckingType = [.address, .date]
        let dataDetector = try? NSDataDetector(types: types.rawValue)

        dataDetector?.enumerateMatches(in: thisString as String, range: NSMakeRange(0, thisString.length), using: {
            (match, flags, _) in

            let matchString = thisString.substring(with: (match?.range)!) as NSString
            if match?.resultType == .date {
                newString = thisString.replacingOccurrences(of: matchString as String, with: "")
                newDateString = matchString as String
            }
        })

        newString = newString.replacingOccurrences(of: "  " as String, with: " ")
        newString = newString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print([newDateString, newString])
        return [newDateString, newString]
    }
}


extension Date {
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-US")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    static var yesterday: Date {
        return Date().dayBefore
    }
    static var tomorrow: Date {
        return Date().dayAfter
    }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: midnight)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: midnight)!
    }
    var midnight: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }

    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

