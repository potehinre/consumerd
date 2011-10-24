{application,consumerd,
             [{description,"Consumes to RabbitMQ Queues and distribute tasks"},
              {vsn,"1"},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{consumerd_app,[]}},
              {env,[]},
              {modules,[consumer,consumerd_app,consumerd_sup]}]}.
