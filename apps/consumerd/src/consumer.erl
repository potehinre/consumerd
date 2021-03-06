-module(consumer).
-include("../../../deps/amqp_client/include/amqp_client.hrl").
-export([start_link/3,spawn_process/2,http_request/2,loop/4,init/3]).
-compile(debug_info).
-define(SLEEP_BEFORE_RETRY,1000).
-define(TIMEOUT,5000).

%%Поспать некоторый интервал времени и перезапустить скрипт
retry(Port, Name, Message) ->
    timer:sleep(?SLEEP_BEFORE_RETRY),
    port_close(Port),
    spawn_process(Name, Message).

%%Запускает питон скрипт и передает ему сообщение
spawn_process(Name, Message) ->
    Port = open_port({spawn,"python -u task/" ++ Name}, [{packet,4},binary, use_stdio]),
    ReqData = term_to_binary({msg, Message}), 
    port_command(Port, ReqData),
    receive
	    {Port, {data, Response}} ->
            case binary_to_term(Response) of
                ok ->  
                    port_close(Port),
                    ok;
                _  ->
                    retry(Port, Name, Message)
            end;
	    {'EXIT',Port, _Reason} ->
            io:format("Exited with reason ~p ~n",[_Reason]),
            timer:sleep(?SLEEP_BEFORE_RETRY),
            spawn_process(Name, Message)
    after ?TIMEOUT ->
        port_close(Port),
        spawn_process(Name, Message)
    end.

%%Выполняет http запрос по заданному URL и передаем ему cообщение Message постом
http_request(Url, Message) ->
    PostStr = "msg=" ++ binary_to_list(Message),
    {ok, RequestId} = httpc:request(post,{Url,[],"application/x-www-form-urlencoded", PostStr},
				   [],[{sync,false}]),
    receive
	{http, {RequestId, Result}} ->
	    case Result of
		    {error,_Reason} ->
		        timer:sleep(?SLEEP_BEFORE_RETRY),
		        http_request(Url, Message);
		    {_, _, <<"ok">>} ->
		        ok
	    end
    after ?TIMEOUT ->
	    http_request(Url, Message)
    end.

loop(Channel, ConsumerTag, TaskName, TaskFunction) ->
    receive
	#'basic.cancel_ok'{} ->
	    ok;
	{#'basic.deliver'{delivery_tag = Tag}, {amqp_msg, _Info, Message}} ->
	    io:format("Message Delivered: ~p ~n",[Message]),
	    ok = TaskFunction(TaskName, Message),
	    amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
        io:format("Message Acquired: ~p ~n",[Message]),
	    loop(Channel, ConsumerTag, TaskName, TaskFunction)
    end.

init(QueueName, TaskType, TaskName) ->
    process_flag(trap_exit,true),
    io:format("I Arised! ~p ~p ~n",[TaskType, TaskName]),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host="192.168.1.193",port=5672}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    try
        Sub = #'basic.consume'{queue = QueueName},
        #'basic.consume_ok'{consumer_tag = ConsumerTag} = amqp_channel:subscribe(Channel,Sub,self()),
        case TaskType of
	        http_request -> 
	            loop(Channel, ConsumerTag, TaskName, fun consumer:http_request/2);
	        spawn_process ->
	            loop(Channel, ConsumerTag, TaskName, fun consumer:spawn_process/2)
        end
    after
        amqp_channel:close(Channel),
        amqp_connection:close(Connection),
        ok
    end.

start_link(Queue, TaskType, TaskName) ->
    Pid = spawn_link(consumer, init,[Queue, TaskType, TaskName]),
    {ok, Pid, {Queue, TaskType, TaskName}}.

