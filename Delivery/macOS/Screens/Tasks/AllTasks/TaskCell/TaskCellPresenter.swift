//
//  TaskCellPresenter.swift
//  Jirassic
//
//  Created by Baluta Cristian on 27/11/15.
//  Copyright © 2015 Cristian Baluta. All rights reserved.
//

import Cocoa

class TaskCellPresenter: NSObject {

	var cell: CellProtocol!
	
	convenience init (cell: CellProtocol) {
		self.init()
		self.cell = cell
	}
	
	func present (previousTask: Task?, currentTask theTask: Task) {
		
        cell.statusImage?.image = nil
        
        switch theTask.taskType {
        case .issue:
            cell.statusImage?.image = NSImage(named: NSImage.statusAvailableName)
            
        case .gitCommit:
            cell.statusImage?.image = NSImage(named: "GitIcon")
            
        case .coderev:
            cell.color = NSColor.systemGray
            
        case .startDay, .endDay:
            cell.color = NSColor.systemBlue
            
        case .calendar:
            cell.color = NSColor.systemGray
            cell.statusImage?.image = NSImage(named: "CalendarIcon")
            
        default:
            cell.color = NSColor.systemGray
        }

        var notes = theTask.notes ?? ""
        if notes == "" {
            notes = theTask.taskType.defaultNotes
        }
        // The codereview notes is a list of tasks that were reviewed
        if theTask.taskType == .coderev && theTask.notes != nil && theTask.notes != "" {
            notes = "\(theTask.taskType.defaultNotes): \(notes)"
        }
		cell.data = (
            dateStart: theTask.startDate,
            dateEnd: theTask.endDate,
			taskNumber: theTask.taskNumber,
            notes: notes,
			taskType: theTask.taskType
		)
        cell.isDark = AppDelegate.sharedApp().theme.isDark
        cell.isEditable = theTask.objectId != nil
        cell.isRemovable = theTask.objectId != nil
        cell.isIgnored = theTask.taskType == .lunch || theTask.taskType == .waste
        cell.timeToolTip = theTask.objectId != nil ? "Click to edit" : "Item can be edited after the day is closed"
	}
}
