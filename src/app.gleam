import app/db
import app/db/migration as mg
import app/internal/colors.{print_red}
import app/internal/ffi
import app/router
import app/server
import app/web
import argv
import dot_env as dot
import dot_env/env
import gleam/io
import wisp

pub fn main() {
  let args = argv.load().arguments

  case args {
    ["dev"] -> run_server("dev")
    ["migrate", "up"] -> run_migration(mg.Up)
    ["migrate", "down"] -> run_migration(mg.Down)
    _ -> print_red(["Options: dev / migrate up / migrate down"])
  }
}

fn init(mode: String) {
  wisp.configure_logger()
  let set_debug = case mode {
    "dev" -> True
    _ -> False
  }

  dot.new()
  |> dot.set_path(".env")
  |> dot.set_debug(set_debug)
  |> dot.load()
}

fn run_migration(opt: mg.MigrationOption) {
  init("")

  use conn <- db.with_connection()
  use <- db.test_connection(conn)

  mg.run(opt, conn)
}

fn run_server(mode: String) {
  io.println("")

  init(mode)
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
    fn(req) { router.handle_request(web.init_ctx(conn, req, jwt_key, redis)) },
    port,
    secret,
  )
}
