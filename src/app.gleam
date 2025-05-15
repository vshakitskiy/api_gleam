import app/context
import app/db
import app/db/migration
import app/internal/colors.{print_red}
import app/internal/ffi
import app/router
import app/server
import argv
import dot_env as dot
import dot_env/env
import wisp

pub fn main() {
  init()

  let args = argv.load().arguments
  case args {
    ["dev"] -> run_server()
    ["migrate", "up"] -> run_migration(migration.Up)
    ["migrate", "down"] -> run_migration(migration.Down)
    _ -> print_red(["Options: dev / migrate up / migrate down"])
  }
}

fn init() {
  wisp.configure_logger()

  dot.new()
  |> dot.set_path(".env")
  |> dot.load()
}

fn run_migration(opt: migration.MigrationOption) {
  use conn <- db.with_connection()
  use <- db.test_connection(conn)

  migration.run(opt, conn)
}

fn run_server() {
  use conn <- db.with_connection()
  use <- db.test_connection(conn)

  use redis <- db.with_redis()

  let secret =
    wisp.random_string(64)
    |> env.get_string_or("SECRET_KEY", _)
  let port = env.get_int_or("PORT", 4040)
  let jwt_key = case env.get_string("JWT_SECRET") {
    Ok(key) -> key
    Error(_) -> {
      colors.print_red(["JWT_SECRET is not provided"])
      ffi.exit(1)
    }
  }

  server.start_server(
    fn(req) {
      router.handle_req(context.new_contex(
        conn,
        req,
        jwt_key,
        redis,
        env.get_int_or("REDIS_TIMEOUT_MS", 250),
      ))
    },
    port,
    secret,
  )
}
