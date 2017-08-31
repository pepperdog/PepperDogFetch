
open class DatabaseConnection {

    func verifyConnection() throws {
        fatalError("Subclasses must override")
    }

    func execute(sql :String, bindings :[String:SQLConvertible]?) throws {
        try self.verifyConnection()
    }
    
    func describeResults() -> [Column] {
        fatalError("Subclasses must override")
    }
    
    /*
    - need a describeResults
    - ResultSet should be optimized for generic record (Row) fetching. Make Row a struct, store columns in individual typed arrays inside the ResultSet for space efficiency.
     - try including https://github.com/spacialdb/libpq.framework (rebuild) and see if the wrapping for char * is better.
 */
}
