import app/web
import gleam/string_tree
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use _req <- web.middleware(req)

  string_tree.from_string("{\"message\": \"Hello, world!\"}")
  |> wisp.json_response(200)
}
