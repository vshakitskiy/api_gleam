import app/db/query.{type PGError, Public, with_formatted_error}
import app/model
import cake/adapter/postgres as pg
import cake/insert as i
import cake/select as s
import cake/where as w
import gleam/list
import gleam/result
import pog.{type Connection}

pub fn get_user_cake() {
  s.new()
  |> s.selects([
    s.col("id"),
    s.col("username"),
    s.col("email"),
    s.col("password_hash"),
  ])
  |> s.from_table("users")
}

pub fn get_user_by_email(
  email: String,
  conn: Connection,
) -> Result(model.User, PGError) {
  let pg_res =
    get_user_cake()
    |> s.where(w.col("email") |> w.eq(w.string(email)))
    |> s.to_query()
    |> pg.run_read_query(model.from_db_user_decoder(), conn)

  use unwraped_pg <- with_formatted_error(pg_res)
  use pg_data <- result.try(unwraped_pg)

  let first =
    list.first(pg_data)
    |> result.replace_error(Public("user not found", 404))
  use pg_user <- result.try(first)

  Ok(pg_user)
}

pub fn get_user_by_id(id: Int, conn: Connection) {
  let pg_res =
    get_user_cake()
    |> s.where(w.col("id") |> w.eq(w.int(id)))
    |> s.to_query()
    |> pg.run_read_query(model.from_db_user_decoder(), conn)

  use unwraped_pg <- with_formatted_error(pg_res)
  use pg_data <- result.try(unwraped_pg)

  let first =
    list.first(pg_data)
    |> result.replace_error(Public("user not found", 404))
  use pg_user <- result.try(first)
  Ok(pg_user)
}

pub fn insert_user(
  user: model.User,
  conn: Connection,
) -> Result(model.User, PGError) {
  let cols = ["username", "email", "password_hash"]
  let pg_res =
    [
      i.string(user.username),
      i.string(user.email),
      i.string(user.password_hash),
    ]
    |> i.row()
    |> list.wrap()
    |> i.from_values(table_name: "users", columns: cols)
    |> i.returning(["id"])
    |> i.to_query()
    |> pg.run_write_query(model.user_id_decoder(), conn)

  use unwraped_pg <- with_formatted_error(pg_res)
  use pg_data <- result.try(unwraped_pg)
  let first =
    list.first(pg_data)
    |> result.replace_error(Public("unable to create user", 500))
  use id <- result.try(first)

  Ok(model.User(..user, id:))
}
