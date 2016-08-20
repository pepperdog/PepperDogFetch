//
//  ConnectionPool.swift
//  PepperDogFetch
//
//  Created by Kenny Leung on 2016-04-05.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

class ConnectionPool {

    let database :Database
    let poolQueue :DispatchQueue
    var pool :[DatabaseConnection]

    init(database: Database) {
        self.database = database;
        self.poolQueue = DispatchQueue(label: "c.p-e.PDF.ConnectionPool.poolQueue.", attributes: [])
        self.pool = [DatabaseConnection]()
    }

    func acquireConnection() throws -> DatabaseConnection {
        var connection :DatabaseConnection? = nil

        self.poolQueue.sync {
            if self.pool.count > 0 {
                connection = self.pool.removeLast()
            }
        }

        if let connection = connection {
            return connection
        } else {
            return database.createConnection()
        }
    }

    func release(_ connection :DatabaseConnection) {
        self.poolQueue.sync {
            self.pool.append(connection)
        }
    }

}


