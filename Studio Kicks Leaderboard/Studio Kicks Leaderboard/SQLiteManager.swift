//
//  SQLiteManager.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/23/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import Foundation
import SQLite3

class SQLiteManager {

  fileprivate var db: OpaquePointer?

  fileprivate var dbQueue: DispatchQueue = DispatchQueue(label: "db_queue", attributes: .concurrent)

  fileprivate let dbPath: String

  init(path: String) {
    debugPrint("Initializing database at \(path)")
    self.dbPath = path
    self.openDatabase()
  }

  deinit {
    guard sqlite3_close(db) == SQLITE_OK else {
      fatalError("error closing database")
    }
    db = nil
  }

  fileprivate func openDatabase() {
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
      debugPrint("Successfully opened connection to database at \(dbPath)")
    } else {
      fatalError("Unable to open database. Verify that you created the directory described in " +
        "the Getting Started section.")
    }
  }

  fileprivate func bind(_ value: Any?, at index: Int32, to statement: inout OpaquePointer) {
    // Check if the value is null, and bind the null value.
    guard value != nil else {
      if sqlite3_bind_null(statement, index) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        debugPrint("Failure binding text value: \(errmsg)")
      }
      return
    }

    // Attempt to bind to a text value.
    if let textValue = value as? NSString {
      if sqlite3_bind_text(statement, index, textValue.utf8String, -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        debugPrint("Failure binding text value: \(errmsg)")
      }
      return
    }
    // Attempt to bind to a real value.
    if let realValue = value as? Double {
      if sqlite3_bind_double(statement, index, realValue) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        debugPrint("failure binding real value: \(errmsg)")
      }
      return
    }
    // Attempt to bind to an integer value.
    if let intValue = value as? Int64 {
      if sqlite3_bind_int64(statement, index, intValue) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        debugPrint("Failure binding integer value: \(errmsg)")
      }
      return
    }
    debugPrint("Could not find any viable binding value.")
  }

  func format(_ query: String, _ args: Any?...) -> OpaquePointer? {
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(self.db, query, -1, &stmt, nil) == SQLITE_OK else {
      let errmsg = String(cString: sqlite3_errmsg(self.db)!)
      debugPrint("error preparing query: \(errmsg)")
      return nil
    }

    for (index, arg) in args.enumerated() {
      self.bind(arg, at: Int32(index + 1), to: &stmt!)
    }
    return stmt
  }

  func execute(statement: OpaquePointer) {
    guard sqlite3_step(statement) == SQLITE_DONE else {
      let errmsg = String(cString: sqlite3_errmsg(self.db)!)
      debugPrint("failure executing query: \(errmsg)")
      return
    }
    sqlite3_finalize(statement)
  }

  func execute(_ nonBindingQuery: String) {
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(self.db, nonBindingQuery, -1, &stmt, nil) == SQLITE_OK else {
      let errmsg = String(cString: sqlite3_errmsg(self.db)!)
      debugPrint("error preparing query: \(errmsg)")
      return
    }
    self.execute(statement: stmt!)
  }

  func retrieveRows(
    from statement: OpaquePointer,
    columnTypes: [Any.Type]) -> [[Any?]]
  {
    var rowData: [[Any?]] = []
    // Iterate through all rows.
    while sqlite3_step(statement) == SQLITE_ROW {
      var columnData: [Any?] = []
      // Grab columns, based on the column types array.
      for (index, columnType) in columnTypes.enumerated() {
        switch columnType {
        case is String.Type:
          columnData.append(columnString(statement, index: index) as Any)
        case is Int64.Type:
          columnData.append(columnInt64(statement, index: index) as Any)
        default:
          continue
        }
      }
      rowData.append(columnData)
    }
    sqlite3_finalize(statement)
    return rowData
  }

  fileprivate func columnString(_ statement: OpaquePointer, index: Int) -> String? {
    if let cString = sqlite3_column_text(statement, Int32(index)) {
      return String(cString: cString)
    }
    return nil
  }

  fileprivate func columnInt64(_ statement: OpaquePointer, index: Int) -> Int64 {
    return sqlite3_column_int64(statement, Int32(index))
  }

}
