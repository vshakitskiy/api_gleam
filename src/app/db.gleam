import cake/adapter/postgres
import dot_env/env
import gleam/option.{Some}
import pog.{type Connection}

pub fn with_connection(callback: fn(Connection) -> a) {
  postgres.with_connection(
    host: env.get_string_or("DB_HOST", "127.0.0.1"),
    port: env.get_int_or("DB_PORT", 5432),
    username: env.get_string_or("DB_USERNAME", "postgres"),
    password: Some(env.get_string_or("DB_PASSWORD", "12345")),
    callback:,
    database: env.get_string_or("DB_NAME", "db"),
  )
}

pub fn test_connection(conn: Connection) {
  case postgres.execute_raw_sql("select 1", conn) {
    Ok(_) -> Ok(conn)
    Error(_) -> Error(Nil)
  }
}
