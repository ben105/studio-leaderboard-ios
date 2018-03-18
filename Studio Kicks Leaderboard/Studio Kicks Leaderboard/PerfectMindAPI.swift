//
//  PerfectMindAPI.swift
//  Studio Kicks Leaderboard
//
//  Created by Ben Rooke on 2/23/18.
//  Copyright © 2018 Ben Rooke. All rights reserved.
//
import Foundation

enum serverError: Error {
  case JSONConversion
  case ServerError
  case BadStatusCode
  case BadDataType
  case BadURL
}

fileprivate struct Headers {
  fileprivate static let accessKey: String = ""
  fileprivate static let clientNumber: String = ""
  fileprivate static let username: String = ""
  fileprivate static let password: String = ""
}

class PerfectMindAPI {

  fileprivate static let orgID: String = ""
  fileprivate static let username: String = ""
  fileprivate static let password: String = ""

  fileprivate static let urlString: String = "studiokickslosgatos.perfectmind.com"
  fileprivate static let queryAPI: String = "/api/2.0/B2C/Query"
  fileprivate static let uriLogin: String = "/api/2.0/B2C/Login"
  fileprivate static let statusAPI: String = "/api/2.0/Status"

  /// Keeps the login process from only happening once at a time.
  fileprivate var loginLock: NSLock = NSLock()

  /// The auth token is aquired after login.
  fileprivate var authToken: String?

  fileprivate let session = URLSession(configuration: URLSessionConfiguration.default)

  fileprivate func lastUpdated(forQuery queryKey: String) -> Date? {
    return UserDefaults.standard.value(forKey: queryKey) as? Date
  }

  init() {
    self.login()
  }

  fileprivate func newURL(for api: String, tail: String = "") -> URL {
    let absoluteUrlString = "https://\(PerfectMindAPI.urlString)\(api)\(tail)"
    guard let url = URL(string: absoluteUrlString) else {
      fatalError("failed to instantiate URL for string \(absoluteUrlString)")
    }
    return url
  }

  fileprivate func newRequest(with url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.setValue(Headers.accessKey, forHTTPHeaderField: "X-Access-Key")
    request.setValue(Headers.clientNumber, forHTTPHeaderField: "X-Client-Number")
    request.setValue(Headers.username, forHTTPHeaderField: "X-Username")
    request.setValue(Headers.password, forHTTPHeaderField: "X-Password")
    request.setValue("Accept-Encoding", forHTTPHeaderField: "identity")
    request.setValue("Connection", forHTTPHeaderField: "close")
    if let token = authToken {
      request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
    }
    return request
  }

  func logout() {
    authToken = nil
  }

  fileprivate func login(completion: (() -> Void)? = nil) {
    // Lock before checking for an auth token, so that when it's our turn we can bail early if the
    // process just completed a moment before.
    debugPrint("Obtaining a login lock.")
    loginLock.lock()
    guard authToken == nil else {
      debugPrint("Auth token has already been populated; bailing.")
      loginLock.unlock()
      completion?()
      return
    }
    let getParams = "orgId=\(PerfectMindAPI.orgID)&" +
      "username=\(PerfectMindAPI.username)&" +
    "password=\(PerfectMindAPI.password)"
    guard let tail = getParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      fatalError("cannot percent escape get parameters \(getParams)")
    }
    let url = newURL(for: PerfectMindAPI.uriLogin, tail: "?" + tail)
    let request = URLRequest(url: url)
    sendRequest(request) { (json, error) in
      if let error = error {
        fatalError("error in response: \(error)")
      }
      guard let data = json as? [String: Any] else {
        fatalError("json invalid format: \(json)")
      }
      guard let token = data["UserID"] as? String else {
        fatalError("json invalid format: \(json)")
      }
      self.authToken = token
      debugPrint("Successfully logged in to PerfectMind.")
      debugPrint("Auth token: " + token)
      completion?()
      self.loginLock.unlock()
    }
  }

  func attendance(after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    return query("Attendance", after: date, completion: completion)
  }

  func contacts(after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    return query("Contact", after: date, completion: completion)
  }

  func events(after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    return query("Event", after: date, completion: completion)
  }

  func teachers(after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    return query("Teachers", after: date, completion: completion)
  }

  func transactions(after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    return query("Transaction", after: date, completion: completion)
  }

  fileprivate func query(_ table: String, after date: Date?, completion: @escaping ([[String: Any?]]?, Error?) -> Void) {
    if authToken == nil {
      debugPrint("Trying to login before running query.")
      login() {
        debugPrint("Implicit login attempt completed; rerunning query.")
        self.query(table, after: date, completion: completion)
      }
      return
    }
    // In the query string, I escape the table name with double quotes, because this is going to run
    // on a SQL server where double quotes can be used to delimit table and columns. The Transaction
    // table is a particularly nasty culprit, because it needs to be escaped. Ultimately, it is just
    // safer to escape the table names.
    var queryString = "SELECT * FROM Custom.\"\(table)\""
    if let timestamp = Util.timestamp(from: date) {
      queryString += " WHERE Custom.\"\(table)\".CreatedDate > convert(datetime, \'\(timestamp)\')"
    }
    let url = newURL(for: PerfectMindAPI.queryAPI)
    var request = newRequest(with: url)
    request.httpMethod = "POST"
    request.httpBody = ("QueryString=" + queryString).data(using: .utf8)
    sendRequest(request) { (json, error) in
      guard error == nil else {
        completion(nil, error)
        return
      }
      guard let formattedJson = json as? [[String: Any?]] else {
        completion(nil, serverError.BadDataType)
        return
      }
      completion(formattedJson, nil)
    }
  }

  func getStatus() {
    if authToken == nil {
      debugPrint("Trying to login before retrieving the PerfectMind status.")
      login() {
        debugPrint("Implicit login attempt completed; rerunning getSatus request.")
        self.getStatus()
      }
      return
    }
    let url = newURL(for: PerfectMindAPI.statusAPI)
    let request = newRequest(with: url)
    sendRequest(request) { (json, error) in
      debugPrint(json)
    }
  }

  fileprivate func sendRequest(
    _ request: URLRequest,
    serverData: @escaping (AnyObject?, Error?) -> Void)
  {
    debugPrint("sendRequest to URL: \(request.url!)")
    let task = session.dataTask(with: request) { (data, response, error) in
      if let httpResponse = response as? HTTPURLResponse {
        debugPrint("HTTP response code \(httpResponse.statusCode)")
      }
      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        serverData(nil, serverError.BadStatusCode)
        return
      }
      guard error == nil else {
        // Trickle the error down.
        serverData(nil, serverError.ServerError)
        return
      }
      guard let responseData = data else {
        // This is okay, we just don't return any data.
        serverData(nil, nil)
        return
      }

      // Parse the result as JSON, since that's what the API provides.
      var responseJSON: AnyObject? = nil
      do {
        if let json = try JSONSerialization.jsonObject(
          with: responseData,
          options: []) as? [[String: AnyObject]]
        {
          responseJSON = json as AnyObject
        } else if let json = try JSONSerialization.jsonObject(
          with: responseData,
          options: []) as? [String: AnyObject]
        {
          responseJSON = json as AnyObject
        } else {
          // The resulting serialization was not a list of string: anyobject
          serverData(nil, serverError.BadDataType)
        }
      } catch {
        // Error tryin to convert data to JSON.
        serverData(nil, serverError.JSONConversion)
      }
      serverData(responseJSON, nil)
    }
    task.resume()
  }

}
