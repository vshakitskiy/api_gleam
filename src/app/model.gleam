import gleam/dynamic/decode

pub type User {
  User(id: Int, username: String, email: String, password_hash: String)
}

pub fn db_user_decoder() {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use email <- decode.field(2, decode.string)
  use password_hash <- decode.field(3, decode.string)
  decode.success(User(id:, username:, email:, password_hash:))
}

pub fn db_user_id_decoder() {
  use id <- decode.field(0, decode.int)
  decode.success(id)
}
