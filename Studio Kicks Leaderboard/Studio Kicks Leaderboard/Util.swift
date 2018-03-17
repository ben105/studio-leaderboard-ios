//
//  Util.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/24/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//

import Foundation

class Util {

  static func phoneNumber(for numberString: String?) -> Int64 {
    guard let number = numberString else {
      return 0
    }
    let numberNoDashes = number.replacingOccurrences(of: "-", with: "")
    let numberNoDashesNoSpaces = numberNoDashes.replacingOccurrences(of: " ", with: "")
    guard let numberInt = Int64(numberNoDashesNoSpaces) else {
      return 0
    }
    return numberInt
  }

  static func databaseEpoch(from string: String?) -> Int64? {
    guard let dateString = string?.components(separatedBy: ".")[0] else {
      return nil
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let date = formatter.date(from: dateString)
    guard let timeInterval = date?.timeIntervalSince1970 else {
      return nil
    }
    return Int64(timeInterval)
  }

  static func timestamp(from date: Date?) -> String? {
    guard let date = date else {
      return nil
    }
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter.string(from: date)
  }

}
