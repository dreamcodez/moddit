-module(loadtest).
-export([start/0]).

start() ->
  loop(800).
  %loop(1).

loop(Times) when Times >= 0 ->
  case Times > 0 of
    true ->
      {worker, 'worker@precise64'} ! {self(), job_request, "{\"command\": \"stylus\", \"input\": \".foo\\n  color blue\"}"},
      loop(Times - 1);
    false ->
      %done
      receive
        Other ->
          erlang:display(Other),
          loop(0)
      after 10000 ->
        done
      end
  end.

