import gleam/int
import gleam/string
import pog.{type QueryError}

pub type PGError {
  Internal(msg: String)
  Public(msg: String, code: Int)
}

pub fn with_formatted_error(
  pg_res: Result(a, QueryError),
  next: fn(Result(a, PGError)) -> b,
) -> b {
  case pg_res {
    Ok(pg_data) -> next(Ok(pg_data))
    Error(pg_error) -> {
      let msg = case pg_error {
        pog.ConstraintViolated(msg, constr, dtl) -> {
          case string.contains(dtl, "already exists") {
            True -> Error(Public("already exists", 409))
            False ->
              Error(Internal(
                "constraint " <> constr <> " violated: " <> dtl <> "\n" <> msg,
              ))
          }
        }
        pog.PostgresqlError(code, name, msg) ->
          Error(Internal(
            "postgresql error " <> code <> " (" <> name <> "): " <> msg,
          ))
        pog.UnexpectedArgumentCount(expected, got) ->
          Error(Internal(
            "unexpected argument count: expected "
            <> int.to_string(expected)
            <> ", got "
            <> int.to_string(got),
          ))
        pog.UnexpectedArgumentType(expected, got) ->
          Error(Internal(
            "unexpected argument type: expected " <> expected <> ", got " <> got,
          ))
        pog.UnexpectedResultType(l) -> {
          echo l
          Error(Internal("unexpected result type"))
        }
        pog.QueryTimeout -> Error(Internal("query timeout"))
        pog.ConnectionUnavailable -> Error(Internal("database is unavailable"))
      }
      next(msg)
    }
  }
}
