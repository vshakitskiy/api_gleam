import app/internal/ffi
import gleam/dynamic/decode
import gleam/json as j
import gwt

pub fn sign_jwt(id: Int, key: String, seconds_from_now: Int) -> String {
  gwt.new()
  |> gwt.set_issuer("api_gleam")
  |> gwt.set_subject("api_gleam_user")
  |> gwt.set_expiration(ffi.seconds() + seconds_from_now)
  |> gwt.set_issued_at(ffi.seconds())
  |> gwt.set_payload_claim("user_id", j.int(id))
  |> gwt.to_signed_string(gwt.HS256, key)
}

pub fn validate_jwt(token: String, key: String) -> Result(Int, String) {
  case gwt.from_signed_string(token, key) {
    Ok(jwt) -> {
      case gwt.get_payload_claim(jwt, "user_id", decode.int) {
        Ok(id) -> Ok(id)
        Error(_) -> Error("invalid token")
      }
    }
    Error(e) ->
      case e {
        gwt.TokenExpired -> Error("token expired")
        _ -> Error("invalid token")
      }
  }
}
