
// https://www.postgresql.org/docs/9.6/static/catalog-pg-type.html


class PGType {
    typealias name = String
    typealias oid = Int
    typealias smallint = Int
    typealias boolean = Bool
    typealias char = Character
    typealias regproc = String
    typealias integer = Int
    typealias pg_node_tree = String
    typealias text = String
    typealias aclitem = String
    
    var name        :name
    var namespace   :oid
    var owner       :oid
    var len         :smallint
    var byval       :boolean
    var type        :char
    var category    :char
    var ispreferred :boolean
    var isdefined   :boolean
    var delim       :char
    var relid       :oid
    var elem        :oid
    var array       :oid
    var input       :regproc
    var output      :regproc
    var receive     :regproc
    var send        :regproc
    var modin       :regproc
    var modout      :regproc
    var analyze     :regproc
    var align       :char
    var storage     :char
    var notnull     :boolean
    var basetype    :oid
    var typmod      :integer
    var ndims       :integer
    var collation   :oid
    var defaultbin  :pg_node_tree?
    var defaultText :text?
    var acl         :[aclitem]?
    
    public init(name        :name         ,
                namespace   :oid          ,
                owner       :oid          ,
                len         :smallint     ,
                byval       :boolean      ,
                type        :char         ,
                category    :char         ,
                ispreferred :boolean      ,
                isdefined   :boolean      ,
                delim       :char         ,
                relid       :oid          ,
                elem        :oid          ,
                array       :oid          ,
                input       :regproc      ,
                output      :regproc      ,
                receive     :regproc      ,
                send        :regproc      ,
                modin       :regproc      ,
                modout      :regproc      ,
                analyze     :regproc      ,
                align       :char         ,
                storage     :char         ,
                notnull     :boolean      ,
                basetype    :oid          ,
                typmod      :integer      ,
                ndims       :integer      ,
                collation   :oid          ,
                defaultbin  :pg_node_tree?,
                defaultText :text?        ,
                acl         :[aclitem]?
        ) {
        self.name        = name
        self.namespace   = namespace
        self.owner       = owner
        self.len         = len
        self.byval       = byval
        self.type        = type
        self.category    = category
        self.ispreferred = ispreferred
        self.isdefined   = isdefined
        self.delim       = delim
        self.relid       = relid
        self.elem        = elem
        self.array       = array
        self.input       = input
        self.output      = output
        self.receive     = receive
        self.send        = send
        self.modin       = modin
        self.modout      = modout
        self.analyze     = analyze
        self.align       = align
        self.storage     = storage
        self.notnull     = notnull
        self.basetype    = basetype
        self.typmod      = typmod     
        self.ndims       = ndims      
        self.collation   = collation  
        self.defaultbin  = defaultbin 
        self.defaultText = defaultText
        self.acl         = acl        
    }
}


