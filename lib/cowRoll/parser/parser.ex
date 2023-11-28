defmodule Parser do
  import NimbleParsec

  # code                ::= numeric_expression | boolean_expression | if_statement

  # expression          ::= numeric_expression | boolean_expression | term
  # term                ::= numeric_term | boolean_term | factor
  # factor              ::= numeric_factor | boolean_factor

  # if_statement        ::= if_then | if_then_else
  # if_then             ::= 'if' boolean_expression 'then' code
  # if_then_else        ::= 'if' boolean_expression 'then' code 'else' code

  # numeric_expression  ::= numeric_term ( ( '+' | '-' ) numeric_term )*
  # numeric_term        ::= numeric_factor ( ( '*' | '/' ) numeric_factor )*
  # numeric_factor      ::= '-'* ( '(' numeric_expression ')' | number )

  # boolean_expression  ::= boolean_term ( ( 'or' | 'and' ) boolean_expression )*
  # boolean_term        ::= compare_numbers | compare_booleans | compare_terms | boolean_factor
  # compare_numbers     ::= numeric_expression ( '>' | '>=' | '<' | '<=' | '!=' | '==' ) numeric_expression
  # compare_terms       ::= factor ( '!=' | '==' ) term
  # boolean_factor      ::= 'not'* ( '(' boolean_expression ')' | boolean )

  # boolean             ::= 'true' | 'false'
  # number              ::= '1' | '2' | '3' | '...'

  # general
  whitespace = choice([string(" "), string("\n"), string("\t")])

  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")

  numeric_grouping =
    repeat(ignore(whitespace))
    |> ignore(lparen)
    |> parsec(:numeric_expression)
    |> ignore(rparen)
    |> label("parenthesis")

  # arithmetic
  number =
    repeat(ignore(whitespace))
    |> integer(min: 1)
    |> tag(:number)
    |> label("number")

  negation =
    repeat(ignore(whitespace))
    |> ignore(ascii_char([?-]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:numeric_factor))
    |> repeat(ignore(whitespace))
    |> tag(:negation)
    |> label("negation")

  plus =
    parsec(:numeric_term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?+]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:numeric_expression))
    |> repeat(ignore(whitespace))
    |> tag(:plus)
    |> label("plus")

  minus =
    parsec(:numeric_term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?-]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:numeric_expression))
    |> repeat(ignore(whitespace))
    |> tag(:minus)
    |> label("minus")

  mult =
    parsec(:numeric_factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?*]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:numeric_term))
    |> repeat(ignore(whitespace))
    |> tag(:mult)
    |> label("mult")

  div =
    parsec(:numeric_factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?/]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:numeric_term))
    |> repeat(ignore(whitespace))
    |> tag(:div)
    |> label("div")

  # boolean
  true_ =
    repeat(ignore(whitespace)) |> string("true") |> replace(true) |> label("true")

  false_ =
    repeat(ignore(whitespace))
    |> string("false")
    |> replace(false)
    |> label("false")

  boolean_grouping =
    repeat(ignore(whitespace))
    |> ignore(lparen)
    |> parsec(:boolean_expression)
    |> ignore(rparen)
    |> label("parenthesis")

  boolean = choice([true_, false_]) |> tag(:boolean) |> label("boolean")

  not_ =
    repeat(ignore(whitespace))
    |> ignore(string("not"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:not)
    |> label("not")

  and_ =
    parsec(:boolean_term)
    |> repeat(ignore(whitespace))
    |> ignore(string("and"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:boolean_expression))
    |> repeat(ignore(whitespace))
    |> tag(:and)
    |> label("and")

  or_ =
    parsec(:boolean_term)
    |> repeat(ignore(whitespace))
    |> ignore(string("or"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:boolean_expression))
    |> repeat(ignore(whitespace))
    |> tag(:or)
    |> label("or")

  stric_more =
    parsec(:numeric_expression)
    |> repeat(ignore(whitespace))
    |> ignore(string(">"))
    |> parsec(:numeric_expression)
    |> tag(:stric_more)
    |> label(">")

  more_equal =
    parsec(:numeric_expression)
    |> repeat(ignore(whitespace))
    |> ignore(string(">="))
    |> parsec(:numeric_expression)
    |> tag(:more_equal)
    |> label(">=")

  stric_less =
    parsec(:numeric_expression)
    |> repeat(ignore(whitespace))
    |> ignore(string("<"))
    |> parsec(:numeric_expression)
    |> tag(:stric_less)
    |> label("<")

  less_equal =
    parsec(:numeric_expression)
    |> repeat(ignore(whitespace))
    |> ignore(string("<="))
    |> parsec(:numeric_expression)
    |> tag(:less_equal)
    |> label("<=")

  equal =
    ignore(string("=="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:equal)
    |> label("==")

  not_equal =
    ignore(string("!="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:not_equal)
    |> label("!=")

  # if statement

  if_then =
    repeat(ignore(whitespace))
    |> ignore(string("if"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:condition))
    |> repeat(ignore(whitespace))
    |> ignore(string("then"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:then_expr))
    |> tag(:if_then)
    |> label("if then")

  if_then_else =
    if_then
    |> repeat(ignore(whitespace))
    |> ignore(string("else"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:else_expr))
    |> tag(:if_then_else)
    |> label("if then else")

  if_statement = choice([if_then_else, if_then]) |> label("if statement")

  # code
  defcombinatorp(
    :code,
    empty()
    |> choice(
      [
        parsec(:boolean_expression),
        parsec(:numeric_expression),
        if_statement
      ],
      gen_weights: [1, 1, 1]
    )
  )

  # expresion
  defcombinatorp(
    :expression,
    empty()
    |> choice(
      [
        parsec(:numeric_expression),
        parsec(:boolean_expression),
        parsec(:term)
      ],
      gen_weights: [1, 1, 2]
    )
  )

  # term
  defcombinatorp(
    :term,
    empty()
    |> choice(
      [
        parsec(:numeric_term),
        parsec(:boolean_term),
        parsec(:factor)
      ],
      gen_weights: [1, 1, 2]
    )
  )

  # factor
  defcombinatorp(
    :factor,
    empty()
    |> choice(
      [
        parsec(:numeric_factor),
        parsec(:boolean_factor)
      ],
      gen_weights: [1, 1]
    )
  )

  # conditionals

  # condition
  defcombinatorp(
    :condition,
    empty()
    |> parsec(:boolean_expression)
    |> tag(:condition)
    |> label("condition")
  )

  # then_expresion
  defcombinatorp(
    :then_expr,
    empty()
    |> parsec(:code)
    |> tag(:then_expr)
    |> label("then expresion")
  )

  # else_expresion
  defcombinatorp(
    :else_expr,
    empty() |> parsec(:code) |> tag(:else_expr) |> label("else expresion")
  )

  defcombinatorp(
    :numeric_factor,
    empty()
    |> choice(
      [
        numeric_grouping,
        negation,
        number
      ],
      gen_weights: [1, 2, 3]
    )
  )

  defcombinatorp(
    :numeric_term,
    empty()
    |> choice(
      [
        mult,
        div,
        parsec(:factor)
      ],
      gen_weights: [1, 1, 3]
    )
  )

  defcombinatorp(
    :numeric_expression,
    empty()
    |> choice(
      [
        plus,
        minus,
        parsec(:numeric_term)
      ],
      gen_weights: [1, 1, 2]
    )
  )

  # boolean expresion
  defcombinatorp(
    :boolean_expression,
    empty()
    |> choice(
      [
        and_,
        or_,
        parsec(:boolean_term)
      ],
      gen_weights: [1, 1, 2]
    )
  )

  defcombinatorp(
    :boolean_term,
    empty()
    |> choice(
      [
        parsec(:compare_numbers),
        parsec(:compare_terms),
        parsec(:boolean_factor)
      ],
      gen_weights: [1, 1, 2]
    )
  )

  defcombinatorp(
    :compare_numbers,
    empty()
    |> choice(
      [
        stric_more,
        more_equal,
        stric_less,
        less_equal
      ],
      gen_weights: [1, 1, 1, 1]
    )
  )

  defcombinator(
    :left_term_compere_numbers,
    repeat(ignore(whitespace))
    |> parsec(:numeric_expression)
  )

  defcombinatorp(
    :compare_terms,
    empty()
    |> parsec(:term)
    |> repeat(ignore(whitespace))
    |> choice(
      [
        equal,
        not_equal
      ],
      gen_weights: [1, 1]
    )
  )

  defcombinatorp(
    :boolean_factor,
    empty()
    |> choice(
      [
        boolean_grouping,
        not_,
        boolean
      ],
      gen_weights: [1, 2, 3]
    )
  )

  defparsec(:parse, parsec(:code))
end
