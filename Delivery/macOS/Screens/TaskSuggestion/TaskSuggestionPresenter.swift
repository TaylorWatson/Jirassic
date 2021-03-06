//
//  TaskSuggestionPresenter.swift
//  Jirassic
//
//  Created by Cristian Baluta on 30/11/2016.
//  Copyright © 2016 Imagin soft. All rights reserved.
//

import Foundation

protocol TaskSuggestionPresenterInput: class {
    func setup (startSleepDate: Date?, endSleepDate: Date?)
    func selectSegment (atIndex index: Int)
    func save (selectedSegment: Int, notes: String, startSleepDate: Date?, endSleepDate: Date?)
}

protocol TaskSuggestionPresenterOutput: class {
    func selectSegment (atIndex index: Int)
    func setTime (_ notes: String)
    func setNotes (_ notes: String)
    func hideTaskTypes()
}

class TaskSuggestionPresenter {
    
    weak var userInterface: TaskSuggestionPresenterOutput?
    private var isStartOfDay = false
    private let startWorkText = "Good morning, ready to start working?"
    private let moduleCalendar = ModuleCalendar()
    
    private func taskType (forIndex index: Int) -> TaskType {
        
        switch index {
        case 0: return .scrum
        case 1: return .meeting
        case 2: return .lunch
        case 3: return .waste
        case 4: return .learning
        default: return .issue
        }
    }
    
    private func selectedSegment (forTaskType taskType: TaskType) -> Int {
        
        switch taskType {
            case .scrum: return 0
            case .meeting: return 1
            case .lunch: return 2
            case .waste: return 3
            case .learning: return 4
            default: return -1
        }
    }
}

extension TaskSuggestionPresenter: TaskSuggestionPresenterInput {
    
    func setup (startSleepDate: Date?, endSleepDate: Date?) {
        
        var time = ""
        if let startDate = startSleepDate {
            time += "Away between \(startDate.HHmm()) - "
        }
        time += endSleepDate!.HHmm()
        userInterface!.setTime(time)
        
        if let startDate = startSleepDate {
            let settings: Settings = SettingsInteractor().getAppSettings()
            let interactor = ComputerWakeUpInteractor(repository: localRepository, remoteRepository: remoteRepository, settings: settings)
            if let type = interactor.estimationForDate(startDate, currentDate: endSleepDate ?? Date()) {
                if type == .startDay {
                    isStartOfDay = true
                    userInterface!.setNotes(startWorkText)
                    userInterface!.hideTaskTypes()
                } else {
                    let index = selectedSegment(forTaskType: type)
                    selectSegment(atIndex: index)
                    // If selected segment is meeting, try to see if the meeting is a calendar event and populate with that data
                    if type == .meeting {
                        moduleCalendar.events(dateStart: startDate, dateEnd: startDate.endOfDay()) { (tasks) in
                            for task in tasks {
                                if task.startDate!.isAlmostSameHourAs(startDate) &&
                                    task.endDate.isAlmostSameHourAs(endSleepDate!, devianceSeconds: 30.0.minToSec) {
                                    
                                    self.userInterface!.setNotes(task.notes ?? "")
                                    break
                                }
                            }
                        }
                    }
                }
            }
        } else {
            isStartOfDay = true
            userInterface!.setNotes(startWorkText)
            userInterface!.hideTaskTypes()
        }
    }
    
    func selectSegment (atIndex index: Int) {
        
        let type = taskType(forIndex: index)
        userInterface!.setNotes(type.defaultNotes)
        userInterface!.selectSegment(atIndex: index)
    }
    
    func save (selectedSegment: Int, notes: String, startSleepDate: Date?, endSleepDate: Date?) {
        
        var task: Task
        
        if isStartOfDay {
            task = Task(endDate: endSleepDate!, type: .startDay)
        } else {
            let type = taskType(forIndex: selectedSegment)
            task = Task(endDate: endSleepDate!, type: type)
            task.notes = notes
            task.startDate = startSleepDate
        }
        
        let saveInteractor = TaskInteractor(repository: localRepository, remoteRepository: remoteRepository)
        saveInteractor.saveTask(task, allowSyncing: true, completion: { savedTask in
            
        })
        if task.taskType == .startDay {
            ModuleHookup().insert(task: task)
        }
    }
}
