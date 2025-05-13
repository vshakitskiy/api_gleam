import app/db
import app/db/query
import app/internal/colors.{
  color_blue, color_green, color_orange, color_red, color_white, color_yellow,
}
import app/internal/ffi
import app/internal/jwt
import app/model
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/io
import gleam/string
import pog
import radish
import wisp.{type Request, type Response}

pub type Ctx {
  Ctx(
    conn: pog.Connection,
    req: Request,
    path: List(String),
    jwt_key: String,
    redis: radish.Client,
    timeout_ms: Int,
  )
}

pub fn init_ctx(
  conn: pog.Connection,
  req: Request,
  jwt_key: String,
  redis: radish.Client,
  timeout_ms: Int,
) -> Ctx {
  Ctx(conn:, req:, path: [], jwt_key:, redis:, timeout_ms:)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  use <- log_request(req)
  use <- wisp.rescue_crashes()
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn auth_middleware(
  c: Ctx,
  handle_request: fn(model.User) -> Response,
) -> Response {
  let token_result = wisp.get_cookie(c.req, "token", wisp.PlainText)

  case token_result {
    Error(_) -> error("unauthorized", 401)
    Ok(token) -> {
      echo token

      case jwt.validate_jwt(token, c.jwt_key) {
        Error(_) -> error("unauthorized", 401)
        Ok(user_id) -> {
          let user = query.get_user_by_id(user_id, c.conn)

          case user {
            Error(_) -> error("unauthorized", 401)
            Ok(user) -> handle_request(user)
          }
        }
      }
    }
  }
}

pub fn not_found() -> Response {
  error("unknown endpoint", 404)
}

pub fn error(error: String, code: Int) -> Response {
  model.Err(error)
  |> model.res_body_to_string_tree()
  |> wisp.json_response(code)
}

fn log_request(req: Request, handler: fn() -> Response) -> Response {
  let start = ffi.milliseconds()

  let res = handler()

  let method =
    req.method
    |> http.method_to_string()
    |> string.uppercase()

  let str_status = res.status |> int.to_string()
  let status = case res.status / 100 {
    1 -> color_blue([str_status])
    2 -> color_green([str_status])
    3 -> color_yellow([str_status])
    4 -> color_red([str_status])
    5 -> color_red([str_status])
    _ -> color_orange([str_status])
  }

  let ms = ffi.milliseconds() - start
  let str_ms = int.to_string(ms) <> "ms"
  let time = case ms {
    _ if ms < 50 -> color_green([str_ms])
    _ if ms < 250 -> color_yellow([str_ms])
    _ if ms < 500 -> color_orange([str_ms])
    _ -> color_red([str_ms])
  }

  [status, " ", color_white([method]), " ", color_white([req.path]), " ", time]
  |> string.concat()
  |> io.println()

  res
}

pub fn ensure_json(
  req: Request,
  decoder: decode.Decoder(a),
  next: fn(a) -> Response,
) {
  use json <- wisp.require_json(req)
  let decoder_result = decode.run(json, decoder)

  unwrap_decoding(decoder_result, next)
}

pub fn unwrap_decoding(decoder_result: Result(a, b), next: fn(a) -> Response) {
  case decoder_result {
    Ok(decoded) -> next(decoded)
    Error(_) -> error("invalid body content", 400)
  }
}

pub fn validate_condition(
  condition: Bool,
  msg: String,
  next: fn() -> Response,
) -> Response {
  case condition {
    True -> next()
    False -> error(msg, 400)
  }
}

pub fn unwrap_query(
  query_result: Result(a, db.PGError),
  next: fn(a) -> Response,
) {
  case query_result {
    Ok(data) -> next(data)
    Error(e) ->
      case e {
        db.Internal(msg) -> {
          colors.print_red([msg])
          error("internal server error", 500)
        }
        db.Public(msg, status) -> error(msg, status)
      }
  }
}
