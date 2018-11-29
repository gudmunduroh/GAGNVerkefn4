import Dispatch
import MySQL

struct Student: Codable, QueryParameter {
    
    let id: Int
    var name: String{
        didSet {
            changeValue<String>(column: .name, value: name)
        }
    }
    var credits: Int{
        didSet {
            changeValue<Int>(column: .credits, value: credits)
        }
    }
    var trackID: Int{
        didSet {
            changeValue<Int>(column: .trackID, value: trackID)
        }
    }

    static func create(id: Int, name: String, credits: Int, trackID: Int) -> Future<Student>
    {
        let studentPromise = Promise<Student>()
        ProgressTracker.defaultDB.connectionPool.whenReady { pool in
            do {
                let student: Student = try pool.execute { conn in
                    try conn.query("call CreateStudent(?, ?, ?, ?)", [id, name, credits, trackID])
                    }[0]
                studentPromise.succeed(result: student)
            } catch {
                studentPromise.fail(error: ProgressTrackerError.failedToLoadFromDB)
            }
        }
        return studentPromise.futureResult
    }

    static func find(id: Int) -> Future<Student>
    {
        let studentPromise = Promise<Student>()
        ProgressTracker.defaultDB.connectionPool.whenReady { pool in 
            do {
                let student: Student = try pool.execute { conn in
                    try conn.query("SELECT * FROM students where studentid = ?", [id]) 
                }[0]
                studentPromise.succeed(result: student)
            } catch {
                studentPromise.fail(error: ProgressTrackerError.failedToLoadFromDB)
            }
        }
        return studentPromise.futureResult
    }

    func delete() -> Future<Bool>
    {
        let changeResult = Promise<Bool>()
        ProgressTracker.defaultDB.connectionPool.whenReady { pool in
            do {
                try pool.execute { conn in
                    try conn.query("call DeleteStudent(?)", [self.id])
                }
                changeResult.succeed(result: true)
            } catch {
                changeResult.fail(result: ProgressTrackerError.failedToLoadFromDB)
            }
        }
        return changeResult.futureResult
    }
    
    private func changeValue<T>(column: CodingKeys, value: T) -> Future<Bool>
    {
        let changeResult = Promise<Bool>()
        ProgressTracker.defaultDB.connectionPool.whenReady { pool in
            do {
                 try pool.execute { conn in
                    try conn.query("call UpdateStudent(?, ?, ?, ?)", [column.rawValue, value])
                    changeResult.succeed(result: true)
                }
            } catch {
                changeResult.fail(error: ProgressTrackerError.failedToLoadFromDB)
            }
        }
        return changeResult.futureValue
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "studentID"
        case name = "studentName"
        case credits
        case trackID
    }
}
