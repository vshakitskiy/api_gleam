-module(exit_ffi).
-export([do_exit/1]).

do_exit(Code) ->
  halt(Code).