
public class Database {

    enum ConnectionDictionary {
        case Host, Port, DatabaseName, User, Password
    }

    let connectionDictionary :[ConnectionDictionary:String]

    lazy var connectionPool :ConnectionPool = {
        return ConnectionPool(database:self)
    }()

    init(connectionDictionary: [ConnectionDictionary:String]) {
        self.connectionDictionary = connectionDictionary;
    }

    func createConnection() -> DatabaseConnection {
        fatalError("Not implemented")
    }

    func execute(sql :String, bindings :[String:SQLConvertible]?) throws -> ResultSet<Row> {
        let resultSet = ResultSet<Row>()

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
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