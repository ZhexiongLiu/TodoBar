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
                if self.reminderCount > 0{
                    button.imagePosition = NSControl.ImagePosition.imageLeft
                    button.title = String(self.reminderCount)
                    //                    print(self.reminderCount)
                }
            }
        }
        
        
        
        if !calendarGrant && !remindersGrant{
            defaultMenu()
        }
        
        
        if calendarGrant || remindersGrant{
            
            let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fetchItems), userInfo: nil, repeats: true)
            
            RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        }
        
    }
    
    @ objc func defaultMenu(){
        let statusBarMenu = NSMenu(title: "TodoMenuBar")
        statusBarMenu.minimumWidth = CGFloat(defaultWidth)
        self.statusItem.menu = statusBarMenu
        
        statusBarMenu.addItem(
            withTitle: "Please Grant APP Access",
            action: nil,
            keyEquivalent: "")
        
        statusBarMenu.addItem(
            withTitle: "to Reminders or Calendar",
            action: nil,
            keyEquivalent: "")
        
        
        
        //        statusBarMenu.addItem(
        //            withTitle: "Todo List on " + Date().toString(dateFormat: "EEE MMM d"),
        //            action: #selector(AppDelegate.RefreshAPP),
        //            keyEquivalent: "")
        //
        //        statusBarMenu.addItem(
        //            withTitle: "Calendar",
        //            action: #selector(AppDelegate.OpenCalendar),
        //            keyEquivalent: "c")
        //
        //        statusBarMenu.addItem(
        //            withTitle: "Reminders",
        //            action: #selector(AppDelegate.OpenReminders),
        //            keyEquivalent: "r")
        
        statusBarMenu.addItem(
            withTitle: "Open System Preferences",
            action: #selector(AppDelegate.OpenSystemPreferencesAPP),
            keyEquivalent: ",")
        
        statusBarMenu.addItem(
            withTitle: "Quit",
            action: #selector(AppDelegate.QuitAPP),
            keyEquivalent: "q")
    }
    
    
    @objc func calendarMenu(statusBarMenu: NSMenu){
        
        statusBarMenu.addItem(NSMenuItem.separator())
        if calendarGrant{
            statusBarMenu.addItem(
                withTitle: "Calendar",
                action: #selector(AppDelegate.OpenCalendar),
                keyEquivalent: "c")
        }
        statusBarMenu.addItem(NSMenuItem.separator())
        
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
            
            if event.isAllDay{
                allDayEvent.append(event)
            }
            
            if Date().toLocalTime() < event.startDate.toLocalTime(){
                
                Datestring = startDateString + "-" + endDateString
                EventSring = event.title as String
                if EventSring.count >= 25 {
                    EventSring = String(EventSring.prefix(25)) + "..."
                }
                
                statusBarMenu.addItem(NSMenuItem.separator())
                
                statusBarMenu.addItem(
                    withTitle:  Datestring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")
                
                statusBarMenu.addItem(
                    withTitle:  EventSring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")
                
            }
            
            if !event.isAllDay && Date().toLocalTime() > event.startDate.toLocalTime() && Date().toLocalTime() < event.endDate.toLocalTime(){
                
                Datestring = "Now" + "-" + endDateString
                
                EventSring = event.title as String
                if EventSring.count >= 25 {
                    EventSring = String(EventSring.prefix(25)) + "..."
                }
                
                statusBarMenu.addItem(NSMenuItem.separator())
                
                statusBarMenu.addItem(
                    withTitle:  Datestring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")
                
                statusBarMenu.addItem(
                    withTitle:  EventSring,
                    action: #selector(AppDelegate.DoNothingAPP),
                    keyEquivalent: "")
            }
            
        }
        
        for event in allDayEvent{
            
            Datestring = "All Day"
            EventSring = event.title as String
            if EventSring.count >= 25 {
                EventSring = String(EventSring.prefix(25)) + "..."
            }
            
            statusBarMenu.addItem(NSMenuItem.separator())
            
            statusBarMenu.addItem(
                withTitle:  Datestring,
                action: #selector(AppDelegate.DoNothingAPP),
                keyEquivalent: "")
            
            statusBarMenu.addItem(
                withTitle:  EventSring,
                action: #selector(AppDelegate.DoNothingAPP),
                keyEquivalent: "")
            
        }
    }
    
    
    @objc func remindersMenu(statusBarMenu: NSMenu) {
        
        statusBarMenu.addItem(NSMenuItem.separator())
        if remindersGrant{
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
                        if ReminderString.count >= 20{
                            ReminderString = String(ReminderString.prefix(20)) + "..."
                        }
                        statusBarMenu.addItem(
                            withTitle: ReminderString,
                            action: #selector(AppDelegate.removeItems(sender:)),
                            keyEquivalent: "")                            }
                }
                
                statusBarMenu.addItem(NSMenuItem.separator())
                
                self.calendarMenu(statusBarMenu: statusBarMenu)
                self.referenceMenu(statusBarMenu: statusBarMenu)
                
                self.updateMenuBar()
            })
        }
    }
    
    @objc func updateMenuBar(){
        if let button = self.statusItem.button {
            DispatchQueue.main.async {
                button.image = NSImage(named: "BarIcon")
                if self.reminderCount > 0{
                    button.imagePosition = NSControl.ImagePosition.imageLeft
                    button.title = String(self.reminderCount)
                    //                    print(self.reminderCount)
                }
                else{
                    button.imagePosition = NSControl.ImagePosition.imageOnly
                }
                
            }
        }
    }
    
    @objc func referenceMenu(statusBarMenu: NSMenu){
        
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
    
    @objc func fetchItems(){
        
        self.reminderCount = 0
        
        let statusBarMenu = NSMenu(title: "TodoMenuBar ")
        statusBarMenu.minimumWidth = 200
        statusItem.menu = statusBarMenu
        
        statusBarMenu.addItem(
            withTitle: "Tasks for " + Date().toString(dateFormat: "EEE MMM d, yyyy"),
            action: nil,
            keyEquivalent: "")
        
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
                        if item == target_item{
                            reminder?.isCompleted = true
                            do {
                                try self.eventStore.save(reminder!, commit: true)
                                print("completed reminder successed")
                                self.fetchItems()
                            }catch{
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
    
    @objc func OpenReferenceURL(){
        let url = URL(string: "https://github.com/ZhexiongLiu/TodoBar")!
        NSWorkspace.shared.open(url)
    }
    
    @objc func OpenContentWindow(){
        
        let alert = NSAlert.init()
        alert.messageText = "To-do Bar"
        alert.informativeText = "Grant access to Reminders/Calendar in Privacy Preference if you'd like to show tasks in menu bar. @ZhexiongLiu"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }
    
    
}



extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-US")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
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
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
}

