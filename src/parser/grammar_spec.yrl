Nonterminals
    term  expr factor else_clause function boolean_expression. 
    
Terminals 'if' 'then' 'else'  boolean number dice '+' '-' '%' '*' '/' '//' '(' ')' '^'.

Rootsymbol
    function.

function -> 'if' boolean_expression 'then' expr else_clause : {if_then_else, '$2', '$4', '$5'}.
function -> expr : '$1'.

else_clause -> 'else' term : '$2'.
else_clause ->  '$empty' : nil.


expr -> expr '+' term : {plus, '$1', '$3'}.
expr -> expr '-' term : {minus, '$1', '$3'}.
expr -> term : '$1'.

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
