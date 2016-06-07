//
//  ConnectionPool.swift
//  PepperDogFetch
//
//  Created by Kenny Leung on 2016-04-05.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

class ConnectionPool {

    let database :Database
    let poolQueue :dispatch_queue_t
    var pool :[DatabaseConnection]

    init(database: Database) {
        self.database = database;
        self.poolQueue = dispatch_queue_create("com.pepperdog-enterprises.PepperDogFetch.ConnectionPool.poolQueue", DISPATCH_QUEUE_SERIAL)
        self.pool = [DatabaseConnection]()
    }

    func acquireConnection() throws -> DatabaseConnection {
        var connection :DatabaseConnection? = nil

        dispatch_sync(self.poolQueue) {
            connection = self.pool.removeLast()
            if connection == nil {
                connection = self.database.createConnection()
            }
        }

        guard let conn = connection else {
            throw PDFetch.Error.DatabaseConnectionError
        }
        return conn
    }

    func release(connection :DatabaseConnection) {
        dispatch_sync(self.poolQueue) {
            self.pool.append(connection)
        }
    }

}


