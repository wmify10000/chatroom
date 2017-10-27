%%% simple chatroom program
-module(chatroom).

-compile(export_all).

-define(SERVER_IP, "localhost").
-define(SERVER_PORT, 1025).

-record(storage, {socklist = []}).

%% server
start_server() ->
	{ok, LSocket} = gen_tcp:listen(?SERVER_PORT, [binary, {packet, 0}, {active, true}]),
	spawn(fun() -> wait_new_connect(LSocket, #storage{}) end).

wait_new_connect(LSocket, Storage) ->
	{ok, Socket} = gen_tcp:accept(LSocket),
	SockList = Storage#storage.socklist,
	NewSockList = [Socket|SockList],
	NewStorage = Storage#storage{socklist=NewSockList},
	spawn(fun() -> wait_new_connect(LSocket, NewStorage) end),
	broadcast(NewSockList).

broadcast(SockList) ->
	receive
		{tcp, _Socket, Bin} ->
			io:format("Server recv: ~p~n", [binary_to_list(Bin)]),
			lists:foreach(fun(Sock) ->
				spawn(fun() -> gen_tcp:send(Sock, Bin) end)
			end, SockList),
			broadcast(SockList)
	end.


%% client
start_client() ->
	{ok, Socket} = gen_tcp:connect(?SERVER_IP, ?SERVER_PORT, [binary, {packet, 0}]),
	io:format("---Successfully entered the chatroom!---~n"),
	spawn(fun() -> print_msg(Socket) end),
	enter_msg(Socket),
	ok.

print_msg(Socket) ->
	receive
		{tcp, Socket, Bin} ->
			io:format("client recv: ~p~n", [binary_to_list(Bin)]),
			print_msg(Socket)
	end.

enter_msg(Socket) ->
	% {ok, [Input]} = io:fread("", "~s"),
	Input1 = io:get_line(""),
	Input = re:replace(Input1, "\n$", "", [{return, list}]),
	Packet = list_to_binary(Input),
	ok = gen_tcp:send(Socket, Packet),
	enter_msg(Socket).
