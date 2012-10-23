-module(worker).
-export([start_link/0, do_job/1]).

start_link() ->
  Pid = spawn_link(fun run/0),
  true = register(worker, Pid),
  {ok, Pid}.

run() ->
  %run("./worker.pl", 5000).
  run("./worker.js", 16000).

run(Cmd, Timeout) ->
  Port = erlang:open_port({spawn_executable, Cmd}, [exit_status]),
  [_,_,_,_,_,_,{os_pid,Pid}] = erlang:port_info(Port),
  erlang:display("worker starter as pid #" ++ integer_to_list(Pid)),
  true = port_command(Port, "56:2 {\"command\": \"stylus\", \"input\": \"#foo { color: blue }\"}"),
  loop(Port, "", Timeout, 1).

parse_response_frame(Frame) ->
  case Frame of
    "hb" ->
      heartbeat;
    Frame ->
      Raw = string:tokens(Frame, " "),
      JobId = list_to_integer(lists:nth(1, Raw)),
      ErrCode = list_to_integer(lists:nth(2, Raw)),
      Msg = string:join(lists:nthtail(2, Raw), " "),
      {JobId, ErrCode, Msg}
  end.

do_job(JobRequest) ->
  stub.

loop(Port, Stream, Timeout, JobId) when is_port(Port) ->
  receive
    {Port, {data, NewStream}} ->
      {Messages, AdjStream} = parse_netstrings(Stream++NewStream),
      case length(Messages) > 0 of
        true ->
          % process table for jobid -> pid mapping
          HandleMessage =
            fun(Msg) ->
              JobRes = parse_response_frame(Msg),
              erlang:display(JobRes)
            end,
          lists:map(HandleMessage, Messages),
          loop(Port, AdjStream, Timeout, JobId);
        false ->
          loop(Port, AdjStream, Timeout, JobId)
      end;
    {Port, {exit_status, _}} ->
      throw(worker_exit);
    {Pid, job_request, Msg} when is_pid(Pid) ->
      Frame = integer_to_list(JobId) ++ " " ++ Msg,
      NetString = integer_to_list(length(Frame)) ++ ":" ++ Frame,
      true = port_command(Port, NetString),
      loop(Port, Stream, Timeout, JobId + 1);
    shutdown ->
      throw(shutdown)
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
          Len = list_to_integer(LenStr),
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

