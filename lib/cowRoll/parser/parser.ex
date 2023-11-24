defmodule Parser do
  import NimbleParsec

  # expr   := term + expr | term - expr | term
  # termn := factor * term | factor / term | factor and term | factor or term | factor
  # factor := ( expr ) | not boolean | - number | number | boolean
  # number    := 0 | 1 | 2 | ...
  # boolean    := "true" | "false"

  # general
  whitespace = choice([string(" "), string("\n"), string("\t")])

  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")

  grouping =
    repeat(ignore(whitespace))
    |> ignore(lparen)
    |> parsec(:expr)
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
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:negation)
    |> label("negation")

  plus =
    parsec(:term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?+]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:expr))
    |> repeat(ignore(whitespace))
    |> tag(:plus)
    |> label("plus")

  minus =
    parsec(:term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?-]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:expr))
    |> repeat(ignore(whitespace))
    |> tag(:minus)
    |> label("minus")

  mult =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?*]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:mult)
    |> label("mult")

  div =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?/]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
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
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("and"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:and)
    |> label("and")

  or_ =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("or"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:or)
    |> label("or")

  stric_more =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string(">"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:stric_more)
    |> label(">")

  more_equal =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string(">="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:more_equal)
    |> label(">=")

  stric_less =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("<"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:stric_less)
    |> label("<")

  less_equal =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("<="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:less_equal)
    |> label("<=")

  equal =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("=="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:equal)
    |> label("==")

  not_equal =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("!="))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:not_equal)
    |> label("!=")

  # conditionals

  defcombinatorp(
    :condition,
    empty()
    |> parsec(:boolean_expression)
    |> tag(:condition)
    |> label("condition")
  )

  defcombinatorp(
    :then_expr,
    empty()
    |> parsec(:expr)
    |> tag(:then_expr)
    |> label("then expresion")
  )

  defcombinatorp(
    :else_expr,
    empty() |> parsec(:expr) |> tag(:else_expr) |> label("else expresion")
  )

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

  # factor := ( expr ) | not boolean | - number | number | boolean | if expr then expr else expr

  defcombinatorp(
    :factor,
    empty()
    |> choice(
      [
        grouping,
        not_,
        negation,
        number,
        boolean,
        if_statement
      ],
      gen_weights: [1, 2, 2, 3, 3, 4]
    )
  )

  # Termin := factor * term | factor / term | factor and term | factor or term | factor

  defcombinatorp(
    :term,
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

  # expr := term + expr | term - expr | term

  defcombinatorp(
    :expr,
    empty()
    |> choice(
      [
        plus,
        minus,
        parsec(:boolean_expression),
        parsec(:term)
      ],
      gen_weights: [1, 1, 2, 2]
    )
  )

  defcombinatorp(
    :boolean_expression,
    empty()
    |> choice(
      [
        stric_more,
        more_equal,
        stric_less,
        less_equal,
        equal,
        not_equal,
        and_,
        or_,
        boolean
      ],
      gen_weights: [1, 1, 1, 1, 1, 1, 1, 1, 2]
    )
  )

  defp fold_infixl(acc) do
    acc
    |> Enum.reverse()
    |> Enum.chunk_every(2)
    |> List.foldr([], fn
      [l], [] -> l
      [r, op], l -> {op, [l, r]}
    end)
  end

  defparsec(:parse, parsec(:expr))
end
