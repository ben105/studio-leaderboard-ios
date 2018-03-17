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

  fileprivate let updateQueue = DispatchQueue(label: "update-queue")
  fileprivate let dispatchGroup = DispatchGroup()

  fileprivate lazy var attendanceUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.attendance,
      model: perfectMindModel,
      table: .attendance)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var clientUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.contacts,
      model: perfectMindModel,
      table: .clients)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var teachersUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.teachers,
      model: perfectMindModel,
      table: .teachers)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var eventsUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.events,
      model: perfectMindModel,
      table: .events)
    updater.delegate = self
    return updater
  }()

  fileprivate lazy var transactionsUpdater: DataSourceUpdater = {
    let updater = DataSourceUpdater(
      fetcher: perfectMindAPI.transactions,
      model: perfectMindModel,
      table: .transactions)
    updater.delegate = self
    return updater
  }()

  func update(completion: @escaping ([(name: String, count: Int64)]) -> Void) {
    updateQueue.sync {
      self.attendanceUpdater.update()
      self.clientUpdater.update()
      self.teachersUpdater.update()
      self.eventsUpdater.update()
      self.transactionsUpdater.update()
      print("Waiting on dispatch group")
      self.dispatchGroup.wait()
      print("Finished waiting on dispatch group.")
      DispatchQueue.global().async {
        self.perfectMindModel.attendanceForThisMonth(completion: completion)
      }
    }
  }

  func save() {
    perfectMindModel.writeAllEpochsToDisk()
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
