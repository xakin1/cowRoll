-file("/home/xaquin/.asdf/installs/erlang/26.1/lib/parsetools-2.5/include/leexinc.hrl", 0).
%% The source of this file is part of leex distribution, as such it
%% has the same Copyright as the other files in the leex
%% distribution. The Copyright is defined in the accompanying file
%% COPYRIGHT. However, the resultant scanner generated by leex is the
%% property of the creator of the scanner and is not covered by that
%% Copyright.

-module(lexical_analysis).

-export([string/1,string/2,token/2,token/3,tokens/2,tokens/3]).
-export([format_error/1]).

%% User code. This is placed here to allow extra attributes.
-file("src/lexer/lexical_analysis.xrl", 51).

to_string(TokenChars) ->

    % Convierte la lista de caracteres en una cadena de texto binario
    TokenString = binary:list_to_bin(TokenChars),

    TokenString.
-file("/home/xaquin/.asdf/installs/erlang/26.1/lib/parsetools-2.5/include/leexinc.hrl", 14).

format_error({illegal,S}) -> ["illegal characters ",io_lib:write_string(S)];
format_error({user,S}) -> S.

%% string(InChars) ->
%% string(InChars, Loc) ->
%% {ok,Tokens,EndLoc} | {error,ErrorInfo,EndLoc}.
%% Loc is the starting location of the token, while EndLoc is the first not scanned
%% location. Location is either Line or {Line,Column}, depending on the "error_location" option.

string(Ics) -> 
    string(Ics,1).
string(Ics,L0) -> 
    string(Ics, L0, 1, Ics, []).
string(Ics, L0, C0, Tcs, Ts) -> 
    case do_string(Ics, L0, C0, Tcs, Ts) of
        {ok, T, {L,_}} -> {ok, T, L};
        {error, {{EL,_},M,D}, {L,_}} ->
            EI = {EL,M,D},
            {error, EI, L}
    end.

do_string([], L, C, [], Ts) ->                     % No partial tokens!
    {ok,yyrev(Ts),{L,C}};
do_string(Ics0, L0, C0, Tcs, Ts) ->
    case yystate(yystate(), Ics0, L0, C0, 0, reject, 0) of
        {A,Alen,Ics1,L1,_C1} ->                  % Accepting end state
            C2 = adjust_col(Tcs, Alen, C0),
            string_cont(Ics1, L1, C2, yyaction(A, Alen, Tcs, L0, C0), Ts);
        {A,Alen,Ics1,L1,_C1,_S1} ->              % Accepting transition state
            C2 = adjust_col(Tcs, Alen, C0),
            string_cont(Ics1, L1, C2, yyaction(A, Alen, Tcs, L0, C0), Ts);
        {reject,_Alen,Tlen,_Ics1,_L1,_C1,_S1} ->  % After a non-accepting state
            {error,{{L0, C0} ,?MODULE,{illegal,yypre(Tcs, Tlen+1)}},{L0, C0}};
        {A,Alen,Tlen,_Ics1,L1, C1,_S1}->
            Tcs1 = yysuf(Tcs, Alen),
            L2 = adjust_line(Tlen, Alen, Tcs1, L1),
            C2 = adjust_col(Tcs, Alen, C1),
            string_cont(Tcs1, L2, C2, yyaction(A, Alen, Tcs, L0,C0), Ts)
    end.

%% string_cont(RestChars, Line, Col, Token, Tokens)
%% Test for and remove the end token wrapper. Push back characters
%% are prepended to RestChars.

-dialyzer({nowarn_function, string_cont/5}).

string_cont(Rest, Line, Col, {token,T}, Ts) ->
    do_string(Rest, Line, Col, Rest, [T|Ts]);
