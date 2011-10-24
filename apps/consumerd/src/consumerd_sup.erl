
-module(consumerd_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, { {one_for_one, 5, 10}, 
            [
             {process_worker,{consumer,start_link,[<<"markers-stat">>,spawn_process,"hello.py"]}, permanent, 5000, worker, [consumer]},
             {http_worker,{consumer,start_link,[<<"markers-pusher">>,http_request,"http://127.0.0.1:5000"]}, permanent, 5000, worker, [consumer]}
            ]
          }
     }.

