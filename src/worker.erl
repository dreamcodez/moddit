-module(worker).
-export([start_link/0]).

start_link() ->
  Pid = spawn_link(fun run/0),
  true = register(worker, Pid),
  {ok, Pid}.

run() ->
  %run("./worker.pl", 5000).
  run("./worker.js", 16000).

run (Cmd, Timeout) ->
  Port = erlang:open_port({spawn_executable, Cmd}, [exit_status]),
  [_,_,_,_,_,_,{os_pid,Pid}] = erlang:port_info(Port),
  erlang:display("worker starter as pid #" ++ integer_to_list(Pid)),
  port_command(Port, "56:2 {\"command\": \"stylus\", \"input\": \"#foo { color: blue }\"}"),
  loop(Port, "", Timeout).

loop(Port, OldStream, Timeout) ->
  receive
    {Port, {data, NewStream}} ->
      Stream = OldStream++NewStream,
      {Messages, AdjStream} = parse_netstrings(Stream),
      case length(Messages) > 0 of
        true ->
          erlang:display({messages, Messages}),
          loop(Port, AdjStream, Timeout);
        false ->
          loop(Port, AdjStream, Timeout)
      end;
    {Port, {exit_status, _}} ->
      throw(worker_exit);
    Other ->
      erlang:display(Other)
  after Timeout ->
    port_close(Port),
    throw(timeout)
  end.

parse_netstrings(Stream) when is_list(Stream) ->
  rparse_netstrings("", Stream, []).

rparse_netstrings(LenStr, Stream, Strings) ->
  StreamLen = length(Stream),
  case StreamLen > 0 of
    true ->
      [Head | Tail] = Stream,
      case [Head] == ":" of
        true ->
          {Len, []} = string:to_integer(LenStr),
          TailLen = string:len(Tail),
          case Len =< TailLen of
            true ->
              Str = string:substr(Tail, 1, Len),
              case (TailLen - Len) > 0 of
                true ->
                  StreamLeft = string:substr(Tail, Len + 1),
                  rparse_netstrings("", StreamLeft, Strings ++ [Str]);
                false ->
                  {Strings ++ [Str], ""}
              end;
            false ->
              {Strings, Stream}
          end;
        false ->
          rparse_netstrings(LenStr ++ [Head], Tail, Strings)
      end;
    false ->
      {Strings, Stream}
  end.

