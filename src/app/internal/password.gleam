import argus

pub fn hash_password(password: String) -> String {
  let assert Ok(hashes) =
    argus.hasher()
    |> argus.algorithm(argus.Argon2id)
    |> argus.time_cost(5)
    |> argus.memory_cost(12_228)
    |> argus.parallelism(1)
    |> argus.hash_length(48)
    |> argus.hash(password, argus.gen_salt())

  hashes.encoded_hash
}

pub fn verify_password(hash: String, actual: String) -> Bool {
  case argus.verify(hash, actual) {
    Ok(boolean) -> boolean
    Error(_) -> False
  }
}
