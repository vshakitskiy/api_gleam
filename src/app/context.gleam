import pog
import radish
import wisp.{type Request}

pub type Context {
  Context(
    conn: pog.Connection,
    req: Request,
    path: List(String),
    jwt_key: String,
    redis: radish.Client,
    timeout_ms: Int,
  )
}

pub fn new_contex(
  conn: pog.Connection,
  req: Request,
  jwt_key: String,
  redis: radish.Client,
  timeout_ms: Int,
) -> Context {
  Context(conn:, req:, path: [], jwt_key:, redis:, timeout_ms:)
}
