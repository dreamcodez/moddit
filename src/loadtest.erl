-module(loadtest).
-export([start/0]).

start() ->
  spawn(fun() -> loop(100, []) end),
  spawn(fun() -> loop(100, []) end),
  spawn(fun() -> loop(100, []) end),
  spawn(fun() -> loop(100, []) end),
  loop(1000, []).

now_micro() ->
  {Mega,Secs,Micro} = now(),
  (Mega * 1000000 + Secs) * 1000000 + Micro.

average(List) when is_list(List) ->
  lists:sum(List) / length(List).

loop(Times, Durations) when Times >= 0 ->
  case Times > 0 of
    true ->
      Before = now_micro(),
      {ok, Output} = worker:do_job(
        {worker, 'worker@precise64'},
        "{\"command\": \"stylus\", \"input\": \".foo\\n  color blue\"}"),
      After = now_micro(),
      DurationMs = (After - Before) / 1000,
      erlang:display({output, Output, jobtime_ms, DurationMs}),
      loop(Times - 1, Durations ++ [DurationMs]);
    false ->
      receive
        Other ->
          erlang:display(Other),
          loop(0, Durations)
      after 10000 ->
        [Min] = io_lib:format("~.2f", [lists:min(Durations)]),
        [Max] = io_lib:format("~.2f", [lists:max(Durations)]),
        [Avg] = io_lib:format("~.2f", [average(Durations)]),
        erlang:display({jobtime_ms_totals, {min, Min, max, Max, avg, Avg}})
      end
  end.

