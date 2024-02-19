Nonterminals
arguments assignment assignment_function code else_code enumerable
function for_loop grammar index if_statement items_sequence list map parameters statement statements
map_sequence uminus uninot variable map_struct VAR E.

Terminals 'if' 'then' 'else' error not_defined boolean number name 'end' 'elseif' 'and' 'for' '..' '<-' 'd' 'do' 'or' 'not' '+' '++' '>'
 '=' '>=' '<' ';' ':' ',' '<=' '==' '!=' '-' '%' '*' '/' '//'  '[' ']' '{' '}' '(' ')' '^' string def_function.

Rootsymbol
    grammar.

%precedences
    Left 1 'or'.
    Left 1 'and'.
    
    Left 2 '=='.
    Left 2 '!='.
    
    Left 3 '<'.
    Left 3 '>'.
    Left 3 '<='.
    Left 3 '>='.
    
    Left 4 '++'.
    
    Left 5 '-'.
    Left 5 '+'.
    
    Left 6 '*'.
    Left 6 '/'.
    Left 6 '//'.
    Left 6 '%'.
  
    Right 7 '^'.

    Unary 8 uminus.
    Unary 8 index.
    Unary 8 uninot.
    Unary 10 name '('arguments')'.
    Unary 9 variable.

    Unary 10 list.
    Unary 10 map.

    Unary 11 string.
    Unary 11 number.
    Unary 11 boolean.


grammar -> code : '$1'.

code -> statements            : '$1'.
code -> not_defined           : '$1'.  
code -> '$empty'              : nil.
code -> error                 : '$1'.

%statements
    statements -> statement ';' statements   : {'$1', '$3'}. 
    statements -> statement statements       : {'$1', '$2'}.
    statements -> statement ';'              : '$1'.
    statements -> statement                  : '$1'.


    statement -> for_loop               : '$1'.
    statement -> E             : '$1'.
    statement -> assignment             : '$1'.
    statement -> if_statement           : '$1'.
    statement -> assignment_function    : '$1'.



%functions
    assignment_function ->  def_function name '(' parameters ')' 'do' code 'end': {assignment_function, {function_name, '$2'}, {parameters, '$4'}, {function_code, '$7'} }.
    
    parameters -> variable                 : '$1'.
    parameters -> variable ',' parameters  : {'$1', '$3'}.
    parameters -> '$empty'            : nil.


%ifs
    if_statement -> 'if' E 'then' code else_code 'end'
    : {if_then_else, '$2', '$4', '$5'}.

    else_code -> 'else' code     : '$2'.
    else_code -> 'elseif' E 'then' code else_code   : {if_then_else, '$2', '$4', '$5'}.
    else_code -> '$empty' : nil.

%fors
    for_loop -> 'for' variable '<-' enumerable 'do' code 'end' : {for_loop, '$2', '$4', '$6'}.
    
    enumerable -> variable                                  : {range,'$1'}.
    enumerable -> E'..'E  : {range,{'$1', '$3'}}.
    enumerable -> list                                      : {range,'$1'}.
    enumerable -> map                                       : {range,'$1'}.


% assignment of variables
    assignment -> name '=' statement: {assignment, '$1', '$3'}.

% Expressions
    E -> E '%'   E : {mod,           '$1', '$3'}.
    E -> E '^'   E : {pow,           '$1', '$3'}.
    E -> E '/'   E : {divi,          '$1', '$3'}.
    E -> E '*'   E : {mult,          '$1', '$3'}.
    E -> E '+'   E : {plus,          '$1', '$3'}.
    E -> E '=='  E : {equal,         '$1', '$3'}.
    E -> E '-'   E : {minus,         '$1', '$3'}.
    E -> E '++'  E : {concat,        '$1', '$3'}.
    E -> E '//'  E : {round_div,     '$1', '$3'}.
    E -> E '!='  E : {not_equal,     '$1', '$3'}.       
    E -> E '>'   E : {stric_more,    '$1', '$3'}.
    E -> E '>='  E : {more_equal,    '$1', '$3'}.
    E -> E '<='  E : {less_equal,    '$1', '$3'}.
    E -> E '<'   E : {stric_less,    '$1', '$3'}.
    E -> E 'or'  E : {or_operation,  '$1', '$3'}.
    E -> E 'and' E : {and_operation, '$1', '$3'}.
    E -> '('E')'   : '$2'.
    E -> VAR       : '$1'.
    E -> uminus    : '$1'.
    E -> number    : '$1'.
    E -> uninot    : '$1'.
    E -> boolean   : '$1'.
    E -> map       : '$1'.
    E -> list      : '$1'.
    E -> string    : '$1'.
    E -> index     : '$1'.

    index -> E '[' statement ']' : {index, '$1', '$3'}.

    uminus -> '-'   E : {negative, '$2'}. 
    uninot -> 'not' E : {not_operation, '$2'}.

    VAR -> function   : '$1'.
    VAR -> variable   : '$1'.
    
    function -> name '('arguments')' : {call_function,'$1' ,{parameters, '$3'}}.
    variable -> name                 : '$1'.   
    
    arguments -> E                   : '$1'.
    arguments -> E ',' arguments     : {'$1', '$3'}.
    arguments -> '$empty'            : nil.

    list -> '[' items_sequence ']'                              : {list, '$2'}.
                items_sequence -> statements ',' items_sequence : {'$1', '$3'}.
                items_sequence -> statements                    : '$1'.
                items_sequence -> '$empty'                      : nil.

    map -> '{' map_sequence '}'                             : {map, '$2'}.
                map_sequence -> map_struct ',' map_sequence : {'$1','$3'}.
                map_sequence -> map_struct                  : '$1'.
                map_sequence -> '$empty'           : nil.

    map_struct -> name ':' statements : {'$1','$3'}.