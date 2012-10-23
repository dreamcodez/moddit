-module(myapp_yaws_handler).

-include("/usr/local/lib/yaws/include/yaws_api.hrl").
-compile(export_all).

out(A) ->
  JobSpec = {{command, stylus}, {input, <<".foo\n  color blue">>}},
  JobRequest = lists:flatten(jsonerl:encode(JobSpec)),
  {ok, CSS} = worker:do_job({worker, 'worker@precise64'}, JobRequest),
  {content, "text/css", CSS}.

