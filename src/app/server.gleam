import app/internal/colors.{print_blue, print_green, print_red}
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn start_server(
  handler: fn(Request) -> Response,
  port: Int,
  secret: String,
) -> Nil {
  print_blue(["\nStarting server..."])

  let start_result =
    wisp_mist.handler(handler, secret)
    |> mist.new()
    |> mist.port(port)
    |> mist.bind("0.0.0.0")
    |> mist.after_start(fn(port, schema, ip) {
      print_green([
        "Listening on ",
        http.scheme_to_string(schema),
        "://",
        mist.ip_address_to_string(ip),
        ":",
        int.to_string(port),
        "\n",
      ])
    })
    |> mist.start_http()

  case start_result {
    Ok(_) -> process.sleep_forever()
    Error(e) -> {
      print_red(["Failed to start server\n"])

      echo e
      io.println("")
    }
  }
}
