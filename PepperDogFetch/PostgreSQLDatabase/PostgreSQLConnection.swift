
import hexdreamsCocoa
import libpq

public class PostgreSQLConnection : DatabaseConnection {
    
    let connectionDictionary :[ConnectionDictionaryKey:String]
    var connection :OpaquePointer?
    let listenChannel = "foo"
    
    init(connectionDictionary: [ConnectionDictionaryKey:String]) {
        self.connectionDictionary = connectionDictionary
    }
    
    // Google: swift const char * const *
    // const char * const *
    // http://stackoverflow.com/questions/36783767/array-of-swift-strings-into-const-char-const
    // https://www.reddit.com/r/swift/comments/3g8y77/cchar_versus_unsafepointercchar_for_a/
    
    // Google: postgresql asynchronous connection example
    // https://gist.github.com/revmischa/5384678
    func connect() throws {
        if self.connection != nil {
            return
        }
        
        var names = [String]()
        var values = [String]()
        for (key,value) in connectionDictionary {
            names.append(key.name)
            values.append(value)
        }
        guard let conn = PQconnectStartParams(
            try names.cStringArray().pointer,
            try values.cStringArray().pointer,
            0) else {
            throw Errors.databaseConnectionError("Could not create connection")
        }
        defer {
            if PQstatus(conn) != CONNECTION_OK {
                PQfinish(conn)
            }
        }
        log.debug("Connecting...")
        try mainLoop(conn)
        self.connection = conn
        
        self.readDatabaseInfo()
        
        log.debug("... connected successfully");
    }
    
    private func mainLoop(_ conn :OpaquePointer) throws {
        var connected = false
        
        while !connected {
            let sock = PQsocket(conn)
            if ( sock < 0 ) {
                throw Errors.databaseConnectionError("Postgres socket is gone")
            }
            
            var rfds = fd_set()
            C.FD_ZERO(&rfds)
            var wfds = fd_set()
            C.FD_ZERO(&wfds)
            var tv = timeval()
            tv.tv_sec = 1
            tv.tv_usec = 0
            
            let connStatus = PQconnectPoll(conn);
            switch connStatus {
            case PGRES_POLLING_FAILED:
                log.debug("PGRES_POLLING_FAILED")
                throw Errors.databaseConnectionError("Pg connection failed: \(PQerrorMessage(conn))")
            case PGRES_POLLING_WRITING:
                log.debug("PGRES_POLLING_WRITING")
                C.FD_SET(sock, &wfds)
                break
            case PGRES_POLLING_READING:
                log.debug("PGRES_POLLING_READING")
                C.FD_SET(sock, &rfds)
                break
            case PGRES_POLLING_OK:
                log.debug("PGRES_POLLING_OK")
                connected = true
                return
            case PGRES_POLLING_ACTIVE:  // deprecated
                log.debug("PGRES_POLLING_ACTIVE - deprecated")
                break
            default:
                throw Errors.databaseConnectionError("connection status not supported: \(connStatus)")
            }
            
            let selectStatus = select(sock + Int32(1), &rfds, &wfds, nil, &tv);
            switch selectStatus {
            case -1:
                log.error("select() failed")
                throw Errors.databaseConnectionError("select() failed")
            case 0:
                log.error("socket timed out")
                throw Errors.databaseConnectionError("socket timed out")
            default:
                break
            }
        }
    }
    
