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

  fileprivate let apiFetcher: (@escaping ApiCompletion) -> Void
  fileprivate let recordInserter: (ModelRecord) -> Void

  var delegate: DataSourceUpdaterDelegate?

  init(
    fetcher: @escaping (@escaping ApiCompletion)  -> (),
    recordInserter: @escaping (ModelRecord) -> ())
  {
    self.apiFetcher = fetcher
    self.recordInserter = recordInserter
  }

  func update() {
    delegate?.didBeginUpdating(self)
    apiFetcher() { [unowned self] (data, error) in
      guard error == nil else {
        self.delegate?.didFailUpdating(self)
        return
      }
      guard let records = data else {
        return
      }
      for record in records {
        self.recordInserter(record)
      }
      self.delegate?.didEndUpdating(self)
    }
  }

}
