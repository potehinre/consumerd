-module(consumer).
%%-include_lib("../../../deps/rabbit_common/include/rabbit.hrl").
%%-include_lib("../../../deps/rabbit_common/include/rabbit_framing.hrl").
-include("../../../deps/amqp_client/include/amqp_client.hrl").
-compile([export_all]).

spawn_process(Name, Message) ->
    Port = open_port({spawn,"python -u task/" ++ Name},
		     [{packet, 1}, binary, use_stdio]),
    ReqData = term_to_binary({msg, Message}), 
    port_command(Port, ReqData),
    receive
	    {Port, {data, _RespData}} ->
	        ok;
	    {'EXIT',Port, _Reason} ->
	        spawn_process(Name, Message)
    end.

http_request(Url, Message) ->
    PostStr = "msg=" ++ binary_to_list(Message),
    {ok, RequestId} = httpc:request(post,{Url,[],"application/x-www-form-urlencoded", PostStr},
				   [],[{sync,false}]),
    receive
	{http, {RequestId, Result}} ->
	    case Result of
		    {error,_Reason} ->
		        timer:sleep(2000),
		        http_request(Url, Message);
		    {_, _, <<"ok">>} ->
		        ok
	    end
    after 5000 ->
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
    io:format("I Arised ~p ~p ~n",[QueueName,TaskName]),
    inets:start(),
    process_flag(trap_exit,true),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host="192.168.1.193",port=5672}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    Sub = #'basic.consume'{queue = QueueName},
    #'basic.consume_ok'{consumer_tag = ConsumerTag} = amqp_channel:subscribe(Channel,Sub,self()),
    case TaskType of
	    http_request -> 
	        loop(Channel, ConsumerTag, TaskName, fun consumer:http_request/2);
	    spawn_process ->
	        loop(Channel, ConsumerTag, TaskName, fun consumer:spawn_process/2)
    end,
    amqp_channel:close(Channel),
    amqp_connection:close(Connection),
    ok.

start_link(Queue, TaskType, TaskName) ->
    Pid = spawn_link(consumer, init,[Queue, TaskType, TaskName]),
    {ok, Pid, {Queue, TaskType, TaskName}}.

