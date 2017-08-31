
import XCGLogger

public enum Errors : Error {
    case databaseError(String)
    case databaseConnectionError(String)
}

let log = XCGLogger.default
