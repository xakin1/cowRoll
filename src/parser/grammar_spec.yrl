Nonterminals
    term  expr factor. 
    
Terminals number dice '+' '-' '%' '*' '/' '//' '(' ')' '^'.

Rootsymbol
    expr.


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