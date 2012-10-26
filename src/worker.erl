-module(worker).
-export([start_link/3, do_job/2]).

% worker should send heartbeats within the timeout window
% the heartbeat frame the worker needs to send is '2:hb' or if you have
% a routine which applies the netstring then just 'hb'
% this is just a liveness test
%
% if this  erlang process dies then the underlying os process wil get a sigpipe
% so the worker needs to handle sigpipe to gracefully die
start_link(RegisterAs, Command, Timeout) when is_atom(RegisterAs) ->
  StartWorker = fun() -> run(Command, Timeout) end,
  Pid = spawn_link(StartWorker),
  true = register(RegisterAs, Pid),
  {ok, Pid}.

run(Cmd, Timeout) ->
  Port = erlang:open_port({spawn_executable, Cmd}, [exit_status]),
  [_,_,_,_,_,_,{os_pid,Pid}] = erlang:port_info(Port),
  erlang:display("worker starter as pid #" ++ integer_to_list(Pid)),
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

do_job(Worker, JobRequest) ->
  Worker ! {self(), job_request, JobRequest},
  receive
    {_WorkerPid, job_response, JobResponse} ->
      {ok, JobResponse};
    {_WorkerPid, job_error, JobError} ->
      {error, JobError}
  end.

loop(Port, Stream, Timeout, JobId) when is_port(Port) ->
  receive
    {Port, {data, NewStream}} ->
      {Messages, AdjStream} = parse_netstrings(Stream++NewStream),
      case length(Messages) > 0 of
        true ->
          % process table for jobid -> pid mapping
          HandleMessage =
            fun(Frame) ->
              case parse_response_frame(Frame) of
                heartbeat -> do_nothing;
                {MsgJobId, ErrCode, Msg} ->
                  Pid = erase({pid_by_jobid, MsgJobId}),
                  case ErrCode of
                    0 ->
                      Pid ! {self(), job_response, Msg};
                    _ ->
                      Pid ! {self(), job_error, Msg}
                  end
              end
            end,
          lists:map(HandleMessage, Messages),
          loop(Port, AdjStream, Timeout, JobId);
        false ->
          loop(Port, AdjStream, Timeout, JobId)
      end;
    {Port, {exit_status, _}} ->
      throw(worker_exit);
    {Pid, job_request, Msg} when is_pid(Pid) ->
      undefined = put({pid_by_jobid , JobId}, Pid),
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

