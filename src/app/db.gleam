import app/internal/colors
import app/internal/ffi
import cake/adapter/postgres
import dot_env/env
import gleam/int
import gleam/option.{Some}
import gleam/string
import pog.{type Connection, type QueryError}
import radish

pub type PGError {
  Internal(msg: String)
  Public(msg: String, code: Int)
}

pub fn with_connection(callback: fn(Connection) -> a) -> a {
  postgres.with_connection(
    host: env.get_string_or("DB_HOST", "localhost"),
    port: env.get_int_or("DB_PORT", 5432),
    username: env.get_string_or("DB_USERNAME", "postgres"),
    password: Some(env.get_string_or("DB_PASSWORD", "12345")),
    callback:,
    database: env.get_string_or("DB_NAME", "db"),
  )
}

pub fn test_connection(conn: Connection, callback: fn() -> a) -> a {
  case postgres.execute_raw_sql("select 1", conn) {
    Ok(_) -> {
      colors.print_green(["Postgres connection: OK"])
      callback()
    }
    Error(_) -> {
      colors.print_red(["Postgres connection: ERROR"])
      ffi.exit(1)
    }
  }
}

pub fn with_redis(callback: fn(radish.Client) -> a) -> a {
  let host = env.get_string_or("REDIS_HOST", "localhost")
  let port = env.get_int_or("REDIS_PORT", 4041)
  case radish.start(host, port, [radish.Timeout(128)]) {
    Ok(client) -> {
      colors.print_green(["Redis connection: OK"])
      callback(client)
    }
    Error(e) -> {
      echo e
      colors.print_red(["Redis connection: ERROR"])
      ffi.exit(1)
    }
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
