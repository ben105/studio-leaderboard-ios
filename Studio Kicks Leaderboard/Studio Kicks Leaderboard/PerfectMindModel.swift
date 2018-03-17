import Foundation

enum memberShip: Int64 {
  typealias RawValue = Int64
  case unknown = 0
  case active
  case cancelled
  case expired
  case freeze

  static func status(for value: memberShip) -> String? {
    switch value.rawValue {
    case 1: return "Active"
    case 2: return "Cancelled"
    case 3: return "Expired"
    case 4: return "Freeze"
    default: return nil
    }
  }

  static func value(for status: String?) -> memberShip? {
    guard let status = status else {
      return nil
    }
    let lowercase = status.lowercased()
    switch lowercase {
    case "active": return .active
    case "cancelled": return .cancelled
    case "expired": return .expired
    case "freeze": return .freeze
    default: return nil
    }
  }
}

enum gender: Int64 {
  typealias RawValue = Int64
  case unknown = 0
  case male = 1
  case female = 2

  static func string(for value: gender) -> String? {
    switch value.rawValue {
    case 1: return "Male"
    case 2: return "Female"
    default: return nil
    }
  }

  static func value(for genderString: String?) -> gender? {
    guard let genderString = genderString else {
      return nil
    }
    let lowercase = genderString.lowercased()
    switch lowercase {
    case "male": return .male
    case "female": return .female
    default: return nil
    }
  }
}

class PerfectMindModel {

  enum tables: String {
    case attendance
    case events
    case teachers
    case clients
    case transactions
  }

  fileprivate static let dbPathURL: URL = try! FileManager.default.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false).appendingPathComponent("studio.sqlite")

  fileprivate static var dbPath: String {
    return dbPathURL.absoluteString
  }

  fileprivate let db: SQLiteManager

  // Store the latest epoch by the table name.
  fileprivate var cachedEpochs: [tables: Int64] = [:]

  typealias RecordInserter = ([String: Any?]) -> Void

  init() {
    self.db = SQLiteManager(path: PerfectMindModel.dbPath)
    self.createAll()
    self.insertAll()
    self.readFromDisk(epochForTable: .attendance)
    self.readFromDisk(epochForTable: .events)
    self.readFromDisk(epochForTable: .teachers)
    self.readFromDisk(epochForTable: .clients)
    self.readFromDisk(epochForTable: .transactions)
  }

  deinit {
    writeEpochToDisk(for: .attendance)
    writeEpochToDisk(for: .events)
    writeEpochToDisk(for: .teachers)
    writeEpochToDisk(for: .clients)
    writeEpochToDisk(for: .transactions)
  }

  func recordInserter(for table: tables) -> RecordInserter {
    switch table {
    case .attendance: return insertAttendance
    case .events: return insertEvent
    case .teachers: return insertTeacher
    case .clients: return insertClient
    case .transactions: return insertTransaction
    }
  }

}

// MARK: - Create

extension PerfectMindModel {

  fileprivate func createAll() {
    createClientsTable()
    createGendersTable()
    createMembershipStatusTable()
    createTransactionsTable()
    createAttendanceTable()
    createEventsTable()
    createTeachersTable()
  }

