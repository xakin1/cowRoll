Nonterminals
    term factor boolean_factor numeric_expression
    boolean_term numeric_factor numeric_term compare_terms condition expression if_statement
    code boolean_expression if_block else_block. 
    
Terminals 'if' 'then' 'else' not_defined boolean number 'and' 'or' 'not' '+' '>'
 '>=' '<' '<=' '==' '!=' '-' '%' '*' '/' '//' '(' ')' '^' dice.

Rootsymbol
    code.

code -> if_statement : '$1'.
code -> expression   : '$1'.

if_statement -> 'if' condition 'then' if_block
    : {if_then_else, '$2', '$4'}.

if_block -> expression 'else' else_block : {else, '$1', '$3'}. 
if_block -> expression                   : {then_expression, '$1'}.
if_block -> if_statement                 : '$1'.

else_block -> code                       : {else_expression, '$1'}.

expression -> compare_terms         : '$1'.
expression -> numeric_expression    : '$1'.
expression -> boolean_expression    : '$1'.
expression -> term                  : '$1'.

compare_terms       -> numeric_factor  '!=' numeric_term   : {not_equal, '$1', '$3'}.
compare_terms       -> numeric_factor  '==' numeric_term   : {equal, '$1', '$3'}.
compare_terms       -> boolean_factor  '!=' boolean_term   : {not_equal, '$1', '$3'}.
compare_terms       -> boolean_factor  '==' boolean_term   : {equal, '$1', '$3'}.

term -> factor       : '$1'.

factor ->  not_defined    : '$1'.

condition -> compare_terms      : {condition, '$1'}.
condition -> boolean_expression : {condition, '$1'}.

numeric_expression  -> numeric_term  '+' numeric_term : {plus, '$1', '$3'}.
numeric_expression  -> numeric_term  '-' numeric_term : {minus, '$1', '$3'}.
numeric_expression  -> numeric_term                   : '$1'.
    
numeric_term ->  numeric_factor  '*'  numeric_term : {mult, '$1', '$3'}.
numeric_term ->  numeric_factor  '/'  numeric_term : {divi, '$1', '$3'}.
numeric_term -> numeric_factor '//' numeric_term     : {round_div, '$1', '$3'}.
numeric_term -> numeric_factor '%' numeric_term      : {mod, '$1', '$3'}.
numeric_term -> numeric_factor '^' numeric_term      : {pow, '$1', '$3'}.
numeric_term -> numeric_factor                       : '$1'.

numeric_factor -> '-' numeric_factor        : {negative, '$2'}.
numeric_factor -> '(' numeric_expression ')' : '$2'.
numeric_factor -> dice                      : '$1'.
numeric_factor -> number                    : '$1'.

boolean_expression  -> boolean_term 'or' boolean_expression  : {or_operation, '$1', '$3'}.
boolean_expression  -> boolean_term 'and' boolean_expression : {and_operation, '$1', '$3'}.
boolean_expression  -> boolean_term : '$1'.

boolean_term     -> numeric_term '>'  numeric_expression   : {stric_more, '$1', '$3'}.
boolean_term     -> numeric_term '>=' numeric_expression   : {more_equal, '$1', '$3'}.
boolean_term     -> numeric_term '<'  numeric_expression   : {stric_less, '$1', '$3'}.
boolean_term     -> numeric_term '<=' numeric_expression   : {less_equal, '$1', '$3'}.
boolean_term     -> boolean_factor                         : '$1'.

boolean_factor      -> 'not' boolean_factor                 : {not_operation, '$2'}.
boolean_factor      -> '(' boolean_expression ')'   : '$2'.
boolean_factor      -> boolean                      : '$1'.

