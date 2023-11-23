defmodule Parser do
  import NimbleParsec

  # expr   := term + expr | term - expr | term
  # termn := factor * term | factor / term | factor and term | factor or term | factor
  # factor := ( expr ) | not boolean | - number | integer | boolean
  # integer    := 0 | 1 | 2 | ...
  # boolean    := "true" | "false"

  # general
  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")

  whitespace = choice([string(" "), string("\n"), string("\t")])

  # arithmetic
  integer =
    repeat(ignore(whitespace))
    |> integer(min: 1)
    |> tag(:number)

  negation =
    repeat(ignore(whitespace))
    |> ignore(ascii_char([?-]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:negation)

  plus =
    parsec(:term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?+]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:expr))
    |> repeat(ignore(whitespace))
    |> tag(:plus)

  minus =
    parsec(:term)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?-]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:expr))
    |> repeat(ignore(whitespace))
    |> tag(:minus)

  mult =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?*]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:mult)

  div =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(ascii_char([?/]))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:div)

  # boolean
  true_ =
    repeat(ignore(whitespace))
    |> string("true")
    |> replace(true)

  false_ =
    repeat(ignore(whitespace))
    |> string("false")
    |> replace(false)

  boolean = choice([true_, false_]) |> tag(:boolean)

  not_ =
    repeat(ignore(whitespace))
    |> ignore(string("not"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:factor))
    |> repeat(ignore(whitespace))
    |> tag(:not)

  and_ =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("and"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:and)

  or_ =
    parsec(:factor)
    |> repeat(ignore(whitespace))
    |> ignore(string("or"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:term))
    |> repeat(ignore(whitespace))
    |> tag(:or)

  grouping = repeat(ignore(whitespace)) |> ignore(lparen) |> parsec(:expr) |> ignore(rparen)

  # conditionals

  defcombinatorp(
    :condition,
    empty()
    |> parsec(:expr)
    |> tag(:condition)
  )

  defcombinatorp(
    :then_expr,
    empty()
    |> parsec(:expr)
    |> tag(:then_expr)
  )

  defcombinatorp(
    :else_expr,
    empty()
    |> parsec(:expr)
    |> tag(:else_expr)
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

  if_then_else =
    if_then
    |> repeat(ignore(whitespace))
    |> ignore(string("else"))
    |> repeat(ignore(whitespace))
    |> concat(parsec(:else_expr))
    |> tag(:if_then_else)

  if_statement = choice([if_then_else, if_then])

  # factor := ( expr ) | not boolean | - number | integer | boolean | if expr then expr else expr

  defcombinatorp(
    :factor,
    empty()
    |> choice(
      [
        grouping,
        not_,
        negation,
        integer,
        boolean,
        if_statement
      ],
      gen_weights: [1, 1, 1, 2, 2, 3]
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
        and_,
        or_,
        parsec(:factor)
      ],
      gen_weights: [1, 1, 1, 1, 3]
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
        parsec(:term)
      ],
      gen_weights: [1, 1, 3]
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