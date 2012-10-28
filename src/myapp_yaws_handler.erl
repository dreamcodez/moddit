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

etag_header(Str) ->
  ETag = bin_to_hexstr(crypto:hash(sha, Str)),
  {header, "ETag: " ++ ETag}.

out(A) ->
  Method = A#arg.req#http_request.method,
  Path = A#arg.server_path,
  Query = A#arg.querydata,
  handle(Method, Path, Query).
  
handle('GET', "/", undefined) ->
  {ok, HTML} = jade({file, "jade/homepage.jade"}),
  RespHeaders = [etag_header(HTML), {header, "Cache-Control: max-age=30"}],
  [{allheaders, RespHeaders}, {content, "text/html", HTML}];

handle('GET', "/homepage.css", undefined) ->
  {ok, CSS} = stylus({file, "styl/homepage.styl"}),
  RespHeaders = [etag_header(CSS), {header, "Cache-Control: max-age=30"}],
  [{allheaders, RespHeaders}, {content, "text/css", CSS}];

handle(_, _, _) ->
  [{html, "404"}, {status, 404}].

