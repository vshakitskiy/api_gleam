import app/context.{type Context}
import app/db/query/user
import app/model
import app/web
import gleam/int
import gleam/json
import radish
import wisp.{type Response}

pub fn get_user_by_id(id: Int, c: Context, next: fn(model.User) -> Response) {
  case radish.get(c.redis, "user:" <> int.to_string(id), c.timeout_ms) {
    Ok(user_json) -> {
      let user = json.parse(user_json, model.from_json_user_decoder())
      use user <- web.with_decoding(user)
      next(user)
    }
    Error(_) -> {
      let query_res = user.get_user_by_id(id, c.conn)
      use user <- web.with_decoding(query_res)
      next(user)
    }
  }
}

pub fn get_user_by_email(
  email: String,
  c: Context,
  next: fn(model.User) -> Response,
) {
  case radish.get(c.redis, "user:" <> email, c.timeout_ms) {
    Ok(user_json) -> {
      let user = json.parse(user_json, model.from_json_user_decoder())
      use user <- web.with_decoding(user)
      next(user)
    }
    Error(_) -> {
      let query_res = user.get_user_by_email(email, c.conn)
      use user <- web.with_decoding(query_res)
      next(user)
    }
  }
}
