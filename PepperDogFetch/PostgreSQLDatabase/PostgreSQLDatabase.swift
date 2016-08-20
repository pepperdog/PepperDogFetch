
open class PostgreSQLDatabase : Database {

    override func createConnection() -> DatabaseConnection {
        return PostgreSQLConnection(connectionDictionary: self.connectionDictionary)
    }

}
