import app/internal/colors.{print_blue, print_red}
import app/internal/ffi.{exit}
import cake/adapter/postgres as pg
import pog.{type Connection}

pub type MigrationOption {
  Up
  Down
}

pub fn run(option: MigrationOption, conn: Connection) -> Nil {
  case option {
    Up -> migrate_up(conn)
    Down -> migrate_down(conn)
  }
}

fn migrate_up(conn: Connection) -> Nil {
  execute("Create table users", create_users_table, conn)
}

fn migrate_down(conn: Connection) -> Nil {
  execute("Drop table users", drop_users_table, conn)
}

fn execute(name: String, query: fn() -> String, conn: Connection) -> Nil {
  let res = query() |> pg.execute_raw_sql(conn)

  case res {
    Ok(_) -> print_blue([name, ": ok"])
    Error(_) -> {
      print_red([name, ": ERR"])
      exit(1)
    }
  }
}

fn create_users_table() -> String {
  "
    create table if not exists users (
      id serial primary key,
      username text not null,
      email text unique not null,
      password_hash text not null
    );
  "
}

fn drop_users_table() -> String {
  "drop table if exists users;"
}
