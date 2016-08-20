
import hexdreamsCocoa
import libpq

open class PostgreSQLConnection : DatabaseConnection {

    let connectionDictionary :[String:String]

    init(connectionDictionary: [String:String]) {
        self.connectionDictionary = connectionDictionary
    }

    // Google: swift const char * const *

    // const char * const *
    // http://stackoverflow.com/questions/36783767/array-of-swift-strings-into-const-char-const
    // https://www.reddit.com/r/swift/comments/3g8y77/cchar_versus_unsafepointercchar_for_a/
    open func connect() throws {
        var names = [String]()
        var values = [String]()
        for (name,value) in connectionDictionary {
            names.append(name)
            values.append(value)
        }
        let conn = PQconnectStartParams(try names.cStringArray().pointer, try values.cStringArray().pointer, 0)
        if conn == nil || PQstatus(conn) == CONNECTION_BAD {
            throw Errors.databaseConnectionError
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: PQsocket(conn), queue: DispatchQueue.global(qos: .background))
        source.setEventHandler {
            //source.data
        }

        log.debug("Connecting...")
        while true {
            let status = PQstatus(conn)
            switch status {
            case CONNECTION_OK:
                log.debug("CONNECTION_OK")
                break
            case CONNECTION_BAD:
                log.debug("CONNECTION_BAD: \(self.getErrorMessage(conn))")
                break
            /* Non-blocking mode only below here */

            /*
             * The existence of these should never be relied upon - they should only
             * be used for user feedback or similar purposes.
             */
            case CONNECTION_STARTED:			// Waiting for connection to be made.
                log.debug("CONNECTION_STARTED")
                break
            case CONNECTION_MADE:			    //  Connection OK; waiting to send.
                log.debug("CONNECTION_MADE")
                break
            case CONNECTION_AWAITING_RESPONSE:  // Waiting for a response from the postmaster.
                log.debug("CONNECTION_AWAITING_RESPONSE")
                break
            case CONNECTION_AUTH_OK:		    // Received authentication; waiting for backend startup.
                log.debug("CONNECTION_AUTH_OK")
                break
            case CONNECTION_SETENV:			    // Negotiating environment.
                log.debug("CONNECTION_SETENV")
                break
            case CONNECTION_SSL_STARTUP:		// Negotiating SSL.
                log.debug("CONNECTION_SSL_STARTUP")
                break
            case CONNECTION_NEEDED:			    // Internal state: connect() needed
                log.debug("CONNECTION_NEEDED")
                break
            default:
                log.debug("default")
                break
            }
            sleep(1)
        }

        /*
         
         PGconn *PQconnectStartParams(const char * const *keywords,
         const char * const *values,
         int expand_dbname);
         

        let array: Array<Float> = [10.0, 50.0, 40.0]

        // I am not sure if alloc(array.count) or alloc(array.count * sizeof(Float))
        var cArray: UnsafePointer<Float> = UnsafePointer<Float>.alloc(array.count)
        cArray.initializeFrom(array)
        
        cArray.dealloc(array.count)
        */

    }

    override func verifyConnection() throws {
        try self.connect()
    }

    override func execute(sql :String, bindings :[String:SQLConvertible]?) throws {
        try self.verifyConnection()
    }

    func getErrorMessage(_ connection :OpaquePointer?) -> String {
        guard let connection = connection else {
            return "Connection is null"
        }
        guard let message = PQerrorMessage(connection) else {
            return "No Message"
        }
        guard let messageString =  String(validatingUTF8: message) else {
            return "Could not convert from UTF-8"
        }
        return messageString
    }

}
