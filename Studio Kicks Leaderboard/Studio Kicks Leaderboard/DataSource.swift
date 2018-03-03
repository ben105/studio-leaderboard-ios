//
//  DataSource.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/23/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import Foundation

class DataSource {

  fileprivate let perfectMindAPI: PerfectMindAPI = PerfectMindAPI()
  fileprivate let perfectMindModel: PerfectMindModel = PerfectMindModel()

  fileprivate var updateQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "UpdateQueue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  fileprivate var dispatchGroup = DispatchGroup()

  fileprivate lazy var attendanceUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.attendance,
      recordInserter: perfectMindModel.insertAttendance)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var clientUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.contacts,
      recordInserter: perfectMindModel.insertClient)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var teachersUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.teachers,
      recordInserter: perfectMindModel.insertTeacher)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var eventsUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.events,
      recordInserter: perfectMindModel.insertEvent)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var transactionsUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.transactions,
      recordInserter: perfectMindModel.insertTransaction)
    updater.delegate = self
    return updater
  }()

  func update() {
    guard updateQueue.operationCount < 10 else {
      // There's already too many update operations queued up. Bail.
      return
    }
    updateQueue.addOperation {
      self.attendanceUpdater.update()
      self.clientUpdater.update()
      self.teachersUpdater.update()
      self.eventsUpdater.update()
      self.transactionsUpdater.update()
      self.dispatchGroup.wait()
      self.perfectMindModel.attendance(after: 1519862400) { (results) in
        print(results)
      }
    }
  }

}

extension DataSource: DataSourceUpdaterDelegate {

  func didBeginUpdating(_ updater: DataSourceUpdater) {
    dispatchGroup.enter()
    if updater === attendanceUpdater { debugPrint("Updating attendance...") }
    if updater === clientUpdater { debugPrint("Updating clients...") }
    if updater === teachersUpdater { debugPrint("Updating teachers...") }
    if updater === eventsUpdater { debugPrint("Updating events...") }
    if updater === transactionsUpdater { debugPrint("Transactions events...") }
  }

  func didEndUpdating(_ updater: DataSourceUpdater) {
    dispatchGroup.leave()
    if updater === attendanceUpdater { debugPrint("Attendance updated!") }
    if updater === clientUpdater { debugPrint("Clients updated!") }
    if updater === teachersUpdater { debugPrint("Teachers updated!") }
    if updater === eventsUpdater { debugPrint("Events updated!") }
    if updater === transactionsUpdater { debugPrint("Transactions updated!") }
  }

  func didFailUpdating(_ updater: DataSourceUpdater) {
    dispatchGroup.leave()
    if updater === attendanceUpdater { debugPrint("Attendance failed.") }
    if updater === clientUpdater { debugPrint("Clients failed.") }
    if updater === teachersUpdater { debugPrint("Teachers failed.") }
    if updater === eventsUpdater { debugPrint("Events failed.") }
    if updater === transactionsUpdater { debugPrint("Transactions failed.") }
    // In order to be more extra safe, and avoid a circumstance where we are failing because of
    // stale authentication tokens or something similarly transient, we logout to nil out the
    // authKey.
    perfectMindAPI.logout()
  }

}
