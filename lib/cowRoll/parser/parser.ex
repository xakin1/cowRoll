defmodule Parser do
  import NimbleParsec

  # expr   := term + expr | term - expr | term
  # term   := factor * term | factor / term |factor
  # factor := ( expr ) | integer
  # integer    := 0 | 1 | 2 | ...

  whitespace = choice([string(" "), string("\n"), string("\t")])

  integer =
    repeat(ignore(whitespace))
    |> integer(min: 1)

  factor =
    empty()
    |> choice(
      [
        repeat(ignore(whitespace))
        |> ignore(ascii_char([?(]))
        |> repeat(ignore(whitespace))
        |> concat(parsec(:expr))
        |> repeat(ignore(whitespace))
        |> ignore(ascii_char([?)])),
        integer
      ],
      gen_weights: [1, 1]
    )

  # Recursive definitions require using defparsec with the parsec combinator

  defcombinatorp(
    :term,
    empty()
    |> choice(
      [
        factor
        |> repeat(ignore(whitespace))
        |> ignore(ascii_char([?*]))
        |> repeat(ignore(whitespace))
        |> concat(parsec(:term))
        |> repeat(ignore(whitespace))
        |> tag(:mult),
        factor
        |> repeat(ignore(whitespace))
        |> ignore(ascii_char([?/]))
        |> repeat(ignore(whitespace))
        |> concat(parsec(:term))
        |> repeat(ignore(whitespace))
        |> tag(:div),
        factor
      ],
      gen_weights: [1, 1, 3]
    )
  )

  defcombinatorp(
    :expr,
    empty()
    |> choice(
      [
        parsec(:term)
        |> repeat(ignore(whitespace))
        |> ignore(ascii_char([?+]))
        |> repeat(ignore(whitespace))
        |> concat(parsec(:expr))
        |> repeat(ignore(whitespace))
        |> tag(:plus),
        parsec(:term)
        |> repeat(ignore(whitespace))
        |> ignore(ascii_char([?-]))
        |> repeat(ignore(whitespace))
        |> concat(parsec(:expr))
        |> repeat(ignore(whitespace))
        |> tag(:minus),
        parsec(:term)
      ],
      gen_weights: [1, 1, 3]
    )
  )

  defparsec(:parse, parsec(:expr))
end
