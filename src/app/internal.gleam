import gleam/io
import gleam/string

const reset_color = "\u{001b}[0m"

pub fn print_green(text: List(String)) {
  print_color(text, "\u{001b}[38;5;2m")
}

pub fn print_blue(text: List(String)) {
  print_color(text, "\u{001b}[38;5;12m")
}

pub fn print_red(text: List(String)) {
  print_color(text, "\u{001b}[38;5;9m")
}

fn print_color(text: List(String), start_color: String) {
  string.concat([start_color, string.join(text, ""), reset_color])
  |> io.println()
}

@external(erlang, "exit_ffi", "do_exit")
pub fn exit(exit_code: Int) -> Nil