  fileprivate func createClientsTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS clients (
          ID TEXT,
          FullName TEXT,
          Gender INTEGER,
          Email TEXT,
          Birthdate INTEGER,
          Membership TEXT,
          PerfectScanID TEXT,
          CreatedDate INTEGER,
          StartDate INTEGER,
          EnrollmentDate INTEGER,
          LastAttended INTEGER,
          Photo TEXT,
          PrimaryNumber INTEGER);
      """)
    }
  }

  fileprivate func createGendersTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS genders (
          id INTEGER,
          gender TEXT);
      """)
    }
  }

  fileprivate func createMembershipStatusTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS membership_status (
          id INTEGER,
          status TEXT);
      """)
    }
  }

  fileprivate func createTransactionsTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS transactions (
          CreatedDate INTEGER,
          DurationDays INTEGER,
          EachPayment REAL,
          Expiry INTEGER,
          FinalPayment INTEGER,
          FirstPayment INTEGER,
          ForfeitedAmount REAL,
          ID TEXT,
          MembershipName TEXT,
          MembershipStatus INTEGER,
          MembershipTotal REAL,
          ModifiedDate INTEGER,
          NumberofPayments REAL,
          Ongoing BOOL,
          SessionsLeft INTEGER,
          SessionsPurchased INTEGER,
          TotalAmount REAL);
      """)
    }
  }

  fileprivate func createAttendanceTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS attendance (
          Attendee TEXT,
          Event TEXT,
          ModifiedDate INTEGER,
          Renewed BOOL,
          Status TEXT,
          TimeAttended INTEGER,
          Transactions TEXT);
      """)
    }
  }

  fileprivate func createEventsTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS events (
          CreatedDate INTEGER,
          ModifiedDate INTEGER,
          Details TEXT,
          EndTime INTEGER,
          ID TEXT,
          Price  REAL,
          StartTime INTEGER,
          Subject  TEXT,
          Teacher  TEXT);
      """)
    }
  }

  fileprivate func createTeachersTable() {
    DispatchQueue.main.async {
      self.db.execute("""
        CREATE TABLE IF NOT EXISTS teachers (
          CreatedDate  INTEGER,
          Email TEXT,
          FullName TEXT,
          ID TEXT,
          JobTitle TEXT,
          MobilePhone INTEGER,
          ModifiedDate INTEGER,
          Position TEXT);
      """)
    }
  }

}

// MARK: - Insert

extension PerfectMindModel {

  fileprivate func insertAll() {
    insertGenders()
    insertMembershipStatus()
  }

  fileprivate func insertGenders() {
    DispatchQueue.main.async {
      self.db.execute("INSERT INTO genders VALUES (1, 'Male');")
      self.db.execute("INSERT INTO genders VALUES (2, 'Female');")
    }
  }

  fileprivate func insertMembershipStatus() {
    insertMembershipStatus(with: memberShip.active)
    insertMembershipStatus(with: memberShip.cancelled)
    insertMembershipStatus(with: memberShip.expired)
    insertMembershipStatus(with: memberShip.freeze)
  }

  fileprivate func insertMembershipStatus(with status: memberShip) {
    DispatchQueue.main.async {
      let statusString = memberShip.status(for: status)!
      self.db.execute("""
        INSERT INTO membership_status
        VALUES (
        \(status.rawValue),
        '\(statusString)'
        );
        """)
    }
  }

  func insertAttendance(_ record: [String: Any?]) {
    guard let attendee = record["Attendee"] as? String,
      let modifiedDate = Util.databaseEpoch(from: record["ModifiedDate"] as? String),
      let renewed = record["Renewed"] as? Int64,
      let status = record["Status"] as? String else
    {
      debugPrint("Failed inserting a attendance.")
      return
    }
    let event = record["Event"] as? String
    let timeAttended = Util.databaseEpoch(from: record["TimeAttended"] as? String)
    DispatchQueue.main.async {
      let stmt = self.db.format("""
        INSERT INTO attendance (
          Attendee,
          Event,
          ModifiedDate,
          Renewed,
          Status,
          TimeAttended
        ) VALUES (?, ?, ?, ?, ?, ?);
        """,
        attendee,
        event,
        modifiedDate,
        renewed,
        status,
        timeAttended)
      self.db.execute(statement: stmt!)
    }
    cache(latestEpoch: modifiedDate, for: .attendance)
  }

  func insertEvent(_ record: [String: Any?]) {
    guard let createdDate = Util.databaseEpoch(from: record["CreatedDate"] as? String),
      let modifiedDate = Util.databaseEpoch(from: record["ModifiedDate"] as? String),
      let endTime = Util.databaseEpoch(from: record["EndTime"] as? String),
      let _id = record["Id"] as? String,
      let startTime = Util.databaseEpoch(from: record["StartTime"] as? String),
      let subject = record["Subject"] as? String else
    {
      debugPrint("Failed inserting an event")
      return
    }
    let details = record["Details"] as? String
    let price = record["Price"] as? Double
    let teacher = record["Teacher"] as? String
    DispatchQueue.main.async {
      let stmt = self.db.format("""
        INSERT INTO events (
          CreatedDate,
          ModifiedDate,
          Details,
          EndTime,
          ID,
          Price,
          StartTime,
          Subject,
          Teacher
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """,
         createdDate,
         modifiedDate,
         details,
         endTime,
         _id,
         price,
         startTime,
         subject,
         teacher)
      self.db.execute(statement: stmt!)
    }
    cache(latestEpoch: modifiedDate, for: .events)
  }

