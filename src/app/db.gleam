import app/internal/colors
import app/internal/ffi
import cake/adapter/postgres as pg
import dot_env/env
import gleam/option.{Some}
import pog.{type Connection}
import radish

pub fn with_connection(callback: fn(Connection) -> a) -> a {
  pg.with_connection(
    host: env.get_string_or("DB_HOST", "localhost"),
    port: env.get_int_or("DB_PORT", 5432),
    username: env.get_string_or("DB_USERNAME", "postgres"),
    password: Some(env.get_string_or("DB_PASSWORD", "12345")),
    callback:,
    database: env.get_string_or("DB_NAME", "db"),
  )
}

pub fn test_connection(conn: Connection, callback: fn() -> a) -> a {
  case pg.execute_raw_sql("select 1", conn) {
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
