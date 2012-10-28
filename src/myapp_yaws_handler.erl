-module(myapp_yaws_handler).

-include("/usr/local/lib/yaws/include/yaws_api.hrl").
-compile(export_all).

bin_to_hexstr(Bin) ->
  lists:flatten([io_lib:format("~2.16.0b", [X]) ||
    X <- binary_to_list(Bin)]).

% valid render types are the atoms 'input' or 'file'
render({Engine, Type, Target}) when is_list(Engine); is_atom(Type) ->
  JobSpec = {struct, [{command, Engine}, {Type, Target}]},
  JobRequest = lists:flatten(json2:encode(JobSpec)),
  worker:do_job({worker1, 'worker@precise64'}, JobRequest).

% shortcut for jade
jade({Type, Target}) ->
  render({"jade", Type, Target}).

% shortcut for stylus 
stylus({Type, Target}) ->
  render({"stylus", Type, Target}).

out(_A) ->
  {ok, CSS} = stylus({file, "styl/homepage.styl"}),
  {ok, HTML} = jade({file, "jade/homepage.jade"}),
  ETag = bin_to_hexstr(crypto:hash(sha, CSS)),
  RespHeaders = [{header, "ETag: " ++ ETag}
                ,{header, "Cache-Control: max-age=30"}
                ],
  [{allheaders, RespHeaders}, {content, "text/html", HTML}].

