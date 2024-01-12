Definitions.

DICE              = [0-9]+d[0-9]+

WHITESPACE        = [\n\t\s]
IF                = if
THEN              = then
ELSE              = else
FOR               = for
DO                = do
END               = end
TRUE              = true
FALSE             = false
AND               = and
OR                = or
NOT               = not
LEFT_PARENTHESIS  = \(
RIGHT_PARENTHESIS = \)
VAR               = [a-zA-Z_][a-zA-Z0-9_]*
RANGE             = \.\.
NUMBER            = [0-9]+
NOT_DEFINED       = .


Rules.

{WHITESPACE} : skip_token.

{DICE}       : {token, {dice, to_string(TokenChars)}}.
{RANGE}      : {token, {'..', to_string(TokenChars)}}.

{NUMBER}     : {token, {number, list_to_integer(TokenChars)}}.


%% open/close parens
{LEFT_PARENTHESIS}     : {token, {'(', TokenLine}}.
{RIGHT_PARENTHESIS}    : {token, {')', TokenLine}}.


%% arithmetic operators
\+      : {token, {'+', TokenLine}}.
\-      : {token, {'-', TokenLine}}.
\*      : {token, {'*', TokenLine}}.
\//     : {token, {'//', TokenLine}}.
\/      : {token, {'/', TokenLine}}.
\^      : {token, {'^', TokenLine}}.
\=      : {token, {'=', TokenLine}}.
\;      : {token, {';', TokenLine}}.      
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

%% loop operators

{FOR}   : {token, {'for', TokenLine}}.
{DO}    : {token, {'do', TokenLine}}.
{END}   : {token, {'end', TokenLine}}.

\'.\'  : {token, {string, to_string(TokenChars)}}.
%%%'
\".\"  : {token, {string, to_string(TokenChars)}}.
%"
\<-     : {token, {'<-', TokenLine}}.

{VAR}        : {token, {var, to_string(TokenChars)}}.


{NOT_DEFINED} : {token, {not_defined, to_string(TokenChars)}}.

Erlang code.

to_string(TokenChars) ->

    % Convierte la lista de caracteres en una cadena de texto binario
    TokenString = binary:list_to_bin(TokenChars),

    TokenString.