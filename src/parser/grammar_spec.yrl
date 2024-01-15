Nonterminals
    term factor boolean_factor numeric_expression compare_terms types comparison_expression
    boolean_term numeric_factor numeric_term condition expression if_statement
    code boolean_expression  else_block  assignment block code_sequence for_loop interval list_of_number numeric_sequence
    string_expression string_term string_factor negative_number minus. 
    
Terminals 'if' 'then' 'else' not_defined boolean number var 'end' 'and' 'for' '..' '<-' 'do' 'or' 'not' '+' '>'
 '=' '>=' '<' ';' ',' '<=' '==' '!=' '-' '%' '*' '/' '//'  '[' ']' '(' ')' '^' dice string.

Rootsymbol
    block.

block -> code : '$1'.
block -> code_sequence : '$1'.
block -> '$empty'.

code_sequence -> code ';' block : {'$1', '$3'}.

code -> if_statement : '$1'.
code -> expression   : '$1'.
code -> assignment   : '$1'.
code -> for_loop     : '$1'.


for_loop -> 'for' var '<-' interval 'do' block 'end' : {for_loop, '$2', '$4', '$6'}.

interval -> var : {range,'$1'}.
interval -> numeric_expression'..'numeric_expression : {range,{'$1', '$3'}}.
interval -> list_of_number  : {range,'$1'}.


if_statement -> 'if' boolean_expression 'then' code else_block 'end'
    : {if_then_else, '$2', '$4', '$5'}.

else_block -> '$empty'.
else_block -> 'else' block     : '$2'.


assignment -> var '=' expression : {assignment, '$1', '$3'}.

types   ->  numeric_expression        : '$1'.
types   ->  string_expression         : '$1'.
types   ->  not_defined               : '$1'.    

expression -> types    : '$1'.
expression -> boolean_expression    : '$1'.


minus -> negative_number '+' numeric_expression : {plus, '$1', '$3'}.
minus -> negative_number minus                  : {plus, '$1', '$2'}.
minus -> negative_number                        : '$1'.
minus -> '(' negative_number ')'                : '$2'.

negative_number -> '-' numeric_factor         : {negative, '$2'}.

numeric_expression -> numeric_term  '+' numeric_expression : {plus, '$1', '$3'}.
numeric_expression -> numeric_term  minus                  : {plus, '$1', '$2'}.
numeric_expression -> numeric_term                         : '$1'.   

numeric_term -> numeric_factor '*'  numeric_term : {mult, '$1', '$3'}.
numeric_term -> numeric_factor '/'  numeric_term : {divi, '$1', '$3'}.
numeric_term -> numeric_factor '//'  numeric_term : {round_div, '$1', '$3'}.
numeric_term -> numeric_factor '%'   numeric_term : {mod, '$1', '$3'}.
numeric_term -> numeric_factor '^'   numeric_term : {pow, '$1', '$3'}.
numeric_term -> numeric_factor                    : '$1'.
numeric_term -> var                               : '$1'.

numeric_factor -> negative_number            : '$1'.
numeric_factor -> '(' numeric_expression ')' : '$2'.
numeric_factor -> dice                       : '$1'.
numeric_factor -> number                     : '$1'.
numeric_factor -> list_of_number             : '$1'.

list_of_number -> '[' numeric_sequence ']'                      : {list_of_number, '$2'}.
numeric_sequence -> numeric_expression ',' numeric_sequence     : {'$1', '$3'}.
numeric_sequence -> numeric_expression                          : '$1'.
numeric_sequence -> '$empty'.

boolean_expression -> boolean_expression 'or' boolean_expression  : {or_operation, '$1', '$3'}.
boolean_expression -> boolean_expression 'and' boolean_expression : {and_operation, '$1', '$3'}.
boolean_expression -> comparison_expression                  : '$1'.

comparison_expression -> types '!=' expression              : {not_equal, '$1', '$3'}.
comparison_expression -> types '==' expression              : {equal, '$1', '$3'}.
comparison_expression -> boolean_expression '!=' expression : {not_equal, '$1', '$3'}.
comparison_expression -> boolean_expression '==' expression : {equal, '$1', '$3'}.

boolean_expression -> boolean_term : '$1'.

boolean_term -> types '>'  expression   : {stric_more, '$1', '$3'}.
boolean_term -> types '>=' expression   : {more_equal, '$1', '$3'}.
boolean_term -> types '<=' expression   : {less_equal, '$1', '$3'}.
boolean_term -> types '<'  expression   : {stric_less, '$1', '$3'}.
boolean_term -> boolean_expression '>'  expression   : {stric_more, '$1', '$3'}.
boolean_term -> boolean_expression '>=' expression   : {more_equal, '$1', '$3'}.
boolean_term -> boolean_expression '<=' expression   : {less_equal, '$1', '$3'}.
boolean_term -> boolean_expression '<'  expression   : {stric_less, '$1', '$3'}.
boolean_term -> boolean_factor                               : '$1'.

boolean_factor -> 'not' boolean_expression     : {not_operation, '$2'}.
boolean_factor -> '(' boolean_expression ')'   : '$2'.
boolean_factor -> boolean                      : '$1'.

string_expression -> string_term  '+' string_expression : {concat, '$1', '$3'}.
string_expression -> string_term    : '$1'.
string_term       -> string_factor  : '$1'.
string_factor     -> string : '$1'.

