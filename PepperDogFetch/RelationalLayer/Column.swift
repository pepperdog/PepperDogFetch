
open class Column {
    
    var name           :String
    var ordinal        :Int
    var externalType   :String
    var externalLength :String
    var internalType   :Any.Type
    
    init(name:String, ordinal:Int, externalType:String, externalLength:String, internalType:Any.Type) {
        self.name = name
        self.ordinal = ordinal
        self.externalType = externalType
        self.externalLength = externalLength
        self.internalType = internalType
    }
    
}
