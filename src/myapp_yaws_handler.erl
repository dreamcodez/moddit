-module(myapp_yaws_handler).

-include("/usr/local/lib/yaws/include/yaws_api.hrl").
-compile(export_all).

bin_to_hexstr(Bin) ->
  lists:flatten([io_lib:format("~2.16.0b", [X]) ||
    X <- binary_to_list(Bin)]).

out(A) ->
  JobSpec = {{command, stylus}, {input, <<".foo\n  color blue">>}},
  JobRequest = lists:flatten(jsonerl:encode(JobSpec)),
  {ok, CSS} = worker:do_job({worker, 'worker@precise64'}, JobRequest),
  ETag = bin_to_hexstr(crypto:hash(sha, CSS)),
  RespHeaders = [{header, "ETag: " ++ ETag}],
  [{allheaders, RespHeaders}, {content, "text/css", CSS}].

