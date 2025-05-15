import app/db/query
import app/internal/colors
import app/model
import gleam/dynamic/decode
import wisp.{type Request, type Response}

pub fn not_found() -> Response {
  error_resp("unknown endpoint", 404)
}

pub fn unauthorized() -> Response {
  error_resp("unauthorized", 401)
}

pub fn error_resp(error: String, code: Int) -> Response {
  model.Err(error)
  |> model.resp_body_to_string_tree()
  |> wisp.json_response(code)
}

pub fn with_json(
  req: Request,
  decoder: decode.Decoder(a),
  next: fn(a) -> Response,
) {
  use json <- wisp.require_json(req)
  let decoder_res = decode.run(json, decoder)

  with_decoding(decoder_res, next)
}

pub fn with_decoding(decoder_res: Result(a, b), next: fn(a) -> Response) {
  case decoder_res {
    Ok(decoded) -> next(decoded)
    Error(_) -> error_resp("invalid body content", 400)
  }
}

pub fn with_condition(
  condition: Bool,
  msg: String,
  next: fn() -> Response,
) -> Response {
  case condition {
    True -> next()
    False -> error_resp(msg, 400)
  }
}

pub fn with_query(query_res: Result(a, query.PGError), next: fn(a) -> Response) {
  case query_res {
    Ok(data) -> next(data)
    Error(e) ->
      case e {
        query.Internal(msg) -> {
          colors.print_red([msg])
          error_resp("internal server error", 500)
        }
        query.Public(msg, status) -> error_resp(msg, status)
      }
  }
}
