
// Reference: https://www.postgresql.org/docs/9.5/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS
// Incomplete - get the rest in here.

public class PostgreSQLConnectionDictionaryKey : ConnectionDictionaryKey {
    static var Host                     = PostgreSQLConnectionDictionaryKey(name:"host")
    static let HostAddress              = PostgreSQLConnectionDictionaryKey(name:"hostaddr")
    static let Port                     = PostgreSQLConnectionDictionaryKey(name:"port")
    static let DatabaseName             = PostgreSQLConnectionDictionaryKey(name:"dbname")
    static let User                     = PostgreSQLConnectionDictionaryKey(name:"user")
    static let Password                 = PostgreSQLConnectionDictionaryKey(name:"password")
    static let ConnectTimeout           = PostgreSQLConnectionDictionaryKey(name:"connect_timeout")
    static let ClientEncoding           = PostgreSQLConnectionDictionaryKey(name:"client_encoding")
    static let Options                  = PostgreSQLConnectionDictionaryKey(name:"options")
    static let ApplicationName          = PostgreSQLConnectionDictionaryKey(name:"application_name")
    static let FallbackApplicationName  = PostgreSQLConnectionDictionaryKey(name:"fallback_application_name")
    static let KeepAlives               = PostgreSQLConnectionDictionaryKey(name:"keepalives")
    static let KeepAlivesIdle           = PostgreSQLConnectionDictionaryKey(name:"keepalives_idle")
    static let KeepAlivesInterval       = PostgreSQLConnectionDictionaryKey(name:"keepalives_interval")
    static let KeepAlivesCount          = PostgreSQLConnectionDictionaryKey(name:"keepalives_count")
}