    private func handlePgRead(_ conn :OpaquePointer) throws {
        var notifyPtr :UnsafeMutablePointer<PGnotify>
        var opt :PQprintOpt = PQprintOpt()
        
        // read data waiting in buffer
        if ( PQconsumeInput(conn) == 0 ) {
            throw Errors.databaseConnectionError("Failed to consume pg input: \(PQerrorMessage(conn))")
        }
        
        while true {
            guard let result = PQgetResult(conn) else {
                log.debug("Query Error: \(self.getErrorMessage(conn))")
                break
            }

            if ( PQresultStatus(result) != PGRES_COMMAND_OK ) {
                PQclear(result);
                throw Errors.databaseConnectionError("Result error: \(PQerrorMessage(conn))");
            }
            // memset(&opt, 0, sizeof(opt)); not necessary on initialization:
            // http://stackoverflow.com/questions/30971278/do-i-need-to-memset-a-c-struct-in-swift
            opt.header = 1
            opt.align = 1
            PQprint(stdout, result, &opt);
            log.debug("Got result");
        }
        
        // check for asynchronous notifications
        while true {
            guard let notificationPtr = PQnotifies(conn) else {
                break;
            }
            defer {
                PQfreemem(notificationPtr)
            }
            notificationPtr.withMemoryRebound(to:PGnotify.self, capacity:1) { ptr in
                let notify = ptr.pointee;
                log.debug("NOTIFY of '\(notify.relname)' received from backend PID \(notify.be_pid)");
            }
        }
    }
    
    
    private func initListen(_ conn :OpaquePointer) throws {
        guard let quotedChannel = PQescapeIdentifier(conn, listenChannel, Int(strlen(listenChannel))),
              let quotedChannelString = String(validatingUTF8:quotedChannel) else {
                throw Errors.databaseConnectionError("Could not create quoted channel")
        }
        defer {
            PQfreemem(quotedChannel);
        }
        let query = "LISTEN " + quotedChannelString
        let qs = PQsendQuery(conn, query)
        if qs == 0 {
            throw Errors.databaseConnectionError("Failed to send query \(PQerrorMessage(conn))")
        }
    }

    override func verifyConnection() throws {
        try self.connect()
    }
    
    override func execute(sql :String, bindings :[String:SQLConvertible]?) throws {
        try self.execute(sql:sql, bindings:bindings, readRow:{return Row()})
    }

    // https://www.postgresql.org/docs/9.1/static/libpq-exec.html
    // https://www.postgresql.org/docs/9.1/static/libpq-async.html
    // https://www.postgresql.org/message-id/20160331195656.17bc0e3b@slate.meme.com
    func execute(sql :String, bindings :[String:SQLConvertible]?,
                          readRow :() -> AnyObject) throws {
        try self.verifyConnection()
        let start = Date.timeIntervalSinceReferenceDate
        
        let sent = PQsendQueryParams(self.connection, sql.cString(using:.utf8), 0, nil, nil, nil, nil, 1)
        guard sent != 0 else {
            log.error("Query Error: \(self.getErrorMessage(self.connection))")
            return
        }
        
        let singleRowMode = PQsetSingleRowMode(self.connection)
        if ( singleRowMode == 0 ) {
            throw Errors.databaseConnectionError("Could not set single row mode: \(self.getErrorMessage(self.connection))")
        }
        
        var count = 0
        var firstResultInterval :TimeInterval?
        while true {
            guard let result = PQgetResult(self.connection) else {
                break
            }
            defer {
                PQclear(result)
                count += 1
            }
            
            let resultStatus = PQresultStatus(result)
            switch resultStatus {
            case PGRES_EMPTY_QUERY: /* empty query string was executed */
                log.debug("PGRES_EMPTY_QUERY")
                break
            case PGRES_COMMAND_OK:  /* a query command that doesn't return anything was executed properly by the backend */
                log.debug("PGRES_COMMAND_OK")
                break
            case PGRES_TUPLES_OK:  /* a query command that returns tuples was executed properly by the backend, PGresult contains the result tuples */
                log.debug("PGRES_TUPLES_OK")
                break
            case PGRES_COPY_OUT: /* Copy Out data transfer in progress */
                log.debug("PGRES_COPY_OUT")
                break
            case PGRES_COPY_IN:  /* Copy In data transfer in progress */
                log.debug("PGRES_COPY_IN")
                break
            case PGRES_BAD_RESPONSE: /* an unexpected response was recv'd from the backend */
                log.debug("PGRES_BAD_RESPONSE")
                break
            case PGRES_NONFATAL_ERROR: /* notice or warning message */
                log.debug("PGRES_NONFATAL_ERROR")
                break
            case PGRES_FATAL_ERROR:  /* query failed */
                log.debug("PGRES_FATAL_ERROR")
                break
            case PGRES_COPY_BOTH:  /* Copy In/Out data transfer in progress */
                log.debug("PGRES_COPY_BOTH")
                break
            case PGRES_SINGLE_TUPLE:  /* single tuple from larger resultset */
                if count == 0 {
                    firstResultInterval = Date.timeIntervalSinceReferenceDate
                    _ = try self.describeResults(from: result)
                }
                if count % 1000 == 0 {
                    // log.debug("PGRES_SINGLE_TUPLE: \(count)")
                }
                break
            default:
                throw Errors.databaseConnectionError("result status not supported: \(resultStatus)")
            }
            
            //var opt :PQprintOpt = PQprintOpt()
            //opt.header = 1
            //opt.align = 1
            
            // This is suggested by Jordan Rose, but doesn't work because of UInt8 vs Int8
            //let separator: StaticString = "|"
            //let x = UnsafeMutablePointer(mutating:separator.utf8Start as UnsafePointer<Int8>)
            //opt.fieldSep = x

            // This is a little uglier, but it does work.
            //guard let fieldSeparator = "|".cString(using: .utf8) else {
            //    throw Errors.databaseConnectionError("Could not set field separator")
            //}
            //opt.fieldSep = UnsafeMutablePointer(mutating:fieldSeparator)
            //PQprint(stdout, result, &opt);
        }
        
        if let firstResultInterval = firstResultInterval {
            let end = Date.timeIntervalSinceReferenceDate
            let elapsed = end - firstResultInterval
            let rate = Double(count) / elapsed
            log.debug("fetched \(count) rows in \(elapsed)s - \(rate)/s")
        }
    }
    
