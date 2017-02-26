
import hexdreamsCocoa
import libpq

open class PostgreSQLConnection : DatabaseConnection {
    
    let connectionDictionary :[String:String]
    var connection :OpaquePointer?
    let listenChannel = "foo"
    
    init(connectionDictionary: [String:String]) {
        self.connectionDictionary = connectionDictionary
    }
    
    // Google: swift const char * const *
    // const char * const *
    // http://stackoverflow.com/questions/36783767/array-of-swift-strings-into-const-char-const
    // https://www.reddit.com/r/swift/comments/3g8y77/cchar_versus_unsafepointercchar_for_a/
    
    // Google: postgresql asynchronous connection example
    // https://gist.github.com/revmischa/5384678
    open func connect() throws {
        if self.connection != nil {
            return
        }
        
        var names = [String]()
        var values = [String]()
        for (name,value) in connectionDictionary {
            names.append(name)
            values.append(value)
        }
        guard let conn = PQconnectStartParams(try names.cStringArray().pointer, try values.cStringArray().pointer, 0) else {
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
    }

    private func mainLoop(_ conn :OpaquePointer) throws {
        var rfds :fd_set = fd_set()
        var wfds :fd_set = fd_set()
        var tv   :timeval = timeval()
        var retval :Int32
        var sock   :Int32
        var connStatus :PostgresPollingStatusType
        var connected :Bool = false
        
        while !connected {
            sock = PQsocket(conn)
            if ( sock < 0 ) {
                throw Errors.databaseConnectionError("Postgres socket is gone")
            }
            
            C.FD_ZERO(&rfds)
            C.FD_ZERO(&wfds)
            
            tv.tv_sec = 2
            tv.tv_usec = 0
            
            if !connected {
                connStatus = PQconnectPoll(conn);
                
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
                    try initListen(conn);
                    break
                case PGRES_POLLING_ACTIVE:  // deprecated
                    log.debug("PGRES_POLLING_ACTIVE - deprecated")
                    break
                default:
                    throw Errors.databaseConnectionError("connection status not supported: \(connStatus)")
                }
            }
            
            if connected {
                C.FD_SET(sock, &rfds)
            }
            
            retval = select(sock + Int32(1), &rfds, &wfds, nil, &tv);
            switch retval {
            case -1:
                log.error("select() failed")
                throw Errors.databaseConnectionError("select() failed")
            case 0:
                log.error("socket timed out")
                throw Errors.databaseConnectionError("socket timed out")
            default:
                if !connected {
                    break
                }
                
                if C.FD_ISSET(sock, &rfds) {
                    // ready to read from pg
                    try handlePgRead(conn);
                }
                break;
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

    // https://www.postgresql.org/docs/9.1/static/libpq-async.html
    // https://www.postgresql.org/message-id/20160331195656.17bc0e3b@slate.meme.com
    override func execute(sql :String, bindings :[String:SQLConvertible]?) throws {
        try self.verifyConnection()
        let sent = PQsendQuery(self.connection, sql.cString(using:.utf8));
        if sent == 0 {
            log.error("Query Error: \(self.getErrorMessage(self.connection))")
            return
        }
        let singleRowMode = PQsetSingleRowMode(self.connection)
        if ( singleRowMode == 0 ) {
            log.error("Could not set single row mode: \(self.getErrorMessage(self.connection))")
            return
        }
        var opt :PQprintOpt = PQprintOpt()
        opt.header = 1
        opt.align = 1
        var count = 0
        while true {
            guard let result = PQgetResult(self.connection) else {
                break
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
                //log.debug("PGRES_SINGLE_TUPLE")
                count += 1
                break
            default:
                throw Errors.databaseConnectionError("result status not supported: \(resultStatus)")
            }
            //PQprint(stdout, result, &opt);
        }
        log.debug("fetched \(count) rows")
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
    
}
