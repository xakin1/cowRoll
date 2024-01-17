Nonterminals
    boolean_factor numeric_expression  grammar logic_conditions logic_expression logic_term
    boolean_term numeric_factor numeric_term expression if_statement
    code boolean_expression  else_block  assignment block for_loop enumerable list_of_number numeric_sequence
    string_expression string_term string_factor negative_number minus. 
    
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
    if_statement -> 'if' boolean_expression 'then' code else_block 'end'
    : {if_then_else, '$2', '$4', '$5'}.

    else_block -> 'else' block     : '$2'.
    else_block -> '$empty'.

%fors
    for_loop -> 'for' var '<-' enumerable 'do' block 'end' : {for_loop, '$2', '$4', '$6'}.
    enumerable -> var : {range,'$1'}.
    enumerable -> numeric_expression'..'numeric_expression : {range,{'$1', '$3'}}.
    enumerable -> list_of_number  : {range,'$1'}.


% assignment of variables
    assignment -> var '=' expression : {assignment, '$1', '$3'}.

% expressions
    expression -> numeric_expression        : '$1'.
    expression -> string_expression         : '$1'.

    %numeric expression
        %prioridad 3
        numeric_expression -> numeric_term  '+' numeric_expression  : {plus, '$1', '$3'}.
        numeric_expression -> numeric_term  minus                   : {plus, '$1', '$2'}.
            minus -> negative_number '+' numeric_expression         : {plus, '$1', '$3'}.
            minus -> negative_number minus                          : {plus, '$1', '$2'}.
            minus -> negative_number                                : '$1'.
            minus -> '(' negative_number ')'                        : '$2'.
            negative_number -> '-' numeric_factor                   : {negative, '$2'}.

        numeric_expression -> numeric_term                          : '$1'.   

        %prioridad 2
        numeric_term -> numeric_factor '*'  numeric_term            : {mult, '$1', '$3'}.
        numeric_term -> numeric_factor '/'  numeric_term            : {divi, '$1', '$3'}.
        numeric_term -> numeric_factor '//'  numeric_term           : {round_div, '$1', '$3'}.
        numeric_term -> numeric_factor '%'   numeric_term           : {mod, '$1', '$3'}.
        numeric_term -> numeric_factor '^'   numeric_term           : {pow, '$1', '$3'}.
        numeric_term -> numeric_factor                              : '$1'.
        numeric_term -> var                                         : '$1'.

        %prioridad 
        numeric_factor -> negative_number                           : '$1'.
        numeric_factor -> '(' numeric_expression ')'                : '$2'.
        numeric_factor -> dice                                      : '$1'.
        numeric_factor -> number                                    : '$1'.
        numeric_factor -> list_of_number                            : '$1'.
            list_of_number -> '[' numeric_sequence ']'                          : {list_of_number, '$2'}.
                numeric_sequence -> numeric_expression ',' numeric_sequence     : {'$1', '$3'}.
                numeric_sequence -> numeric_expression                          : '$1'.
                numeric_sequence -> '$empty'.


    %strings expressions
        string_expression -> string_term  '+' string_expression : {concat, '$1', '$3'}.
        string_expression -> string_term    : '$1'.
        string_term       -> string_factor  : '$1'.
        string_factor     -> string : '$1'.

%logic conditions
    logic_conditions -> boolean_expression : '$1'.
  
    logic_expression -> logic_conditions : '$1'.
    logic_expression -> expression : '$1'.

    logic_term-> boolean_term : '$1'.
    logic_term -> expression  : '$1'.

    %boolean expressions
        %prioridad 3
        boolean_expression -> boolean_term 'or'  logic_conditions : {or_operation, '$1', '$3'}.
        boolean_expression -> boolean_term 'and' logic_conditions : {and_operation, '$1', '$3'}.
        boolean_expression -> 'not'              logic_conditions : {not_operation, '$2'}.
        boolean_expression -> logic_term  '!='   logic_expression : {not_equal, '$1', '$3'}.       
        boolean_expression -> logic_term  '=='   logic_expression : {equal, '$1', '$3'}.
        boolean_expression -> logic_term  '>'    logic_expression : {stric_more, '$1', '$3'}.
        boolean_expression -> logic_term  '>='   logic_expression : {more_equal, '$1', '$3'}.
        boolean_expression -> logic_term  '<='   logic_expression : {less_equal, '$1', '$3'}.
        boolean_expression -> logic_term  '<'    logic_expression : {stric_less, '$1', '$3'}.
        boolean_expression -> boolean_term                        : '$1'.

        %prioridad 2
        boolean_term -> boolean_factor                             : '$1'.
        
        %prioridad 1
        boolean_factor -> '(' boolean_expression ')' : '$2'.
        boolean_factor -> boolean                    : '$1'.



