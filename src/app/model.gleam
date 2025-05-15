import gleam/dynamic/decode
import gleam/json as j
import gleam/string_tree.{type StringTree}

pub type User {
  User(id: Int, username: String, email: String, password_hash: String)
}

pub fn from_db_user_decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use email <- decode.field(2, decode.string)
  use password_hash <- decode.field(3, decode.string)
  decode.success(User(id:, username:, email:, password_hash:))
}

pub fn from_json_user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use password_hash <- decode.field("password_hash", decode.string)
  decode.success(User(id:, username:, email:, password_hash:))
}

pub fn user_id_decoder() -> decode.Decoder(Int) {
  use id <- decode.field(0, decode.int)
  decode.success(id)
}

pub fn user_to_json(user: User) -> j.Json {
  j.object([
    #("id", j.int(user.id)),
    #("username", j.string(user.username)),
    #("email", j.string(user.email)),
    #("password_hash", j.string(user.password_hash)),
  ])
}

pub type JSON {
  Err(error: String)
  Message(message: String)
  Data(data: j.Json, message: String)
}

pub fn resp_body_to_string_tree(json: JSON) -> StringTree {
  case json {
    Err(err) -> j.object([#("error", j.string(err))]) |> j.to_string_tree()
    Message(message) ->
      j.object([#("message", j.string(message))]) |> j.to_string_tree()
    Data(data, message) ->
      j.object([#("message", j.string(message)), #("data", data)])
      |> j.to_string_tree()
  }
}
