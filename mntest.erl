%%%-------------------------------------------------------------------
%%% Test für Mnesia
%%% @author friesen
%%% Created : 01. Sep 2015 18:23
%%%-------------------------------------------------------------------
-module(mntest).
-author("friesen").

%% API
-export([test/0,init/0,put/1,get/1,rentry/1,entry/1,close/0]).

-record(table1,{name, number, street, city, country, value}).

%% So gehts:
%% - Mehrere Erlang-Knoten starten (die bei init/0 in der Liste stehen)
%% - Auf Knoten n0 init().
%% - schreibtest mit put(2000000).
%% - lesetest (auf anderem Knoten) mit get(123456).
%% - zum sauberen beenden auf n0: close().
%% Abgeschossene Knoten mit
%%     net_kernel:connect_node('n0@roots-MacBook-Pro'), mnesia:start().
%% wieder starten
%% TODO 'localhost' statt roots-MacBook-Pro
%%      API für einfaches schreiben


init() -> [net_kernel:connect_node(list_to_atom(X++"@roots-MacBook-Pro"))||X <- ["n1","n2","n3","n4"]],
          Nodes=[node()|nodes()],
          mnesia:create_schema(Nodes),
          %mnesia:start(),
          rpc:multicall(Nodes, application, start, [mnesia]),
          mnesia:create_table(table1,[{attributes,record_info(fields,table1)},{ram_copies, nodes()}]).
%init(_) -> net_kernel:connect_node('n0@roots-MacBook-Pro').

close() -> rpc:multicall([node()|nodes()], application, stop, [mnesia]).

put(0) -> ok;
put(N) -> mnesia:transaction(fun() -> mnesia:write(rentry(N)) end), put(N-1).

get(N) -> mnesia:activity(transaction,fun() -> mnesia:read({table1,"horst"++integer_to_list(N)})end).
%mnesia:activity(transaction,fun() -> mnesia:read({table1,"horst123456"})end).

rentry(N) -> #table1{name="horst"++integer_to_list(N),
  number=N,
  street=integer_to_list(N)++"street",
  city="city"++integer_to_list(N*2),
  country=integer_to_list(N)++"th country",
  value=N*119}.

entry(N) -> {
  {name,"horst"++integer_to_list(N)},
  {number,N},
  {street,integer_to_list(N)++"street"},
  {city,"city"++integer_to_list(N*2)},
  {country,integer_to_list(N)++"th country"},
  {value,N*119}
}.