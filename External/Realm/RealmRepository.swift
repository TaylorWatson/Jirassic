//
//  CoreDataRepository.swift
//  Jirassic
//
//  Created by Cristian Baluta on 15/04/16.
//  Copyright © 2016 Cristian Baluta. All rights reserved.
//

import Foundation
import RealmSwift

class RealmRepository {
    
    fileprivate let databaseName = "Jirassic"
    var realm: Realm!
    
    init() {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(databaseName).realm")
        Realm.Configuration.defaultConfiguration = config
        realm = try! Realm()
    }
    
    convenience init (documentsDirectory: String) {
        self.init()
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(databaseName).realm")
        Realm.Configuration.defaultConfiguration = config
        realm = try! Realm()
    }
}

extension RealmRepository {
    
    fileprivate func queryWithPredicate<T:Object> (_ predicate: NSPredicate?, sortingKeyPath: String?) -> [T] {
        
        var results = [T]()
        var resultsObjs = realm.objects(T.self)
        
        if let pred = predicate {
            resultsObjs = resultsObjs.filter(pred)
        }
        if let key = sortingKeyPath {
            resultsObjs = resultsObjs.sorted(byKeyPath: key)
        }
        for result in resultsObjs {
            results.append(result)
        }
        return results
    }
}

extension RealmRepository: RepositoryUser {
    
    func currentUser() -> User {
        
//        let userPredicate = NSPredicate(format: "isLoggedIn == YES")
//        let cusers: [RUser] = queryWithPredicate(userPredicate, sortDescriptors: nil)
//        if let cuser = cusers.last {
//            return User(isLoggedIn: true, email: cuser.email, userId: cuser.userId, lastSyncDate: cuser.lastSyncDate)
//        }
        
        return User(isLoggedIn: false, email: nil, userId: nil, lastSyncDate: nil)
    }
    
    func loginWithCredentials (_ credentials: UserCredentials, completion: (NSError?) -> Void) {
        fatalError("This method is not applicable to CoreDataRepository")
    }
    
    func registerWithCredentials (_ credentials: UserCredentials, completion: (NSError?) -> Void) {
        fatalError("This method is not applicable to CoreDataRepository")
    }
    
    func logout() {
    }
}

extension RealmRepository: RepositoryTasks {

    func queryTasks (_ page: Int, completion: ([Task], NSError?) -> Void) {
        
        let results: [RTask] = queryWithPredicate(nil, sortingKeyPath: "endDate")
        let tasks = tasksFromRTasks(results)
        
        completion(tasks, nil)
    }
    
    func queryTasksInDay (_ day: Date) -> [Task] {
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "endDate >= %@ AND endDate <= %@", day.startOfDay() as CVarArg, day.endOfDay() as CVarArg)
        ])
//        let sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        let results: [RTask] = queryWithPredicate(compoundPredicate, sortingKeyPath: "endDate")
        let tasks = tasksFromRTasks(results)
        
        return tasks
    }
    
    func queryUnsyncedTasks() -> [Task] {
        
        let predicate = NSPredicate(format: "lastModifiedDate == nil")
        let results: [RTask] = queryWithPredicate(predicate, sortingKeyPath: nil)
        let tasks = tasksFromRTasks(results)
        
        return tasks
    }
    
    func deleteTask (_ task: Task, completion: ((_ success: Bool) -> Void)) {
        
        realm.beginWrite()
        let rtask = rtaskFromTask(task)
        realm.delete(rtask)
        try! realm.commitWrite()
        completion(true)
    }
    
    func saveTask (_ task: Task, completion: (_ success: Bool) -> Void) -> Task {
        
        realm.beginWrite()
        let rtask = rtaskFromTask(task)
        try! realm.commitWrite()
        
        return taskFromRTask(rtask)
    }
    
    fileprivate func taskFromRTask (_ rtask: RTask) -> Task {
        
        return Task(startDate: rtask.startDate,
                    endDate: rtask.endDate!,
                    notes: rtask.notes,
                    taskNumber: rtask.taskNumber,
                    taskType: TaskType(rawValue: rtask.taskType)!,
                    objectId: rtask.objectId!
        )
    }
    
    fileprivate func tasksFromRTasks (_ rtasks: [RTask]) -> [Task] {
        
        var tasks = [Task]()
        for rtask in rtasks {
            tasks.append(self.taskFromRTask(rtask))
        }
        
        return tasks
    }
    
    fileprivate func rtaskFromTask (_ task: Task) -> RTask {
        
        let taskPredicate = NSPredicate(format: "objectId == %@", task.objectId)
        let tasks: [RTask] = queryWithPredicate(taskPredicate, sortingKeyPath: nil)
        var rtask: RTask? = tasks.first
        if rtask == nil {
//            rtask = RTask()
            rtask = realm.create(RTask.self)
        }
        if rtask?.objectId == nil {
            rtask?.objectId = task.objectId
        }
        
        return updatedRTask(rtask!, withTask: task)
    }
    
    // Update only updatable properties. objectId can't be updated
    fileprivate func updatedRTask (_ rtask: RTask, withTask task: Task) -> RTask {
        
        rtask.taskNumber = task.taskNumber
        rtask.taskType = task.taskType.rawValue
        rtask.notes = task.notes
        rtask.startDate = task.startDate
        rtask.endDate = task.endDate
        
        return rtask
    }
}

