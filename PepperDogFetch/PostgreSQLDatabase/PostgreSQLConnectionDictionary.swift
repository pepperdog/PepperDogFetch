
// Reference: https://www.postgresql.org/docs/9.5/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS
// Incomplete - get the rest in here.

enum PostgreSQLConnectionDictionary : String {
    case Host = "host"
    case HostAddress = "hostaddr"
    case Port = "port"
    case DatabaseName = "dbname"
    case User = "user"
    case Password = "password"
    case ConnectTimeout = "connect_timeout"
    case ClientEncoding = "client_encoding"
    case Options = "options"
    case ApplicationName = "application_name"
    case FallbackApplicationName = "fallback_application_name"
    case KeepAlives = "keepalives"
    case KeepAlivesIdle = "keepalives_idle"
    case KeepAlivesInterval = "keepalives_interval"
    case KeepAlivesCount = "keepalives_count"
}
