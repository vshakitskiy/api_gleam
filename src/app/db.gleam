import cake/adapter/postgres
import dot_env/env
import gleam/int
import gleam/option.{Some}
import gleam/string
import pog.{type Connection, type QueryError}

pub type PGError {
  Internal(msg: String)
  Public(msg: String, code: Int)
}

pub fn with_connection(callback: fn(Connection) -> a) -> a {
  postgres.with_connection(
    host: env.get_string_or("DB_HOST", "127.0.0.1"),
    port: env.get_int_or("DB_PORT", 5432),
    username: env.get_string_or("DB_USERNAME", "postgres"),
    password: Some(env.get_string_or("DB_PASSWORD", "12345")),
    callback:,
    database: env.get_string_or("DB_NAME", "db"),
  )
}

pub fn test_connection(conn: Connection) -> Result(Connection, Nil) {
  case postgres.execute_raw_sql("select 1", conn) {
    Ok(_) -> Ok(conn)
    Error(_) -> Error(Nil)
  }
}

pub fn unwrap_query_result(
  pg_result: Result(a, QueryError),
  next: fn(Result(a, PGError)) -> b,
) -> b {
  case pg_result {
    Ok(pg_data) -> next(Ok(pg_data))
    Error(pg_error) -> {
      let msg = case pg_error {
        pog.ConstraintViolated(msg, constr, dtl) -> {
          case string.contains(dtl, "already exists") {
            True -> Error(Public("already exists", 409))
            False ->
              Error(Internal(
                "constraint " <> constr <> " violated: " <> dtl <> "\n" <> msg,
              ))
          }
        }
        pog.PostgresqlError(code, name, msg) ->
          Error(Internal(
            "postgresql error " <> code <> " (" <> name <> "): " <> msg,
          ))
        pog.UnexpectedArgumentCount(expected, got) ->
          Error(Internal(
            "unexpected argument count: expected "
            <> int.to_string(expected)
            <> ", got "
            <> int.to_string(got),
          ))
        pog.UnexpectedArgumentType(expected, got) ->
          Error(Internal(
            "unexpected argument type: expected " <> expected <> ", got " <> got,
          ))
        pog.UnexpectedResultType(l) -> {
          echo l
          Error(Internal("unexpected result type"))
        }
        pog.QueryTimeout -> Error(Internal("query timeout"))
        pog.ConnectionUnavailable -> Error(Internal("database is unavailable"))
      }
      next(msg)
    }
  }
}
