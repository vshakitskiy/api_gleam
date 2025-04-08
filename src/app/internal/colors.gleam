import gleam/io
import gleam/string

const reset_color = "\u{001b}[0m"

pub fn print_green(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;2m")
}

pub fn print_blue(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;12m")
}

pub fn print_red(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;9m")
}

pub fn print_orange(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;58m")
}

pub fn print_yellow(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;11m")
}

pub fn print_white(text: List(String)) -> Nil {
  print_color(text, "\u{001b}[38;5;15m")
}

fn print_color(text: List(String), start_color: String) -> Nil {
  color_text(text, start_color)
  |> io.println()
}

pub fn color_green(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;2m")
}

pub fn color_blue(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;12m")
}

pub fn color_red(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;9m")
}

pub fn color_orange(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;58m")
}

pub fn color_yellow(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;11m")
}

pub fn color_white(text: List(String)) -> String {
  color_text(text, "\u{001b}[38;5;15m")
}

fn color_text(text: List(String), start_color: String) -> String {
  string.concat([start_color, string.join(text, ""), reset_color])
}
