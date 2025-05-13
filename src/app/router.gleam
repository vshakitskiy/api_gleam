import app/model
import app/router/auth.{handle_auth}
import app/web.{type Ctx, Ctx}
import gleam/http
import wisp.{type Response}

pub fn handle_request(c: Ctx) -> Response {
  use req <- web.middleware(c.req)
  case wisp.path_segments(c.req) {
    ["api", "v1", ..path] -> handle_v1(Ctx(..c, path:, req:))
    _ -> web.not_found()
  }
}

fn handle_v1(c: Ctx) -> Response {
  case c.req.method, c.path {
    _, ["auth", ..path] -> handle_auth(Ctx(..c, path:))
    http.Get, ["ping"] ->
      model.Message("pong!")
      |> model.res_body_to_string_tree()
      |> wisp.json_response(200)
    _, _ -> web.not_found()
  }
}
