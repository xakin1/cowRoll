defmodule Parser do
  import NimbleParsec

  integer =
    integer(min: 1)

  boolean = choice([string("false"), string("true")])

  whitespace = choice([string(" "), string("\n"), string("\t")])

  arithmetical_two_terms_operators =
    choice([string("-"), string("+"), string("/"), string("*"), string("^")])

  arithmetical_one_term_operators =
    choice([string("-"), string("+")])

  boolean_two_terms_operators =
    choice([
      string("and"),
      string("or"),
      string(">"),
      string(">="),
      string("<"),
      string("<="),
      string("=="),
      string("!=")
    ])

  boolean_one_terms_operators = string("!")

  arithmetical_two_terms_operations =
    integer
    |> repeat(ignore(whitespace))
    |> concat(arithmetical_two_terms_operators)
    |> repeat(ignore(whitespace))
    |> concat(integer)

  arithmetical_one_term_operations =
    arithmetical_one_term_operators
    |> repeat(ignore(whitespace))
    |> concat(integer)

  boolean_two_terms_operations =
    boolean
    |> repeat(ignore(whitespace))
    |> concat(boolean_two_terms_operators)
    |> repeat(ignore(whitespace))
    |> concat(boolean)

  boolean_one_term_operations =
    boolean_one_terms_operators
    |> repeat(ignore(whitespace))
    |> concat(boolean)

  code =
    choice([
      arithmetical_two_terms_operations,
      arithmetical_one_term_operations,
      boolean_two_terms_operations,
      boolean_one_term_operations
    ])

  defparsec(
    :parse,
    code
  )
end
