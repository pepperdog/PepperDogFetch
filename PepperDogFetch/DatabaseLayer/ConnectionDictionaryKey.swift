
// Abstract class for defining connection dictionary keys
public class ConnectionDictionaryKey : Hashable {
    // Equatable protocol
    public static func ==(lhs: ConnectionDictionaryKey, rhs: ConnectionDictionaryKey) -> Bool {
        return lhs.name == rhs.name
    }

    // Hashable protocol
    public var hashValue :Int {
        return self.name.hashValue
    }
    
    let name :String
    
    public init(name :String) {
        self.name = name
    }
}

