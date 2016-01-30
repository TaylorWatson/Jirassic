//
//  DataManagerProtocol.swift
//  Jirassic
//
//  Created by Baluta Cristian on 01/05/15.
//  Copyright (c) 2015 Cristian Baluta. All rights reserved.
//

import Foundation

protocol DataManagerProtocol {
	
	func queryTasks (completion: ([Task], NSError?) -> Void)
	func allCachedTasks() -> [Task]
    func deleteTask (dataToDelete: Task)
	func updateTask (theTask: Task, completion: ((success: Bool) -> Void))
}
