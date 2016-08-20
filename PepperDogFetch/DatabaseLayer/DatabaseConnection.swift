
open class DatabaseConnection {

    func verifyConnection() throws {
        fatalError("Subclasses must override")
    }

    func execute(sql :String, bindings :[String:SQLConvertible]?) throws {
        try self.verifyConnection()
    }

}
