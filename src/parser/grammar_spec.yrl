Nonterminals
    boolean_expression_prior0 numeric_expression_prior2  grammar logic_conditions logic_expression_prior3 logic_expression_prior2 logic_expression_prior1
    boolean_expression_prior2 boolean_expression_prior3 numeric_expression_prior0 numeric_expression_prior1 expression if_statement 
    code boolean_expression_prior1  else_block  assignment block for_loop enumerable list_of_number numeric_sequence
    string_expression_prior2 string_expression_prior1 string_expression_prior0 negative_number minus logic_expression_prior0. 
    
Terminals 'if' 'then' 'else' not_defined boolean number var 'end' 'and' 'for' '..' '<-' 'do' 'or' 'not' '+' '>'
 '=' '>=' '<' ';' ',' '<=' '==' '!=' '-' '%' '*' '/' '//'  '[' ']' '(' ')' '^' dice string.

Rootsymbol
    grammar.

grammar -> block : '$1'.

block -> code           : '$1'.
block -> code ';' block : {'$1', '$3'}. 
block -> not_defined    : '$1'.  
block -> '$empty'.

%code
    code -> if_statement : '$1'.
    code -> for_loop     : '$1'.
    code -> assignment   : '$1'.
    code -> expression   : '$1'.
    code -> logic_conditions   : '$1'.

%ifs
    if_statement -> 'if' logic_conditions 'then' code else_block 'end'
    : {if_then_else, '$2', '$4', '$5'}.

    else_block -> 'else' block     : '$2'.
    else_block -> '$empty'.

%fors
    for_loop -> 'for' var '<-' enumerable 'do' block 'end' : {for_loop, '$2', '$4', '$6'}.
    enumerable -> var : {range,'$1'}.
    enumerable -> numeric_expression_prior2'..'numeric_expression_prior2 : {range,{'$1', '$3'}}.
    enumerable -> list_of_number  : {range,'$1'}.


% assignment of variables
    assignment -> var '=' expression : {assignment, '$1', '$3'}.

% expressions
    expression -> numeric_expression_prior2        : '$1'.
    expression -> string_expression_prior2         : '$1'.

    %numeric expression
        %prioridad 2
        numeric_expression_prior2 -> numeric_expression_prior1  '+' numeric_expression_prior2  : {plus, '$1', '$3'}.
        numeric_expression_prior2 -> numeric_expression_prior1  minus                          : {plus, '$1', '$2'}.
            minus -> negative_number '+' numeric_expression_prior2  : {plus, '$1', '$3'}.
            minus -> negative_number minus                          : {plus, '$1', '$2'}.
            minus -> negative_number                                : '$1'.
            minus -> '(' negative_number ')'                        : '$2'.
            negative_number -> '-' numeric_expression_prior0        : {negative, '$2'}.
        numeric_expression_prior2 -> numeric_expression_prior1                          : '$1'.   

        %prioridad 1
        numeric_expression_prior1 -> numeric_expression_prior0 '*'  numeric_expression_prior1           : {mult, '$1', '$3'}.
        numeric_expression_prior1 -> numeric_expression_prior0 '/'  numeric_expression_prior1           : {divi, '$1', '$3'}.
        numeric_expression_prior1 -> numeric_expression_prior0 '//' numeric_expression_prior1           : {round_div, '$1', '$3'}.
        numeric_expression_prior1 -> numeric_expression_prior0 '%'  numeric_expression_prior1           : {mod, '$1', '$3'}.
        numeric_expression_prior1 -> numeric_expression_prior0 '^'  numeric_expression_prior1           : {pow, '$1', '$3'}.
        numeric_expression_prior1 -> numeric_expression_prior0                                          : '$1'.

        %prioridad 0
        numeric_expression_prior0 -> negative_number                                    : '$1'.
        numeric_expression_prior0 -> '(' numeric_expression_prior2 ')'                  : '$2'.
        numeric_expression_prior0 -> dice                                               : '$1'.
        numeric_expression_prior0 -> number                                             : '$1'.
        numeric_expression_prior0 -> var                                                : '$1'.
        numeric_expression_prior0 -> list_of_number                                     : '$1'.
            list_of_number -> '[' numeric_sequence ']'                                  : {list_of_number, '$2'}.
                numeric_sequence -> numeric_expression_prior2 ',' numeric_sequence      : {'$1', '$3'}.
                numeric_sequence -> numeric_expression_prior2                           : '$1'.
                numeric_sequence -> '$empty'.


    %strings expressions
        string_expression_prior2 -> string_expression_prior1  '+' string_expression_prior2 : {concat, '$1', '$3'}.
        string_expression_prior2 -> string_expression_prior1  : '$1'.
        string_expression_prior1 -> string_expression_prior0  : '$1'.
        string_expression_prior0 -> string                    : '$1'.

%logic conditions
    logic_conditions -> boolean_expression_prior3 : '$1'.
  
    logic_expression_prior3 -> boolean_expression_prior3 : '$1'.
    logic_expression_prior3 -> expression : '$1'.

    logic_expression_prior2-> boolean_expression_prior2 : '$1'.
    logic_expression_prior2 -> expression  : '$1'.

    logic_expression_prior1 -> boolean_expression_prior1: '$1'.
    logic_expression_prior1 -> expression  : '$1'.

    logic_expression_prior0 -> boolean_expression_prior0: '$1'.
    logic_expression_prior0 -> expression  : '$1'.

    %boolean expressions
        %prioridad 3
        boolean_expression_prior3 -> logic_expression_prior2 'or'    logic_expression_prior3 : {or_operation, '$1', '$3'}.
        boolean_expression_prior3 -> logic_expression_prior2 'and'   logic_expression_prior3 : {and_operation, '$1', '$3'}.
        boolean_expression_prior3 ->                         'not'   logic_expression_prior3 : {not_operation, '$2'}.
        boolean_expression_prior3 -> boolean_expression_prior2                        : '$1'.

        %prioridad 2
        boolean_expression_prior2 -> logic_expression_prior1 '!=' logic_expression_prior2 : {not_equal, '$1', '$3'}.       
        boolean_expression_prior2 -> logic_expression_prior1 '==' logic_expression_prior2 : {equal, '$1', '$3'}.
        boolean_expression_prior2 -> boolean_expression_prior1                            : '$1'.

        %prioridad 1
        boolean_expression_prior1 -> logic_expression_prior0  '>'    logic_expression_prior1 : {stric_more, '$1', '$3'}.
        boolean_expression_prior1 -> logic_expression_prior0  '>='   logic_expression_prior0 : {more_equal, '$1', '$3'}.
        boolean_expression_prior1 -> logic_expression_prior0  '<='   logic_expression_prior0 : {less_equal, '$1', '$3'}.
        boolean_expression_prior1 -> logic_expression_prior0  '<'    logic_expression_prior0 : {stric_less, '$1', '$3'}.
        boolean_expression_prior1 -> boolean_expression_prior0                               : '$1'.
        
        %prioridad 0
        
        boolean_expression_prior0 -> '(' boolean_expression_prior3 ')' : '$2'.
        boolean_expression_prior0 -> boolean                           : '$1'.



