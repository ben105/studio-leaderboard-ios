//
//  DataSourceUpdater.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/26/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import Foundation

typealias ApiCompletion = ([[String: Any?]]?, Error?) -> Void
typealias ModelRecord = [String: Any?]

protocol DataSourceUpdaterDelegate {
  func didBeginUpdating(_ updater: DataSourceUpdater)
  func didEndUpdating(_ updater: DataSourceUpdater)
  func didFailUpdating(_ updater: DataSourceUpdater)
}

class DataSourceUpdater {

  fileprivate let apiFetcher: (Date?, @escaping ApiCompletion) -> Void
  fileprivate let model: PerfectMindModel
  fileprivate let table: PerfectMindModel.tables

  var delegate: DataSourceUpdaterDelegate?

  init(
    fetcher: @escaping (Date?, @escaping ApiCompletion)  -> (),
    model: PerfectMindModel,
    table: PerfectMindModel.tables)
  {
    self.apiFetcher = fetcher
    self.model = model
    self.table = table
  }

  fileprivate func lastUpdatedDate() -> Date? {
    var latestDate: Date?
    if let latestEpochForTable = model.latestEpoch(for: table) {
      latestDate = Date(timeIntervalSince1970: TimeInterval(latestEpochForTable))
    }
    return latestDate
  }

  func update() {
    delegate?.didBeginUpdating(self)
    apiFetcher(lastUpdatedDate()) { [unowned self] (data, error) in
      guard error == nil else {
        self.delegate?.didFailUpdating(self)
        return
      }
      guard let records = data else {
        return
      }
      let recordInserter = self.model.recordInserter(for: self.table)
      for record in records {
        recordInserter(record)
      }
      self.delegate?.didEndUpdating(self)
    }
  }

}
