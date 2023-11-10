Nonterminals
    term  expr factor if_then_else code function boolean_expression. 
    
Terminals 'if' 'then' 'else'  boolean number dice '+' '>' '>=' '<' '<=' '==' '-' '%' '*' '/' '//' '(' ')' '^'.

Rootsymbol
    function.

function -> code : '$1'.

code -> expr : '$1'.
code -> if_then_else : '$1'.

code -> expr 'else' code : {else, '$1', '$3'}.

if_then_else -> 'if' boolean_expression 'then' code : {if_then_else, '$2', '$4'}.

expr -> expr '+' term : {plus, '$1', '$3'}.
expr -> expr '-' term : {minus, '$1', '$3'}.
expr -> term : '$1'.
expr -> boolean_expression: '$1'.

term -> factor '*' term : {mult, '$1', '$3'}.
term -> factor '/' term : {divi, '$1', '$3'}.
term -> factor '//' term : {round_div, '$1', '$3'}.
term -> factor '%' term : {mod, '$1', '$3'}.
term -> factor '^' term : {pow, '$1', '$3'}.
term -> factor : '$1'.

factor -> '(' expr ')' : '$2'.
factor -> '-' factor : {negative, '$2'}.

factor -> number : '$1'.
factor -> dice : '$1'.

boolean_expression -> boolean : '$1'.
boolean_expression -> expr '>' term : {stric_more, '$1', '$3'}.
boolean_expression -> expr '>=' term : {more_equal, '$1', '$3'}.
boolean_expression -> expr '<' term : {stric_less, '$1', '$3'}.
boolean_expression -> expr '<=' term : {less_equal, '$1', '$3'}.
boolean_expression -> expr '==' term : {equal, '$1', '$3'}.
