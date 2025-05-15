import app/context.{type Context, Context}
import app/middleware
import app/model
import app/router/auth.{handle_auth}
import app/web
import gleam/http
import wisp.{type Response}

pub fn handle_req(c: Context) -> Response {
  use req <- middleware.default(c.req)
  case wisp.path_segments(c.req) {
    ["api", "v1", ..path] -> handle_v1(Context(..c, path:, req:))
    _ -> web.not_found()
  }
}

fn handle_v1(c: Context) -> Response {
  case c.req.method, c.path {
    _, ["auth", ..path] -> handle_auth(Context(..c, path:))
    http.Get, ["ping"] ->
      model.Message("pong!")
      |> model.resp_body_to_string_tree()
      |> wisp.json_response(200)
    _, _ -> web.not_found()
  }
}
