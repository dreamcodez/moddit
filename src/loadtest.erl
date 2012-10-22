-module(loadtest).
-export([start/0]).

start() ->
  loop(1000).
  %loop(1).

loop(Times) when Times >= 0 ->
  case Times > 0 of
    true ->
      {worker, 'worker@precise64'} ! {self(), job_request, "{\"command\": \"stylus\", \"input\": \".foo\\n  color blue\"}"},
      loop(Times - 1);
    false ->
      done
  end.

