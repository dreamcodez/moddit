-module(loadtest).
-export([start/0]).

start() ->
  loop(800).
  %loop(1).

loop(Times) when Times >= 0 ->
  case Times > 0 of
    true ->
      {ok, Output} = worker:do_job(
        {worker, 'worker@precise64'},
        "{\"command\": \"stylus\", \"input\": \".foo\\n  color blue\"}"),
      erlang:display(Output),
      loop(Times - 1);
    false ->
      receive
        Other ->
          erlang:display(Other),
          loop(0)
      after 10000 ->
        done
      end
  end.

