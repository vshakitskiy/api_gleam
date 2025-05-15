import app/context.{type Context}
import app/internal/colors.{
  color_blue, color_green, color_orange, color_red, color_white, color_yellow,
}
import app/internal/ffi
import app/internal/jwt
import app/web
import gleam/http
import gleam/int
import gleam/io
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

pub fn default(req: Request, next: fn(Request) -> Response) -> Response {
  use <- log_request(req)
  use <- wisp.rescue_crashes()
  use req <- wisp.handle_head(req)

  next(req)
}

pub fn auth(c: Context, next: fn(Int) -> Response) -> Response {
  let resp = {
    let token_res =
      wisp.get_cookie(c.req, "token", wisp.PlainText)
      |> result.map_error(fn(_) { web.unauthorized() })
    use token <- result.try(token_res)

    let validate_res =
      jwt.validate_jwt(token, c.jwt_key)
      |> result.map_error(fn(_) { web.unauthorized() })
    use user_id <- result.try(validate_res)

    Ok(next(user_id))
  }

  result.unwrap_both(resp)
}

fn log_request(req: Request, next: fn() -> Response) -> Response {
  let start = ffi.milliseconds()

  let resp = next()

  let method =
    req.method
    |> http.method_to_string()
    |> string.uppercase()

  let str_status = resp.status |> int.to_string()
  let status = case resp.status / 100 {
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

  resp
}
