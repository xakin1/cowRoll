Definitions.

CONTENT_STRING      = [a-zA-Z0-9_,\-\/\\.\(\)\sáéíóúÁÉÍÓÚüÜñÑ&\+\-%?¡!;·:€$#@^~|<>½¬{}\[\]=¿!*─'`,:_«»“”@ł€¶ŧ←↓→øþ~łĸŋđðßæ¢nµ]+
STRING              = (\'\s*{CONTENT_STRING}\'|\"\s*{CONTENT_STRING}\")
% '
WHITESPACE          = [\n\t\s]
JUMP                = \n
IF                  = if
FUNCTION            = function
THEN                = then
ELSE                = else
ELSEIF              = elseif
FOR                 = for
DO                  = do
END                 = end
TRUE                = true
FALSE               = false
AND                 = and
OR                  = or
NOT                 = not
LEFT_PARENTHESIS    = \(
RIGHT_PARENTHESIS   = \)
LEFT_BRACKET        = \[
RIGHT_BRACKET       = \]
LEFT_CURLY_BRACKET  = \{
RIGHT_CURLY_BRACKET = \}
LINE_COMMENT          = \#[^\n]*
BLOCK_COMMENT         = \/\*[^*]*\*+([^/*][^*]*\*+)*\/
NAME              = [a-zA-Z_áéíóúÁÉÍÓÚüÜñÑ]+[a-zA-Z0-9_áéíóúÁÉÍÓÚüÜñÑ&]*

RANGE             = \.\.
NUMBER            = [0-9]+
NEGATIVE_NUMBER   = \-\s*[0-9]+


Rules.

{WHITESPACE} : skip_token.
{LINE_COMMENT} : skip_token.
{BLOCK_COMMENT} : skip_token.


{RANGE}      : {token, {'..', to_string(TokenChars),TokenLine}}.

{NUMBER}     : {token, {number, list_to_integer(TokenChars),TokenLine}}.

%% String

{STRING} : {token, {string, to_string(TokenChars),TokenLine}}. 

%% open/close parens
{LEFT_PARENTHESIS}     : {token, {'(', TokenLine}}.
{RIGHT_PARENTHESIS}    : {token, {')', TokenLine}}.

%% open/close bracket
{LEFT_BRACKET}     : {token, {'[', TokenLine}}.
{RIGHT_BRACKET}    : {token, {']', TokenLine}}.

%% open/close bracket
{LEFT_CURLY_BRACKET}     : {token, { '{', TokenLine}}.
{RIGHT_CURLY_BRACKET}    : {token, { '}', TokenLine}}.


%% arithmetic operators
\+      : {token, {'+', TokenLine}}.
\+\+    : {token, {'++',TokenLine}}.
\-\-    : {token, {'--',TokenLine}}.
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
{TRUE}   : {token, {boolean, true,TokenLine}}.
{FALSE}  : {token, {boolean, false,TokenLine}}.
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
\:      : {token, {':', TokenLine}}.

{FUNCTION}   : {token, {def_function, to_string(TokenChars),TokenLine}}.
{NAME}        : {token, {name, to_string(TokenChars),TokenLine}}.

Erlang code.


to_string(TokenChars) ->

    TokenString = unicode:characters_to_binary(TokenChars),

    TokenString.