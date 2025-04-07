import decode/zero as z
import gleam/dynamic

pub type User {
  User(id: Int, username: String, email: String, password_hash: String)
}

pub fn from_db(dynamic: dynamic.Dynamic) {
  let decoder = {
    use id <- z.field("username", z.int)
    use username <- z.field("username", z.string)
    use email <- z.field("email", z.string)
    use password_hash <- z.field("password_hash", z.string)
    z.success(User(id:, username:, email:, password_hash:))
  }

  z.run(dynamic, decoder)
}
