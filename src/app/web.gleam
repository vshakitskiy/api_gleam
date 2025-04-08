import app/db
import app/internal/colors.{
  color_blue, color_green, color_orange, color_red, color_white, color_yellow,
}
import app/model
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/io
import gleam/string
import pog
import wisp.{type Request, type Response}

pub type Ctx {
  Ctx(conn: pog.Connection, req: Request, path: List(String))
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

pub fn not_found() -> Response {
  error("unknown endpoint", 404)
}

pub fn error(error: String, code: Int) -> Response {
  model.Err(error)
  |> model.to_json_response()
  |> wisp.json_response(code)
}

fn log_request(req: Request, handler: fn() -> Response) -> Response {
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

  [status, " ", color_white([method]), " ", color_white([req.path])]
  |> string.concat()
  |> io.println()

  res
}

pub fn unwrap_json_result(
  decode_result: Result(a, List(decode.DecodeError)),
  next: fn(a) -> Response,
) -> Response {
  case decode_result {
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
