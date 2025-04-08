import app/db/query
import app/model
import app/web.{type Ctx, Ctx}
import gleam/dynamic/decode
import gleam/http
import gleam/regexp
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

const email_regex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"

const password_regex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$"

type CreateUser {
  CreateUser(username: String, email: String, password: String)
}

fn create_user_req_decoder() -> decode.Decoder(CreateUser) {
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(CreateUser(username:, email:, password:))
}

pub fn handle_auth(c: Ctx) -> Response {
  case c.req.method, c.path {
    http.Post, ["register"] -> create_user(c)
    _, _ -> web.not_found()
  }
}

fn create_user(c: Ctx) -> Response {
  use json <- wisp.require_json(c.req)
  let decoder_result = decode.run(json, create_user_req_decoder())
  use CreateUser(username, email, password) <- web.unwrap_json_result(
    decoder_result,
  )

  use <- web.validate_condition(
    string.length(username) > 3 && string.length(username) < 21,
    "username must be 3-20 characters long",
  )

  let assert Ok(email_re) = regexp.from_string(email_regex)
  use <- web.validate_condition(
    regexp.check(email_re, email),
    "email must be valid",
  )

  let assert Ok(password_re) = regexp.from_string(password_regex)
  use <- web.validate_condition(
    regexp.check(password_re, password),
    "password must be longer than 8 characters and contain at least one upper letter, lower letter and digit",
  )

  let query_result =
    query.insert_user(
      model.User(0, username:, email:, password_hash: password),
      c.conn,
    )
  use user <- web.unwrap_query(query_result)

  model.user_json(user)
  |> model.Data("user created")
  |> model.to_json_response()
  |> wisp.json_response(201)
}
