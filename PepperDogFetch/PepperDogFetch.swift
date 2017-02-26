
import XCGLogger

public enum Errors : Error {
    case databaseConnectionError(String)
}

let log = XCGLogger.default