string_cont(Rest, Line, Col, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    do_string(NewRest, Line, Col, NewRest, [T|Ts]);
string_cont(Rest, Line, Col, {end_token,T}, Ts) ->
    do_string(Rest, Line, Col, Rest, [T|Ts]);
string_cont(Rest, Line, Col, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    do_string(NewRest, Line, Col, NewRest, [T|Ts]);
string_cont(Rest, Line, Col, skip_token, Ts) ->
    do_string(Rest, Line, Col, Rest, Ts);
string_cont(Rest, Line, Col, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    do_string(NewRest, Line, Col, NewRest, Ts);
string_cont(_Rest, Line, Col, {error,S}, _Ts) ->
    {error,{{Line, Col},?MODULE,{user,S}},{Line,Col}}.

%% token(Continuation, Chars) ->
%% token(Continuation, Chars, Loc) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {token,State,CurrLine,CurrCol,TokenChars,TokenLen,TokenLine,TokenCol,AccAction,AccLen}

token(Cont,Chars) -> 
    token(Cont,Chars,1).
token(Cont, Chars, Line) -> 
    case do_token(Cont,Chars,Line,1) of
        {more, _} = C -> C;
        {done, Ret0, R} ->
            Ret1 = case Ret0 of
                {ok, T, {L,_}} -> {ok, T, L};
                {eof, {L,_}} -> {eof, L};
                {error, {{EL,_},M,D},{L,_}} -> {error, {EL,M,D},L}
            end,
            {done, Ret1, R}
    end.

do_token([], Chars, Line, Col) ->
    token(yystate(), Chars, Line, Col, Chars, 0, Line, Col, reject, 0);
do_token({token,State,Line,Col,Tcs,Tlen,Tline,Tcol,Action,Alen}, Chars, _, _) ->
    token(State, Chars, Line, Col, Tcs ++ Chars, Tlen, Tline, Tcol, Action, Alen).

%% token(State, InChars, Line, Col, TokenChars, TokenLen, TokenLine, TokenCol
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% The argument order is chosen to be more efficient.

token(S0, Ics0, L0, C0, Tcs, Tlen0, Tline, Tcol, A0, Alen0) ->
    case yystate(S0, Ics0, L0, C0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1,C1} ->
            C2 = adjust_col(Tcs, Alen1, C1),
            token_cont(Ics1, L1, C2, yyaction(A1, Alen1, Tcs, Tline,Tcol));
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,C1,S1} ->                  % Need more chars to check
            {more,{token,S1,L1,C1,Tcs,Alen1,Tline,Tcol,A1,Alen1}};
        {A1,Alen1,Ics1,L1,C1,_S1} ->               % Take what we got
            C2 = adjust_col(Tcs, Alen1, C1),
            token_cont(Ics1, L1, C2, yyaction(A1, Alen1, Tcs, Tline,Tcol));
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,C1,S1} ->            % Need more chars to check
            {more,{token,S1,L1,C1,Tcs,Tlen1,Tline,Tcol,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,C1,_S1} ->     % No token match
            %% Check for partial token which is error.
            Ret = if Tlen1 > 0 -> {error,{{Tline,Tcol},?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},{L1,C1}};
                     true -> {eof,{L1,C1}}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,Ics1,_L1,_C1,_S1} ->    % No token match
            Error = {{Tline,Tcol},?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            {done,{error,Error,{Tline,Tcol}},Ics1};
        {A1,Alen1,Tlen1,_Ics1,L1,_C1,_S1} ->       % Use last accept match
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            C2 = C0 + Alen1,
            token_cont(Tcs1, L2, C2, yyaction(A1, Alen1, Tcs, Tline, Tcol))
    end.

%% token_cont(RestChars, Line, Col, Token)
%% If we have a token or error then return done, else if we have a
%% skip_token then continue.

-dialyzer({nowarn_function, token_cont/4}).

token_cont(Rest, Line, Col, {token,T}) ->
    {done,{ok,T,{Line,Col}},Rest};
token_cont(Rest, Line, Col, {token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,{Line,Col}},NewRest};
token_cont(Rest, Line, Col, {end_token,T}) ->
    {done,{ok,T,{Line,Col}},Rest};
token_cont(Rest, Line, Col, {end_token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,{Line,Col}},NewRest};
token_cont(Rest, Line, Col, skip_token) ->
    token(yystate(), Rest, Line, Col, Rest, 0, Line, Col, reject, 0);
token_cont(Rest, Line, Col, {skip_token,Push}) ->
    NewRest = Push ++ Rest,
    token(yystate(), NewRest, Line, Col, NewRest, 0, Line, Col, reject, 0);
token_cont(Rest, Line, Col, {error,S}) ->
    {done,{error,{{Line, Col},?MODULE,{user,S}},{Line, Col}},Rest}.

%% tokens(Continuation, Chars) ->
%% tokens(Continuation, Chars, Loc) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {tokens,State,CurrLine,CurrCol,TokenChars,TokenLen,TokenLine,TokenCur,Tokens,AccAction,AccLen}
%% {skip_tokens,State,CurrLine,CurrCol,TokenChars,TokenLen,TokenLine,TokenCur,Error,AccAction,AccLen}

tokens(Cont,Chars) -> 
    tokens(Cont,Chars,1).
tokens(Cont, Chars, Line) -> 
    case do_tokens(Cont,Chars,Line,1) of
        {more, _} = C -> C;
        {done, Ret0, R} ->
            Ret1 = case Ret0 of
                {ok, T, {L,_}} -> {ok, T, L};
                {eof, {L,_}} -> {eof, L};
                {error, {{EL,_},M,D},{L,_}} -> {error, {EL,M,D},L}
            end,
            {done, Ret1, R}
    end.

do_tokens([], Chars, Line, Col) ->
    tokens(yystate(), Chars, Line, Col, Chars, 0, Line, Col, [], reject, 0);
do_tokens({tokens,State,Line,Col,Tcs,Tlen,Tline,Tcol,Ts,Action,Alen}, Chars, _,_) ->
    tokens(State, Chars, Line, Col, Tcs ++ Chars, Tlen, Tline, Tcol, Ts, Action, Alen);
do_tokens({skip_tokens,State,Line, Col, Tcs,Tlen,Tline,Tcol,Error,Action,Alen}, Chars, _,_) ->
    skip_tokens(State, Chars, Line, Col, Tcs ++ Chars, Tlen, Tline, Tcol, Error, Action, Alen).

%% tokens(State, InChars, Line, Col, TokenChars, TokenLen, TokenLine, TokenCol,Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

tokens(S0, Ics0, L0, C0, Tcs, Tlen0, Tline, Tcol, Ts, A0, Alen0) ->
    case yystate(S0, Ics0, L0, C0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1,C1} ->
            C2 = adjust_col(Tcs, Alen1, C1),
            tokens_cont(Ics1, L1, C2, yyaction(A1, Alen1, Tcs, Tline, Tcol), Ts);
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,C1,S1} ->                  % Need more chars to check
            {more,{tokens,S1,L1,C1,Tcs,Alen1,Tline,Tcol,Ts,A1,Alen1}};
        {A1,Alen1,Ics1,L1,C1,_S1} ->               % Take what we got
            C2 = adjust_col(Tcs, Alen1, C1),
            tokens_cont(Ics1, L1, C2, yyaction(A1, Alen1, Tcs, Tline,Tcol), Ts);
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,C1,S1} ->            % Need more chars to check
            {more,{tokens,S1,L1,C1,Tcs,Tlen1,Tline,Tcol,Ts,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,C1,_S1} ->     % No token match
            %% Check for partial token which is error, no need to skip here.
            Ret = if Tlen1 > 0 -> {error,{{Tline,Tcol},?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},{L1,C1}};
                     Ts == [] -> {eof,{L1,C1}};
                     true -> {ok,yyrev(Ts),{L1,C1}}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,C1,_S1} ->
            %% Skip rest of tokens.
            Error = {{L1,C1},?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, C1, Error);
        {A1,Alen1,Tlen1,_Ics1,L1,_C1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline,Tcol),
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            C2 = C0 + Alen1,
            tokens_cont(Tcs1, L2, C2, Token, Ts)
    end.

%% tokens_cont(RestChars, Line, Column, Token, Tokens)
%% If we have an end_token or error then return done, else if we have
%% a token then save it and continue, else if we have a skip_token
%% just continue.

-dialyzer({nowarn_function, tokens_cont/5}).

tokens_cont(Rest, Line, Col, {token,T}, Ts) ->
    tokens(yystate(), Rest, Line, Col, Rest, 0, Line, Col, [T|Ts], reject, 0);
tokens_cont(Rest, Line, Col, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, Col, NewRest, 0, Line, Col, [T|Ts], reject, 0);
tokens_cont(Rest, Line, Col, {end_token,T}, Ts) ->
    {done,{ok,yyrev(Ts, [T]),{Line,Col}},Rest};
tokens_cont(Rest, Line, Col, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    {done,{ok,yyrev(Ts, [T]),{Line, Col}},NewRest};
tokens_cont(Rest, Line, Col, skip_token, Ts) ->
    tokens(yystate(), Rest, Line, Col, Rest, 0, Line, Col, Ts, reject, 0);
tokens_cont(Rest, Line, Col, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, Col, NewRest, 0, Line, Col, Ts, reject, 0);
tokens_cont(Rest, Line, Col, {error,S}, _Ts) ->
    skip_tokens(Rest, Line, Col, {{Line,Col},?MODULE,{user,S}}).

%% skip_tokens(InChars, Line, Col, Error) -> {done,{error,Error,{Line,Col}},Ics}.
%% Skip tokens until an end token, junk everything and return the error.

skip_tokens(Ics, Line, Col, Error) ->
    skip_tokens(yystate(), Ics, Line, Col, Ics, 0, Line, Col, Error, reject, 0).

%% skip_tokens(State, InChars, Line, Col, TokenChars, TokenLen, TokenLine, TokenCol, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

skip_tokens(S0, Ics0, L0, C0, Tcs, Tlen0, Tline, Tcol, Error, A0, Alen0) ->
    case yystate(S0, Ics0, L0, C0, Tlen0, A0, Alen0) of
        {A1,Alen1,Ics1,L1, C1} ->                  % Accepting end state
            skip_cont(Ics1, L1, C1, yyaction(A1, Alen1, Tcs, Tline, Tcol), Error);
        {A1,Alen1,[],L1,C1, S1} ->                 % After an accepting state
            {more,{skip_tokens,S1,L1,C1,Tcs,Alen1,Tline,Tcol,Error,A1,Alen1}};
        {A1,Alen1,Ics1,L1,C1,_S1} ->
            skip_cont(Ics1, L1, C1, yyaction(A1, Alen1, Tcs, Tline, Tcol), Error);
        {A1,Alen1,Tlen1,[],L1,C1,S1} ->           % After a non-accepting state
            {more,{skip_tokens,S1,L1,C1,Tcs,Tlen1,Tline,Tcol,Error,A1,Alen1}};
        {reject,_Alen1,_Tlen1,eof,L1,C1,_S1} ->
            {done,{error,Error,{L1,C1}},eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,C1,_S1} ->
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, C1,Error);
        {A1,Alen1,Tlen1,_Ics1,L1,C1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline, Tcol),
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            skip_cont(Tcs1, L2, C1, Token, Error)
    end.

%% skip_cont(RestChars, Line, Col, Token, Error)
%% Skip tokens until we have an end_token or error then return done
%% with the original rror.

-dialyzer({nowarn_function, skip_cont/5}).

skip_cont(Rest, Line, Col, {token,_T}, Error) ->
    skip_tokens(yystate(), Rest, Line, Col, Rest, 0, Line, Col, Error, reject, 0);
skip_cont(Rest, Line, Col, {token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, Col, NewRest, 0, Line, Col, Error, reject, 0);
skip_cont(Rest, Line, Col, {end_token,_T}, Error) ->
    {done,{error,Error,{Line,Col}},Rest};
skip_cont(Rest, Line, Col, {end_token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    {done,{error,Error,{Line,Col}},NewRest};
skip_cont(Rest, Line, Col, skip_token, Error) ->
    skip_tokens(yystate(), Rest, Line, Col, Rest, 0, Line, Col, Error, reject, 0);
skip_cont(Rest, Line, Col, {skip_token,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, Col, NewRest, 0, Line, Col, Error, reject, 0);
skip_cont(Rest, Line, Col, {error,_S}, Error) ->
    skip_tokens(yystate(), Rest, Line, Col, Rest, 0, Line, Col, Error, reject, 0).

-compile({nowarn_unused_function, [yyrev/1, yyrev/2, yypre/2, yysuf/2]}).

yyrev(List) -> lists:reverse(List).
yyrev(List, Tail) -> lists:reverse(List, Tail).
yypre(List, N) -> lists:sublist(List, N).
yysuf(List, N) -> lists:nthtail(N, List).

%% adjust_line(TokenLength, AcceptLength, Chars, Line) -> NewLine
%% Make sure that newlines in Chars are not counted twice.
%% Line has been updated with respect to newlines in the prefix of
%% Chars consisting of (TokenLength - AcceptLength) characters.

-compile({nowarn_unused_function, adjust_line/4}).

adjust_line(N, N, _Cs, L) -> L;
adjust_line(T, A, [$\n|Cs], L) ->
    adjust_line(T-1, A, Cs, L-1);
adjust_line(T, A, [_|Cs], L) ->
    adjust_line(T-1, A, Cs, L).

%% adjust_col(Chars, AcceptLength, Col) -> NewCol
%% Handle newlines, tabs and unicode chars.
adjust_col(_, 0, Col) ->
    Col;
adjust_col([$\n | R], L, _) ->
    adjust_col(R, L-1, 1);
adjust_col([$\t | R], L, Col) ->
    adjust_col(R, L-1, tab_forward(Col)+1);
adjust_col([C | R], L, Col) when C>=0 andalso C=< 16#7F ->
    adjust_col(R, L-1, Col+1);
adjust_col([C | R], L, Col) when C>= 16#80 andalso C=< 16#7FF ->
    adjust_col(R, L-1, Col+2);
adjust_col([C | R], L, Col) when C>= 16#800 andalso C=< 16#FFFF ->
    adjust_col(R, L-1, Col+3);
adjust_col([C | R], L, Col) when C>= 16#10000 andalso C=< 16#10FFFF ->
    adjust_col(R, L-1, Col+4).

tab_forward(C) ->
    D = C rem tab_size(),
    A = tab_size()-D,
    C+A.

tab_size() -> 8.

%% yystate() -> InitialState.
%% yystate(State, InChars, Line, Col, CurrTokLen, AcceptAction, AcceptLen) ->
%% {Action, AcceptLen, RestChars, Line, Col} |
%% {Action, AcceptLen, RestChars, Line, Col, State} |
%% {reject, AcceptLen, CurrTokLen, RestChars, Line, Col, State} |
%% {Action, AcceptLen, CurrTokLen, RestChars, Line, Col, State}.
%% Generated state transition functions. The non-accepting end state
%% return signal either an unrecognised character or end of current
%% input.

-file("src/lexical_analysis.erl", 346).
yystate() -> 46.

yystate(47, Ics, Line, Col, Tlen, _, _) ->
    {0,Tlen,Ics,Line,Col};
yystate(46, [116|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(44, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [111|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(30, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [110|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(26, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [105|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [102|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(16, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [101|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [97|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(1, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [94|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(7, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [62|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(9, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [61|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(13, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [60|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(17, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [47|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(27, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [45|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(31, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [43|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(33, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [42|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(35, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [41|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(37, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [40|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(39, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [37|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(41, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [33|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(43, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [32|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(47, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [9|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(47, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, [10|Ics], Line, _, Tlen, Action, Alen) ->
    yystate(47, Ics, Line+1, 1, Tlen+1, Action, Alen);
yystate(46, [C|Ics], Line, Col, Tlen, Action, Alen) when C >= 48, C =< 57 ->
    yystate(21, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(46, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,46};
yystate(45, Ics, Line, Col, Tlen, _, _) ->
    {25,Tlen,Ics,Line,Col};
yystate(44, [114|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(42, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(44, [104|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(44, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,44};
yystate(43, [61|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(45, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(43, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,43};
yystate(42, [117|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(40, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(42, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,42};
yystate(41, Ics, Line, Col, Tlen, _, _) ->
    {11,Tlen,Ics,Line,Col};
yystate(40, [101|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(38, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(40, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,40};
yystate(39, Ics, Line, Col, Tlen, _, _) ->
    {3,Tlen,Ics,Line,Col};
yystate(38, Ics, Line, Col, Tlen, _, _) ->
    {15,Tlen,Ics,Line,Col};
yystate(37, Ics, Line, Col, Tlen, _, _) ->
    {4,Tlen,Ics,Line,Col};
yystate(36, [101|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(34, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(36, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,36};
yystate(35, Ics, Line, Col, Tlen, _, _) ->
    {7,Tlen,Ics,Line,Col};
yystate(34, [110|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(32, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(34, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,34};
yystate(33, Ics, Line, Col, Tlen, _, _) ->
    {5,Tlen,Ics,Line,Col};
yystate(32, Ics, Line, Col, Tlen, _, _) ->
    {13,Tlen,Ics,Line,Col};
yystate(31, Ics, Line, Col, Tlen, _, _) ->
    {6,Tlen,Ics,Line,Col};
yystate(30, [114|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(28, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(30, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,30};
yystate(29, Ics, Line, Col, Tlen, _, _) ->
    {8,Tlen,Ics,Line,Col};
yystate(28, Ics, Line, Col, Tlen, _, _) ->
    {18,Tlen,Ics,Line,Col};
yystate(27, [47|Ics], Line, Col, Tlen, _, _) ->
    yystate(29, Ics, Line, Col, Tlen+1, 9, Tlen);
yystate(27, Ics, Line, Col, Tlen, _, _) ->
    {9,Tlen,Ics,Line,Col,27};
yystate(26, [111|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(24, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(26, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,26};
yystate(25, [C|Ics], Line, Col, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(25, Ics, Line, Col, Tlen+1, 1, Tlen);
yystate(25, Ics, Line, Col, Tlen, _, _) ->
    {1,Tlen,Ics,Line,Col,25};
yystate(24, [116|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(22, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(24, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,24};
yystate(23, [C|Ics], Line, Col, Tlen, Action, Alen) when C >= 48, C =< 57 ->
    yystate(25, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(23, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,23};
yystate(22, Ics, Line, Col, Tlen, _, _) ->
    {19,Tlen,Ics,Line,Col};
yystate(21, [100|Ics], Line, Col, Tlen, _, _) ->
    yystate(23, Ics, Line, Col, Tlen+1, 2, Tlen);
yystate(21, [C|Ics], Line, Col, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(21, Ics, Line, Col, Tlen+1, 2, Tlen);
yystate(21, Ics, Line, Col, Tlen, _, _) ->
    {2,Tlen,Ics,Line,Col,21};
yystate(20, [102|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(18, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(20, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,20};
yystate(19, Ics, Line, Col, Tlen, _, _) ->
    {23,Tlen,Ics,Line,Col};
yystate(18, Ics, Line, Col, Tlen, _, _) ->
    {12,Tlen,Ics,Line,Col};
yystate(17, [61|Ics], Line, Col, Tlen, _, _) ->
    yystate(19, Ics, Line, Col, Tlen+1, 22, Tlen);
yystate(17, Ics, Line, Col, Tlen, _, _) ->
    {22,Tlen,Ics,Line,Col,17};
yystate(16, [97|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(14, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(16, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,16};
yystate(15, Ics, Line, Col, Tlen, _, _) ->
    {24,Tlen,Ics,Line,Col};
yystate(14, [108|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(14, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,14};
yystate(13, [61|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(15, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(13, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,13};
yystate(12, [115|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(10, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(12, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,12};
yystate(11, Ics, Line, Col, Tlen, _, _) ->
    {21,Tlen,Ics,Line,Col};
yystate(10, [101|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(8, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(10, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,10};
yystate(9, [61|Ics], Line, Col, Tlen, _, _) ->
    yystate(11, Ics, Line, Col, Tlen+1, 20, Tlen);
yystate(9, Ics, Line, Col, Tlen, _, _) ->
    {20,Tlen,Ics,Line,Col,9};
yystate(8, Ics, Line, Col, Tlen, _, _) ->
    {16,Tlen,Ics,Line,Col};
yystate(7, Ics, Line, Col, Tlen, _, _) ->
    {10,Tlen,Ics,Line,Col};
yystate(6, [108|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(4, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(6, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,6};
yystate(5, Ics, Line, Col, Tlen, _, _) ->
    {17,Tlen,Ics,Line,Col};
yystate(4, [115|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(2, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(4, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,4};
yystate(3, [100|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(5, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(3, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,3};
yystate(2, [101|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(0, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(2, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,2};
yystate(1, [110|Ics], Line, Col, Tlen, Action, Alen) ->
    yystate(3, Ics, Line, Col, Tlen+1, Action, Alen);
yystate(1, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,1};
yystate(0, Ics, Line, Col, Tlen, _, _) ->
    {14,Tlen,Ics,Line,Col};
yystate(S, Ics, Line, Col, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,Col,S}.

%% yyaction(Action, TokenLength, TokenChars, TokenLine, TokenCol) ->
%% {token,Token} | {end_token, Token} | skip_token | {error,String}.
%% Generated action function.

yyaction(0, _, _, _, _) ->
    yyaction_0();
yyaction(1, TokenLen, YYtcs, _, _) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_1(TokenChars);
yyaction(2, TokenLen, YYtcs, _, _) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_2(TokenChars);
yyaction(3, _, _, TokenLine, _) ->
    yyaction_3(TokenLine);
yyaction(4, _, _, TokenLine, _) ->
    yyaction_4(TokenLine);
yyaction(5, _, _, TokenLine, _) ->
    yyaction_5(TokenLine);
yyaction(6, _, _, TokenLine, _) ->
    yyaction_6(TokenLine);
yyaction(7, _, _, TokenLine, _) ->
    yyaction_7(TokenLine);
yyaction(8, _, _, TokenLine, _) ->
    yyaction_8(TokenLine);
yyaction(9, _, _, TokenLine, _) ->
    yyaction_9(TokenLine);
yyaction(10, _, _, TokenLine, _) ->
    yyaction_10(TokenLine);
yyaction(11, _, _, TokenLine, _) ->
    yyaction_11(TokenLine);
yyaction(12, _, _, TokenLine, _) ->
    yyaction_12(TokenLine);
yyaction(13, _, _, TokenLine, _) ->
    yyaction_13(TokenLine);
yyaction(14, _, _, TokenLine, _) ->
    yyaction_14(TokenLine);
yyaction(15, _, _, _, _) ->
    yyaction_15();
yyaction(16, _, _, _, _) ->
    yyaction_16();
yyaction(17, _, _, TokenLine, _) ->
    yyaction_17(TokenLine);
yyaction(18, _, _, TokenLine, _) ->
    yyaction_18(TokenLine);
yyaction(19, _, _, TokenLine, _) ->
    yyaction_19(TokenLine);
yyaction(20, _, _, TokenLine, _) ->
    yyaction_20(TokenLine);
yyaction(21, _, _, TokenLine, _) ->
    yyaction_21(TokenLine);
yyaction(22, _, _, TokenLine, _) ->
    yyaction_22(TokenLine);
yyaction(23, _, _, TokenLine, _) ->
    yyaction_23(TokenLine);
yyaction(24, _, _, TokenLine, _) ->
    yyaction_24(TokenLine);
yyaction(25, _, _, TokenLine, _) ->
    yyaction_25(TokenLine);
yyaction(_, _, _, _, _) -> error.

-compile({inline,yyaction_0/0}).
-file("src/lexer/lexical_analysis.xrl", 14).
yyaction_0() ->
     skip_token .

-compile({inline,yyaction_1/1}).
-file("src/lexer/lexical_analysis.xrl", 16).
yyaction_1(TokenChars) ->
     { token, { dice, to_string (TokenChars) } } .

-compile({inline,yyaction_2/1}).
-file("src/lexer/lexical_analysis.xrl", 17).
yyaction_2(TokenChars) ->
     { token, { number, list_to_integer (TokenChars) } } .

-compile({inline,yyaction_3/1}).
-file("src/lexer/lexical_analysis.xrl", 20).
yyaction_3(TokenLine) ->
     { token, { '(', TokenLine } } .

-compile({inline,yyaction_4/1}).
-file("src/lexer/lexical_analysis.xrl", 21).
yyaction_4(TokenLine) ->
     { token, { ')', TokenLine } } .

-compile({inline,yyaction_5/1}).
-file("src/lexer/lexical_analysis.xrl", 24).
yyaction_5(TokenLine) ->
     { token, { '+', TokenLine } } .

-compile({inline,yyaction_6/1}).
-file("src/lexer/lexical_analysis.xrl", 25).
yyaction_6(TokenLine) ->
     { token, { '-', TokenLine } } .

-compile({inline,yyaction_7/1}).
-file("src/lexer/lexical_analysis.xrl", 26).
yyaction_7(TokenLine) ->
     { token, { '*', TokenLine } } .

-compile({inline,yyaction_8/1}).
-file("src/lexer/lexical_analysis.xrl", 27).
yyaction_8(TokenLine) ->
     { token, { '//', TokenLine } } .

-compile({inline,yyaction_9/1}).
-file("src/lexer/lexical_analysis.xrl", 28).
yyaction_9(TokenLine) ->
     { token, { '/', TokenLine } } .

-compile({inline,yyaction_10/1}).
-file("src/lexer/lexical_analysis.xrl", 29).
yyaction_10(TokenLine) ->
     { token, { '^', TokenLine } } .

-compile({inline,yyaction_11/1}).
-file("src/lexer/lexical_analysis.xrl", 30).
yyaction_11(TokenLine) ->
     { token, { '%', TokenLine } } .

-compile({inline,yyaction_12/1}).
-file("src/lexer/lexical_analysis.xrl", 34).
yyaction_12(TokenLine) ->
     { token, { 'if', TokenLine } } .

-compile({inline,yyaction_13/1}).
-file("src/lexer/lexical_analysis.xrl", 35).
yyaction_13(TokenLine) ->
     { token, { then, TokenLine } } .

-compile({inline,yyaction_14/1}).
-file("src/lexer/lexical_analysis.xrl", 36).
yyaction_14(TokenLine) ->
     { token, { else, TokenLine } } .

-compile({inline,yyaction_15/0}).
-file("src/lexer/lexical_analysis.xrl", 37).
yyaction_15() ->
     { token, { boolean, true } } .

-compile({inline,yyaction_16/0}).
-file("src/lexer/lexical_analysis.xrl", 38).
yyaction_16() ->
     { token, { boolean, false } } .

-compile({inline,yyaction_17/1}).
-file("src/lexer/lexical_analysis.xrl", 39).
yyaction_17(TokenLine) ->
     { token, { 'and', TokenLine } } .

-compile({inline,yyaction_18/1}).
-file("src/lexer/lexical_analysis.xrl", 40).
yyaction_18(TokenLine) ->
     { token, { 'or', TokenLine } } .

-compile({inline,yyaction_19/1}).
-file("src/lexer/lexical_analysis.xrl", 41).
yyaction_19(TokenLine) ->
     { token, { 'not', TokenLine } } .

-compile({inline,yyaction_20/1}).
-file("src/lexer/lexical_analysis.xrl", 43).
yyaction_20(TokenLine) ->
     { token, { '>', TokenLine } } .

-compile({inline,yyaction_21/1}).
-file("src/lexer/lexical_analysis.xrl", 44).
yyaction_21(TokenLine) ->
     { token, { '>=', TokenLine } } .

-compile({inline,yyaction_22/1}).
-file("src/lexer/lexical_analysis.xrl", 45).
yyaction_22(TokenLine) ->
     { token, { '<', TokenLine } } .

-compile({inline,yyaction_23/1}).
-file("src/lexer/lexical_analysis.xrl", 46).
yyaction_23(TokenLine) ->
     { token, { '<=', TokenLine } } .

-compile({inline,yyaction_24/1}).
-file("src/lexer/lexical_analysis.xrl", 47).
yyaction_24(TokenLine) ->
     { token, { '==', TokenLine } } .

-compile({inline,yyaction_25/1}).
-file("src/lexer/lexical_analysis.xrl", 48).
yyaction_25(TokenLine) ->
     { token, { '!=', TokenLine } } .
-file("/home/xaquin/.asdf/installs/erlang/26.1/lib/parsetools-2.5/include/leexinc.hrl", 344).
