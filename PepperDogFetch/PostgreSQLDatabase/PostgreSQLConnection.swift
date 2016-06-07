
import libpq

public class PostgreSQLConnection : DatabaseConnection {

    let connectionDictionary :[String:String]

    init(connectionDictionary: [String:String]) {
        self.connectionDictionary = connectionDictionary
    }

    // Google: swift const char * const *
    // http://stackoverflow.com/questions/36783767/array-of-swift-strings-into-const-char-const
    public func connect() throws {
        var parameterNames = [UnsafePointer<CChar>?]()
        var parameterValues = [UnsafePointer<CChar>?]()

        for (key,value) in self.connectionDictionary {
            guard let ckey = key.cString(using: String.defaultCStringEncoding()) else {
                throw PDFetch.Error.DatabaseConnectionError
            }
            guard let cvalue = value.cString(using: String.defaultCStringEncoding()) else {
                throw PDFetch.Error.DatabaseConnectionError
            }
            parameterNames.append(ckey)
            parameterValues.append(cvalue)
        }
        parameterNames.append(nil)
        parameterValues.append(nil)

        let conn = PQconnectStartParams(parameterNames, parameterValues, 0)
        if ( conn == nil ) {
            throw PDFetch.Error.DatabaseConnectionError
        }

        while true {
            let status = PQstatus(conn)
            if status == CONNECTION_OK {
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

}