  func insertTeacher(_ record: [String: Any?]) {
    guard let createdDate = Util.databaseEpoch(from: record["CreatedDate"] as? String),
      let fullName = record["FullName"] as? String,
      let _id = record["ID"] as? String,
      let modifiedDate = Util.databaseEpoch(from: record["ModifiedDate"] as? String) else
    {
      debugPrint("Failed inserting a teacher.")
      return
    }
    let number = Util.phoneNumber(for: record["MobilePhone"] as? String)
    let email = record["Email"] as? String
    let position = record["Position"] as? String
    let jobTitle = record["JobTitle"] as? String
    DispatchQueue.main.async {
      let stmt = self.db.format("""
        INSERT INTO teachers (
          CreatedDate,
          Email,
          FullName,
          ID,
          JobTitle,
          MobilePhone,
          ModifiedDate,
          Position
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """,
        createdDate,
        email,
        fullName,
        _id,
        jobTitle,
        modifiedDate,
        position,
        number)
      self.db.execute(statement: stmt!)
    }
    cache(latestEpoch: modifiedDate, for: .teachers)
  }

  func insertClient(_ record: [String: Any?]) {
    guard let _id = record["ID"] as? String,
      let fullName = record["FullNameSimple"] as? String,
      let scanID = record["PerfectScanID"] as? String,
      let createdDate = Util.databaseEpoch(from: record["CreatedDate"] as? String) else
    {
      debugPrint("Failed inserting a client.")
      return
    }
    let genderString = gender.value(for: record["Gender"] as? String)
    let birthdate = Util.databaseEpoch(from: record["Birthdate"] as? String)
    let lastAttended = Util.databaseEpoch(from: record["LastAttended"] as? String)
    let primaryNumber = record["PrimaryNumber"] as? String
    let photo = record["Photo"] as? String
    let email = record["Email"] as? String
    let membership = record["Membership"] as? String
    let startDate = Util.databaseEpoch(from: record["StartDate"] as? String)
    let enrollmentDate = Util.databaseEpoch(from: record["EnrollmentDate"] as? String)
    DispatchQueue.main.async {
      let stmt = self.db.format("""
        INSERT INTO clients (
          ID,
          FullName,
          Gender,
          Email,
          Birthdate,
          Membership,
          PerfectScanID,
          CreatedDate,
          StartDate,
          EnrollmentDate,
          LastAttended,
          Photo,
          PrimaryNumber
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      """,
      _id,
      fullName,
      genderString?.rawValue,
      email,
      birthdate,
      membership,
      scanID,
      createdDate,
      startDate,
      enrollmentDate,
      lastAttended,
      photo,
      primaryNumber)
      self.db.execute(statement: stmt!)
    }
    cache(latestEpoch: createdDate, for: .clients)
  }

  func insertTransaction(_ record: [String: Any?]) {
    guard let createdDate = Util.databaseEpoch(from: record["CreatedDate"] as? String),
      let _id = record["ID"] as? String,
      let modifiedDate = Util.databaseEpoch(from: record["ModifiedDate"] as? String),
      let ongoing = record["Ongoing"] as? Int64 else
    {
      debugPrint("Failed inserting a transaction.")
      return
    }
    let durationDays = record["DurationDays"] as? Int64
    let eachPayment = record["EachPayment"] as? Double
    let expiry = Util.databaseEpoch(from: record["Expiry"] as? String)
    let finalPayment = Util.databaseEpoch(from: record["FinalPayment"] as? String)
    let firstPayment = Util.databaseEpoch(from: record["FirstPayment"] as? String)
    let forfeitedAmount = record["ForfeitedAmount"] as? Double
    let sessionsLeft = record["SessionsLeft"] as? Int64
    let sessionsPurchased = record["SessionsPurchased"] as? Int64
    let numberOfPayments = record["NumberofPayments"] as? Double
    let membershipTotal = record["MembershipTotal"] as? Double
    let totalAmount = record["TotalAmount"] as? Double
    let membershipName = record["MembershipName"] as? String
    let membershipStatus = memberShip.value(for: record["MembershipStatus"] as? String)
    DispatchQueue.main.async {
      let stmt = self.db.format("""
        INSERT INTO transactions (
          CreatedDate,
          DurationDays,
          EachPayment,
          Expiry,
          FinalPayment,
          FirstPayment,
          ForfeitedAmount,
          ID,
          MembershipName,
          MembershipStatus,
          MembershipTotal,
          ModifiedDate,
          NumberofPayments,
          Ongoing,
          SessionsLeft,
          SessionsPurchased,
          TotalAmount
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """,
        createdDate,
        durationDays,
        eachPayment,
        expiry,
        finalPayment,
        firstPayment,
        forfeitedAmount,
        _id,
        membershipName,
        membershipStatus?.rawValue,
        membershipTotal,
        modifiedDate,
        numberOfPayments,
        ongoing,
        sessionsLeft,
        sessionsPurchased,
        totalAmount)
      self.db.execute(statement: stmt!)
    }
    cache(latestEpoch: modifiedDate, for: .transactions)
  }

}

