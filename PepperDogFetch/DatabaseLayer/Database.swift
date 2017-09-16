
open class Database {

    let connectionDictionary :[ConnectionDictionaryKey:String]

    lazy var connectionPool :ConnectionPool = {
        return ConnectionPool(database:self)
    }()

    init(connectionDictionary: [ConnectionDictionaryKey:String]) {
        self.connectionDictionary = connectionDictionary;
    }

    func createConnection() -> DatabaseConnection {
        fatalError("Subclasses must override this method")
    }

    func execute(sql :String, bindings :[String:SQLConvertible]?) throws -> ResultSet<Row> {
        let resultSet = ResultSet<Row>()

        // Here's where we might decide to go synchronous or asynchronous with the fetch. If we decide to go asynchronous, then we need to create the fetching info
        resultSet.goAsynchronous()

        DispatchQueue.global(qos: .background).async {
            do {
                let connection = try self.connectionPool.acquireConnection()
                try connection.execute(sql: sql, bindings: bindings)
            } catch {
                resultSet.error = error
            }
        }

        return resultSet;
    }

}