extension RealmRepository: RepositorySettings {
    
    func settings() -> Settings {
        
        let results: [RSettings] = queryWithPredicate(nil, sortingKeyPath: nil)
        var rsettings: RSettings? = results.first
        if rsettings == nil {
            
            realm.beginWrite()
            
            rsettings = RSettings()
            rsettings?.startOfDayEnabled = true
            rsettings?.lunchEnabled = true
            rsettings?.scrumEnabled = true
            rsettings?.meetingEnabled = true
            rsettings?.autoTrackEnabled = true
            rsettings?.trackingMode = 1
            rsettings?.startOfDayTime = Date(hour: 9, minute: 0)
            rsettings?.endOfDayTime = Date(hour: 17, minute: 0)
            rsettings?.lunchTime = Date(hour: 13, minute: 0)
            rsettings?.scrumTime = Date(hour: 10, minute: 30)
            rsettings?.minSleepDuration = Date(hour: 0, minute: 13)
            
            try! realm.commitWrite()
        }
        return settingsFromRSettings(rsettings!)
    }
    
    func saveSettings (_ settings: Settings) {
        
        realm.beginWrite()
        let _ = rsettingsFromSettings(settings)
        try! realm.commitWrite()
    }
    
    fileprivate func settingsFromRSettings (_ rsettings: RSettings) -> Settings {
        
        return Settings(startOfDayEnabled: rsettings.startOfDayEnabled,
                        lunchEnabled: rsettings.lunchEnabled,
                        scrumEnabled: rsettings.scrumEnabled,
                        meetingEnabled: rsettings.meetingEnabled,
                        autoTrackEnabled: rsettings.autoTrackEnabled,
                        trackingMode: TaskTrackingMode(rawValue: rsettings.trackingMode)!,
                        startOfDayTime: rsettings.startOfDayTime!,
                        endOfDayTime: rsettings.endOfDayTime!,
                        lunchTime: rsettings.lunchTime!,
                        scrumTime: rsettings.scrumTime!,
                        minSleepDuration: rsettings.minSleepDuration!
        )
    }
    
    fileprivate func rsettingsFromSettings (_ settings: Settings) -> RSettings {
        
        let results: [RSettings] = queryWithPredicate(nil, sortingKeyPath: nil)
        var rsettings: RSettings? = results.first
        if rsettings == nil {
            rsettings = RSettings()
        }
        rsettings?.startOfDayEnabled = settings.startOfDayEnabled
        rsettings?.lunchEnabled = settings.lunchEnabled
        rsettings?.scrumEnabled = settings.scrumEnabled
        rsettings?.meetingEnabled = settings.meetingEnabled
        rsettings?.autoTrackEnabled = settings.autoTrackEnabled
        rsettings?.trackingMode = settings.trackingMode.rawValue
        rsettings?.startOfDayTime = settings.startOfDayTime
        rsettings?.endOfDayTime = settings.endOfDayTime
        rsettings?.lunchTime = settings.lunchTime
        rsettings?.scrumTime = settings.scrumTime
        rsettings?.minSleepDuration = settings.minSleepDuration
        
        return rsettings!
    }
}