// MARK: - Read

extension PerfectMindModel {

  func attendanceForThisMonth(
    completion: @escaping ([(name: String, count: Int64)]) -> Void)
  {
    // We get today's year and month components.
    let todaysComponents = Calendar.current.dateComponents([.year, .month], from: Date())
    // Instantiating a new date from these components will default the day to 1.
    let startOfMonth = Calendar.current.date(from: todaysComponents)
    attendance(after: startOfMonth?.timeIntervalSince1970 ?? 0, completion: completion)
  }

  func attendance(
    after epoch: TimeInterval,
    completion: @escaping ([(name: String, count: Int64)]) -> Void)
  {
    let query = """
      SELECT c.FullName, count(*) as ClassCount
      FROM clients c, attendance a, events e
      WHERE a.Attendee = c.ID and a.Event = e.ID and a.TimeAttended > ?
      GROUP BY c.ID
      ORDER BY ClassCount desc;
    """
    DispatchQueue.main.sync {
      guard let stmt = self.db.format(query, epoch) else {
        debugPrint("Failed to retrieve attendance after the date \(epoch).")
        return
      }
      let results = self.db.retrieveRows(from: stmt, columnTypes: [String.self, Int64.self])
      let formattedResults = results.map {
        return (name: $0[0] as! String, count: $0[1] as! Int64)
      }

      DispatchQueue.global().async {
        completion(formattedResults)
      }
    }
  }

}

// MARK: - Latest Dates

extension PerfectMindModel {

  fileprivate func cache(latestEpoch: Int64, for table: tables) {
    guard let currentEpoch = cachedEpochs[table] else {
      cachedEpochs[table] = latestEpoch
      return
    }
    // Only update the epoch if the latest epoch is actually post-current.
    guard currentEpoch < latestEpoch else {
      return
    }
    cachedEpochs[table] = latestEpoch
  }

  /// Publicly exposed getter for the cached last-updated epochs.
  func latestEpoch(for table: tables) -> Int64? {
    debugPrint("Latest epoch for table \(table.rawValue) being fetched.")
    return cachedEpochs[table]
  }

  fileprivate func writeEpochToDisk(for table: tables) {
    guard let epoch = cachedEpochs[table] else {
      return
    }
    debugPrint("Writing epoch(\(epoch)) to disk.")
    let date = Date(timeIntervalSince1970: TimeInterval(epoch))
    UserDefaults.standard.set(date, forKey: table.rawValue)
  }

  func writeAllEpochsToDisk() {
    writeEpochToDisk(for: .attendance)
    writeEpochToDisk(for: .events)
    writeEpochToDisk(for: .teachers)
    writeEpochToDisk(for: .clients)
    writeEpochToDisk(for: .transactions)
  }

  fileprivate func readFromDisk(epochForTable table: tables) {
    guard let date = UserDefaults.standard.value(forKey: table.rawValue) as? Date else {
      return
    }
    debugPrint("Reading a date in from disk, for table \(table.rawValue)")
    cachedEpochs[table] = Int64(date.timeIntervalSince1970)
  }

}