    func describeResults(from pgresult:OpaquePointer) throws -> [Column] {
        let nFields = PQnfields(pgresult)
        //var columns = [Column]()
        for i in 0..<nFields {
            guard let fieldNameCString = PQfname(pgresult, i) else {
                throw Errors.databaseError("Could not describe results. fieldName comes up null")
            }
            let fieldName = String(cString:fieldNameCString)
            print("field: \(fieldName)")
            //let format = PQfformat(pgresult, i)  // 0=text, 1=binary, other=reserved
            let type = PQftype(pgresult, i) // You can query the system table pg_type to obtain the names and properties of the various data types. The OIDs of the built-in data types are defined in the file src/include/catalog/pg_type.h in the source tree.
            let value = PQgetvalue(pgresult, 0, i)
            //guard let
            //let column = Column(name: fieldName, ordinal: i, externalType: <#T##String#>, externalLength: <#T##String#>, internalType: <#T##Any.Type#>)
        }
        
        return [Column]()
        
        /* print out the row
        for (j = 0; j < nFields; j++)
        printf("%-15s", PQgetvalue(res, 0, j));
        printf("\n");
        */
    }

    func getErrorMessage(_ conn :OpaquePointer?) -> String {
        guard let conn = conn else {
            return "Connection is null"
        }
        guard let message = PQerrorMessage(conn) else {
            return "No Message"
        }
        guard let messageString =  String(validatingUTF8: message) else {
            return "Could not convert from UTF-8"
        }
        return messageString
    }
    
    private func readDatabaseInfo() {
        self.readTypes()
    }
    
    private func readTypes() {
        let sql = "SELECT oid, name, namespace, owner, len, byval, type, category, ispreferred, isdefined, delim, relid, elem, array, input, output, receive, send, modin, modout, analyze, align, storage, notnull, basetype, typmod, ndims, collation, defaultbin, defaultText, acl FROM pg_catalog.pg_type ORDER BY oid"
    }

    /*
     comics=> \d pg_catalog.pg_type;
     Table "pg_catalog.pg_type"
     Column     |     Type     | Modifiers
     ----------------+--------------+-----------
     typname        | name         | not null
     typnamespace   | oid          | not null
     typowner       | oid          | not null
     typlen         | smallint     | not null
     typbyval       | boolean      | not null
     typtype        | "char"       | not null
     typcategory    | "char"       | not null
     typispreferred | boolean      | not null
     typisdefined   | boolean      | not null
     typdelim       | "char"       | not null
     typrelid       | oid          | not null
     typelem        | oid          | not null
     typarray       | oid          | not null
     typinput       | regproc      | not null
     typoutput      | regproc      | not null
     typreceive     | regproc      | not null
     typsend        | regproc      | not null
     typmodin       | regproc      | not null
     typmodout      | regproc      | not null
     typanalyze     | regproc      | not null
     typalign       | "char"       | not null
     typstorage     | "char"       | not null
     typnotnull     | boolean      | not null
     typbasetype    | oid          | not null
     typtypmod      | integer      | not null
     typndims       | integer      | not null
     typcollation   | oid          | not null
     typdefaultbin  | pg_node_tree |
     typdefault     | text         |
     typacl         | aclitem[]    |
     Indexes:
     "pg_type_oid_index" UNIQUE, btree (oid)
     "pg_type_typname_nsp_index" UNIQUE, btree (typname, typnamespace)
 */
}
