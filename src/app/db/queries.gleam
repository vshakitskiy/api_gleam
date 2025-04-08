import app/db.{unwrap_query_result}
import app/model
import cake/adapter/postgres
import cake/insert as i
import cake/select as s
import cake/where as w
import gleam/list
import gleam/result
import pog.{type Connection}

pub fn get_user_by_email(email: String, conn: Connection) {
  let pg_result =
    s.new()
    |> s.selects([
      s.col("id"),
      s.col("username"),
      s.col("email"),
      s.col("password_hash"),
    ])
    |> s.from_table("users")
    |> s.where(w.col("email") |> w.eq(w.string(email)))
    |> s.to_query()
    |> postgres.run_read_query(model.db_user_decoder(), conn)

  use unwraped_pg <- unwrap_query_result(pg_result)
  use pg_data <- result.try(unwraped_pg)

  let first =
    list.first(pg_data)
    |> result.replace_error(db.Public("user not found", 404))
  use pg_user <- result.try(first)

  Ok(pg_user)
}

pub fn insert_user(user: model.User, conn: Connection) {
  let cols = ["username", "email", "password_hash"]
  let pg_result =
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
    |> postgres.run_write_query(model.db_user_id_decoder(), conn)

  use unwraped_pg <- unwrap_query_result(pg_result)
  use pg_data <- result.try(unwraped_pg)
  let first =
    list.first(pg_data)
    |> result.replace_error(db.Public("unable to create user", 500))
  use id <- result.try(first)

  Ok(model.User(..user, id:))
}
