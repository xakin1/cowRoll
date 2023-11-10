Definitions.

DICE          = [0-9]+d[0-9]+
NUMBER        = [0-9]+
WHITESPACE    = [\n\t\s]
IF            = if
THEN          = then
ELSE          = else
TRUE          = true
FALSE         = false
AND           = and
OR            = or
NOT           = not
Rules.

{WHITESPACE} : skip_token.

{DICE}       : {token, {dice, to_string(TokenChars)}}.
{NUMBER}     : {token, {number, list_to_integer(TokenChars)}}.

%% open/close parens
\(      : {token, {'(', TokenLine}}.
\)      : {token, {')', TokenLine}}.

%% arithmetic operators
\+      : {token, {'+', TokenLine}}.
\-      : {token, {'-', TokenLine}}.
\*      : {token, {'*', TokenLine}}.
\//     : {token, {'//', TokenLine}}.
\/      : {token, {'/', TokenLine}}.
\^      : {token, {'^', TokenLine}}.
\%      : {token, {'%', TokenLine}}.


%% conditional operators
{IF}    : {token, {'if', TokenLine}}.
{THEN}  : {token, {'then', TokenLine}}.
{ELSE}  : {token, {'else', TokenLine}}.
{TRUE}  : {token, {boolean, true}}.
{FALSE} : {token, {boolean, false}}.
{AND}   : {token, {'and', TokenLine}}.
{OR}    : {token, {'or', TokenLine}}.
{NOT}   : {token, {'not', TokenLine}}.

\>      : {token, {'>', TokenLine}}.
\>=     : {token, {'>=', TokenLine}}.
\<      : {token, {'<', TokenLine}}.
\<=     : {token, {'<=', TokenLine}}.
\==     : {token, {'==', TokenLine}}.
\!=     : {token, {'!=', TokenLine}}.
Erlang code.

to_string(TokenChars) ->

    % Convierte la lista de caracteres en una cadena de texto binario
    TokenString = binary:list_to_bin(TokenChars),

    TokenString.