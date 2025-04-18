import app/db/query
import app/internal/jwt
import app/internal/password
import app/model
import app/web.{type Ctx, Ctx}
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/regexp
import gleam/string
import radish
import wisp.{type Response}

const email_regex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"

const password_regex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$"

type Register {
  Register(username: String, email: String, password: String)
}

type Login {
  Login(email: String, password: String)
}

fn register_decoder() -> decode.Decoder(Register) {
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(Register(username:, email:, password:))
}

fn login_decoder() -> decode.Decoder(Login) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(Login(email:, password:))
}

pub fn handle_auth(c: Ctx) -> Response {
  case c.req.method, c.path {
    http.Post, ["register"] -> register(c)
    http.Post, ["login"] -> login(c)
    http.Post, ["logout"] -> logout(c)
    http.Get, ["status"] -> status(c)
    _, _ -> web.not_found()
  }
}

fn register(c: Ctx) -> Response {
  use Register(username, email, password) <- web.ensure_json(
    c.req,
    register_decoder(),
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

  let password_hash = password.hash_password(password)
  let query_result =
    query.insert_user(model.User(0, username:, email:, password_hash:), c.conn)
  use user <- web.unwrap_query(query_result)

  let json_user = model.user_to_json(user)
  let json_stringified = json_user |> json.to_string()

  let _ =
    radish.set(
      c.redis,
      "user:" <> user.id |> int.to_string(),
      json_stringified,
      100,
    )
  let _ = radish.set(c.redis, "user:" <> user.email, json_stringified, 100)

  json_user
  |> model.Data("user created")
  |> model.res_body_to_string_tree()
  |> wisp.json_response(201)
}

fn login(c: Ctx) -> Response {
  use Login(email, password) <- web.ensure_json(c.req, login_decoder())

  use user <- fetch_user(email, c)

  case password.verify_password(user.password_hash, password) {
    True -> {
      let token = jwt.sign_jwt(user.id, c.jwt_key, 60 * 60 * 24)

      wisp.ok()
      |> wisp.set_cookie(c.req, "token", token, wisp.PlainText, 60 * 60 * 24)
    }
    False -> web.error("invalid credentials", 401)
  }
}

fn fetch_user(email: String, c: Ctx, next: fn(model.User) -> Response) {
  case radish.get(c.redis, "user:" <> email, 30) {
    Ok(user_json) -> {
      let user = json.parse(user_json, model.from_json_user_decoder())
      use user <- web.unwrap_decoding(user)
      next(user)
    }
    Error(_) -> {
      let query_result = query.get_user_by_email(email, c.conn)
      use user <- web.unwrap_query(query_result)
      next(user)
    }
  }
}

fn logout(c: Ctx) -> Response {
  wisp.ok()
  |> wisp.set_cookie(c.req, "token", "", wisp.PlainText, 0)
}

fn status(c: Ctx) -> Response {
  use user <- web.auth_middleware(c)

  model.user_to_json(user)
  |> model.Data("authorized")
  |> model.res_body_to_string_tree()
  |> wisp.json_response(200)
}
