-module(consumerd_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).
-record(workers,
	{queue_name,
	 task_type,
	 task_name,
	 count}).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Config = [#workers{queue_name = <<"markers-stat">>, task_type = spawn_process, task_name = "hello.py", count = 4}],
    {ok, SupPid} = consumerd_sup:start_link(),
    inets:start(),
    start_workers(SupPid,Config),
    {ok, SupPid}.

%% Принимает на вход конфиг сколько рабочих для каждой очереди запускать и последовательно запускает 
start_workers(SupPid, Config) ->
    lists:map(fun (Element) -> 
		     Count = Element#workers.count,
		     QueueWorkerConfig = {Element#workers.queue_name, Element#workers.task_type, Element#workers.task_name},
		     start_queue_workers(SupPid, QueueWorkerConfig, Count)
	     end,
	     Config).

%% Запускает указанное в Count рабочих на очередь
start_queue_workers(SupPid, QueueWorkerConfig, Count) ->
    case Count of
	0 -> ok;
	Count -> 
	    {QueueName, TaskType, TaskName} = QueueWorkerConfig,
	    supervisor:start_child(SupPid, [QueueName, TaskType, TaskName]),
	    start_queue_workers(SupPid, QueueWorkerConfig, Count - 1)
    end.

stop(_State) ->
    ok.
