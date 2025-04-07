import app/internal.{exit, print_blue, print_red}
import cake/adapter/postgres
import pog.{type Connection}

pub type MigrationOption {
  Up
  Down
}

pub fn run(option: MigrationOption, conn: Connection) {
  case option {
    Up -> migrate_up(conn)
    Down -> migrate_down(conn)
  }
}

fn migrate_up(conn: Connection) {
  execute("Create table users", create_users_table, conn)
}

fn migrate_down(conn: Connection) {
  execute("Drop table users", drop_users_table, conn)
}

fn execute(name: String, query: fn() -> String, conn: Connection) {
  let result =
    query()
    |> postgres.execute_raw_sql(conn)

  case result {
    Ok(_) -> print_blue([name, ": ok"])
    Error(_) -> {
      print_red([name, ": ERR"])
      exit(1)
    }
  }
}

fn create_users_table() {
  "
    create table if not exists users (
      id serial primary key,
      username text not null,
      email text unique not null,
      password_hash text not null
    );
  "
}

fn drop_users_table() {
  "drop table if exists users;"
}
