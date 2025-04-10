-module(ffi).
-export([do_exit/1, milliseconds/0, seconds/0]).

do_exit(Code) ->
  halt(Code).

milliseconds() ->
  erlang:system_time(millisecond).

seconds() ->
  erlang:system_time(second).