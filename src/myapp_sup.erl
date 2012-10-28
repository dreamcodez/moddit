
-module(myapp_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  Worker1 = {worker1, {worker, start_link, [worker1, './worker.ls', 16000]}, permanent, 5000, worker, [worker]},
  {ok, {{one_for_one, 5, 10}, [Worker1]}}.

