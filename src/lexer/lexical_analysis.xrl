Definitions.

CONTENT_STRING    = [a-zA-Z0-9_,\-\/\\\.\ssáéíóúÁÉÍÓÚüÜñÑ]*
STRING            = (\'\s*{CONTENT_STRING}\'|\"\s*{CONTENT_STRING}\")
% '
WHITESPACE        = [\n\t\s]
JUMP              = \n
IF                = if
FUNCTION          = function
THEN              = then
ELSE              = else
ELSEIF            = elseif
FOR               = for
DO                = do
END               = end
TRUE              = true
FALSE             = false
AND               = and
OR                = or
NOT               = not
DICE              = d
LEFT_PARENTHESIS  = \(
RIGHT_PARENTHESIS = \)
LEFT_BRACKET      = \[
RIGHT_BRACKET     = \]
% Esto se hace para que evitar que expresiones como 1d743 lo tokenice como number 1 var d743
NAME              = [a-ce-zA-Z_]|d[^0-9\s*]|[a-zA-Z_][a-zA-Z_]+[a-zA-Z0-9_]*

RANGE             = \.\.
NUMBER            = [0-9]+
NEGATIVE_NUMBER   = \-\s*[0-9]+
NOT_DEFINED       = .


Rules.

{WHITESPACE} : skip_token.

{DICE}       : {token, {'d', TokenLine}}.
{RANGE}      : {token, {'..', to_string(TokenChars)}}.

{NUMBER}     : {token, {number, list_to_integer(TokenChars)}}.

%% String

{STRING} : {token, {string, to_string(TokenChars)}}. 

%% open/close parens
{LEFT_PARENTHESIS}     : {token, {'(', TokenLine}}.
{RIGHT_PARENTHESIS}    : {token, {')', TokenLine}}.

%% open/close bracket
{LEFT_BRACKET}     : {token, {'[', TokenLine}}.
{RIGHT_BRACKET}    : {token, {']', TokenLine}}.


%% arithmetic operators
\+      : {token, {'+', TokenLine}}.
\+\+    : {token, {'++',TokenLine}}.
\-      : {token, {'-', TokenLine}}.
\*      : {token, {'*', TokenLine}}.
\//     : {token, {'//',TokenLine}}.
\/      : {token, {'/', TokenLine}}.
\^      : {token, {'^', TokenLine}}.
\=      : {token, {'=', TokenLine}}.
\;      : {token, {';', TokenLine}}.   
\,      : {token, {',', TokenLine}}.      
\%      : {token, {'%', TokenLine}}.

%% conditional operators
{IF}     : {token, {'if', TokenLine}}.
{THEN}   : {token, {'then', TokenLine}}.
{ELSE}   : {token, {'else', TokenLine}}.
{ELSEIF} : {token, {'elseif', TokenLine}}.
{TRUE}   : {token, {boolean, true}}.
{FALSE}  : {token, {boolean, false}}.
{AND}    : {token, {'and', TokenLine}}.
{OR}     : {token, {'or', TokenLine}}.
{NOT}    : {token, {'not', TokenLine}}.
\>       : {token, {'>', TokenLine}}.
\>=      : {token, {'>=', TokenLine}}.
\<       : {token, {'<', TokenLine}}.
\<=      : {token, {'<=', TokenLine}}.
\==      : {token, {'==', TokenLine}}.
\!=      : {token, {'!=', TokenLine}}.
 
%% loop operators

{FOR}   : {token, {'for', TokenLine}}.
{DO}    : {token, {'do', TokenLine}}.
{END}   : {token, {'end', TokenLine}}.

\<-     : {token, {'<-', TokenLine}}.

{FUNCTION}   : {token, {def_function, to_string(TokenChars)}}.
{NAME}        : {token, {name, to_string(TokenChars)}}.

% {ERROR}         : {error, {token,to_string(TokenChars),TokenLine} }.
% {NOT_DEFINED}   : {token, {not_defined, to_string(TokenChars)}}.

Erlang code.


to_string(TokenChars) ->

    TokenString = unicode:characters_to_binary(TokenChars),

    TokenString.