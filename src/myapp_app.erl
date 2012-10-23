-module(myapp_app).

-behaviour(application).

%% Application callbacks
-export([shell/0, start/0, start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

shell() ->
  {ok, Pid} = myapp_sup:start_link(),
  true = unlink(Pid),
  {ok, Pid}.

start() ->
  myapp_sup:start_link().

start(_StartType, _StartArgs) ->
  start().

stop(_State) ->
  ok.

