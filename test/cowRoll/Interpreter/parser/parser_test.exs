defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "ifs" do
    test "parse if_then statemen" do
      input = "if false then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:boolean, false, 1}, {:number, 2, 1}, nil, {:if, 1}}
    end

    test "parse if_then_else statemen" do
      input = "if false or true then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:or_operation, {{:boolean, false, 1}, {:boolean, true, 1}}, {:or, 1}},
                {:number, 2, 1}, nil, {:if, 1}}
    end

    test "parse if_then statemen with conditions" do
      input = "if (4>7) == (true or false) then 2 end "
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal,
                 {{:strict_more, {{:number, 4, 1}, {:number, 7, 1}}, {:>, 1}},
                  {:or_operation, {{:boolean, true, 1}, {:boolean, false, 1}}, {:or, 1}}},
                 {:==, 1}}, {:number, 2, 1}, nil, {:if, 1}}
    end

    test "parse if_then statemen with code" do
      input = "
        x = 1;
        y = 3;
        if true then
          x = 2;
          y = y + x
        end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {{:assignment, {:name, "x", 2}, {:number, 1, 2}},
                {{:assignment, {:name, "y", 3}, {:number, 3, 3}},
                 {:if_then_else, {:boolean, true, 4},
                  {{:assignment, {:name, "x", 5}, {:number, 2, 5}},
                   {:assignment, {:name, "y", 6},
                    {:plus, {{:name, "y", 6}, {:name, "x", 6}}, {:+, 6}}}}, nil, {:if, 4}}}}
    end

    test "parse if_then_else statemen with conditions and returning differents types" do
      input = "if (4>7) == (true or false) then 2 else '3' end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal,
                 {{:strict_more, {{:number, 4, 1}, {:number, 7, 1}}, {:>, 1}},
                  {:or_operation, {{:boolean, true, 1}, {:boolean, false, 1}}, {:or, 1}}},
                 {:==, 1}}, {:number, 2, 1}, {:string, "'3'", 1}, {:if, 1}}
    end

    test "parse if_then_else statemen with conditions and nested if_then_else in the if" do
      input = "if (4>7) == (true or false) then if true then 2 else 1 end else 3+5 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal,
                 {{:strict_more, {{:number, 4, 1}, {:number, 7, 1}}, {:>, 1}},
                  {:or_operation, {{:boolean, true, 1}, {:boolean, false, 1}}, {:or, 1}}},
                 {:==, 1}},
                {:if_then_else, {:boolean, true, 1}, {:number, 2, 1}, {:number, 1, 1}, {:if, 1}},
                {:plus, {{:number, 3, 1}, {:number, 5, 1}}, {:+, 1}}, {:if, 1}}
    end

    test "parse if_then_else statemen with conditions and nested if_then_else in the if and else" do
      input =
        "if (4>7) == (true or false) then if true then 2 else 1 end else if false then 3+5 else 0 end end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal,
                 {{:strict_more, {{:number, 4, 1}, {:number, 7, 1}}, {:>, 1}},
                  {:or_operation, {{:boolean, true, 1}, {:boolean, false, 1}}, {:or, 1}}},
                 {:==, 1}},
                {:if_then_else, {:boolean, true, 1}, {:number, 2, 1}, {:number, 1, 1}, {:if, 1}},
                {:if_then_else, {:boolean, false, 1},
                 {:plus, {{:number, 3, 1}, {:number, 5, 1}}, {:+, 1}}, {:number, 0, 1}, {:if, 1}},
                {:if, 1}}
    end

    test "parse elseif" do
      input =
        "        if clase == 'Bárbaro' then
                        1
                  elseif clase == 'Bardo' then
                       2
                  elseif clase == 'Clérigo' then
                       3
                  elseif clase == 'Druida' then
                       4
                  elseif clase == 'Hechicero' then
                       5
                  elseif clase == 'Mago' then
                       6
                  else
                        0
                  end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {{:name, "clase", 1}, {:string, "'Bárbaro'", 1}}, {:==, 1}},
                {:number, 1, 2},
                {:if_then_else,
                 {:equal, {{:name, "clase", 3}, {:string, "'Bardo'", 3}}, {:==, 3}},
                 {:number, 2, 4},
                 {:if_then_else,
                  {:equal, {{:name, "clase", 5}, {:string, "'Clérigo'", 5}}, {:==, 5}},
                  {:number, 3, 6},
                  {:if_then_else,
                   {:equal, {{:name, "clase", 7}, {:string, "'Druida'", 7}}, {:==, 7}},
                   {:number, 4, 8},
                   {:if_then_else,
                    {:equal, {{:name, "clase", 9}, {:string, "'Hechicero'", 9}}, {:==, 9}},
                    {:number, 5, 10},
                    {:if_then_else,
                     {:equal, {{:name, "clase", 11}, {:string, "'Mago'", 11}}, {:==, 11}},
                     {:number, 6, 12}, {:number, 0, 14}, {:elseif, 11}}, {:elseif, 9}},
                   {:elseif, 7}}, {:elseif, 5}}, {:elseif, 3}}, {:if, 1}}
    end
  end

  describe "fors" do
    test "parse for" do
      input = "
      for x <- y do
        x = 2 + 1
      end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 2}, {:range, {:name, "y", 2}},
                {:assignment, {:name, "x", 3},
                 {:plus, {{:number, 2, 3}, {:number, 1, 3}}, {:+, 3}}}}

      input = "for x <- 1..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 1}, {:range, {{:number, 1, 1}, {:number, 3, 1}}},
                {:assignment, {:name, "x", 2},
                 {:plus, {{:number, 2, 2}, {:number, 1, 2}}, {:+, 2}}}}

      input = "for x <- [1,2,3] do
                  y = 2 + x
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 1},
                {:range, {:list, {{:number, 1, 1}, {{:number, 2, 1}, {:number, 3, 1}}}}},
                {:assignment, {:name, "y", 2},
                 {:plus, {{:number, 2, 2}, {:name, "x", 2}}, {:+, 2}}}}

      input = "for x <- {a: 1,b: 2,c: 3} do
                  y = 2 + x
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 1},
                {:range,
                 {:map,
                  {{{:name, "a", 1}, {:number, 1, 1}},
                   {{{:name, "b", 1}, {:number, 2, 1}}, {{:name, "c", 1}, {:number, 3, 1}}}}}},
                {:assignment, {:name, "y", 2},
                 {:plus, {{:number, 2, 2}, {:name, "x", 2}}, {:+, 2}}}}

      input = "for x <- y..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 1}, {:range, {{:name, "y", 1}, {:number, 3, 1}}},
                {:assignment, {:name, "x", 2},
                 {:plus, {{:number, 2, 2}, {:number, 1, 2}}, {:+, 2}}}}

      input = "for x <- y..z do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x", 1}, {:range, {{:name, "y", 1}, {:name, "z", 1}}},
                {:assignment, {:name, "x", 2},
                 {:plus, {{:number, 2, 2}, {:number, 1, 2}}, {:+, 2}}}}
    end

    test "fors with arrays" do
      input = "
      for i <- 0..3 do
        if (rolls[i] < rolls[min_index]) then
          min_index = i
        end
      end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "i", 2}, {:range, {{:number, 0, 2}, {:number, 3, 2}}},
                {:if_then_else,
                 {:strict_less,
                  {{:index, {{:name, "i", 3}, {:name, "rolls", 3}}},
                   {:index, {{:name, "min_index", 3}, {:name, "rolls", 3}}}}, {:<, 3}},
                 {:assignment, {:name, "min_index", 4}, {:name, "i", 4}}, nil, {:if, 3}}}
    end
  end

  describe "maps" do
    test "empty map" do
      input = "{}"
      {:ok, token} = Parser.parse(input)

      assert token == {:map, nil}
    end

    test "map with an numeric element" do
      input = "{a: 1}"
      {:ok, token} = Parser.parse(input)

      assert token == {:map, {{:name, "a", 1}, {:number, 1, 1}}}
    end

    test "map with two numeric elements" do
      input = "{a: 1, b: 2}"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map, {{{:name, "a", 1}, {:number, 1, 1}}, {{:name, "b", 1}, {:number, 2, 1}}}}
    end

    test "map with nested maps" do
      input = "{a: {a1: 2}, b: 2}"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map,
                {{{:name, "a", 1}, {:map, {{:name, "a1", 1}, {:number, 2, 1}}}},
                 {{:name, "b", 1}, {:number, 2, 1}}}}

      input = "{a: {a1: {vida_total: 2}}, b: 2}"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map,
                {{{:name, "a", 1},
                  {:map, {{:name, "a1", 1}, {:map, {{:name, "vida_total", 1}, {:number, 2, 1}}}}}},
                 {{:name, "b", 1}, {:number, 2, 1}}}}
    end

    test "map with n numeric elements" do
      input = "{a: 1, b: 2, c: 3, c: 9}"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map,
                {{{:name, "a", 1}, {:number, 1, 1}},
                 {{{:name, "b", 1}, {:number, 2, 1}},
                  {{{:name, "c", 1}, {:number, 3, 1}}, {{:name, "c", 1}, {:number, 9, 1}}}}}}
    end

    test "map with an string element" do
      input = " {a: '1'}"
      {:ok, token} = Parser.parse(input)

      assert token == {:map, {{:name, "a", 1}, {:string, "'1'", 1}}}
    end

    test "map with two string elements" do
      input = "{a: '1',b: \"2\"}"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map,
                {{{:name, "a", 1}, {:string, "'1'", 1}}, {{:name, "b", 1}, {:string, "\"2\"", 1}}}}
    end

    test "map with n mix elements and operations" do
      input =
        "{first: '1'++'2',second: 3+2*(3+3), third: '3',fourth: if true then 3 else 'r' end}"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:map,
                {{{:name, "first", 1},
                  {:concat, {{:string, "'1'", 1}, {:string, "'2'", 1}}, {:++, 1}}},
                 {{{:name, "second", 1},
                   {:plus,
                    {{:number, 3, 1},
                     {:mult,
                      {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 3, 1}}, {:+, 1}}},
                      {:*, 1}}}, {:+, 1}}},
                  {{{:name, "third", 1}, {:string, "'3'", 1}},
                   {{:name, "fourth", 1},
                    {:if_then_else, {:boolean, true, 1}, {:number, 3, 1}, {:string, "'r'", 1},
                     {:if, 1}}}}}}}
    end

    test "map with string index" do
      input = "x = {a: '1',b: \"2\"}
      x['a']"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {{:assignment, {:name, "x", 1},
                 {:map,
                  {{{:name, "a", 1}, {:string, "'1'", 1}},
                   {{:name, "b", 1}, {:string, "\"2\"", 1}}}}},
                {:index, {{:string, "'a'", 2}, {:name, "x", 2}}}}
    end

    test "map with index" do
      input =
        "{first: '1'++'2',second: 3+2*(3+3), third: '3',fourth: if true then 3 else 'r' end}[1]"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:number, 1, 1},
                 {:map,
                  {{{:name, "first", 1},
                    {:concat, {{:string, "'1'", 1}, {:string, "'2'", 1}}, {:++, 1}}},
                   {{{:name, "second", 1},
                     {:plus,
                      {{:number, 3, 1},
                       {:mult,
                        {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 3, 1}}, {:+, 1}}},
                        {:*, 1}}}, {:+, 1}}},
                    {{{:name, "third", 1}, {:string, "'3'", 1}},
                     {{:name, "fourth", 1},
                      {:if_then_else, {:boolean, true, 1}, {:number, 3, 1}, {:string, "'r'", 1},
                       {:if, 1}}}}}}}}}
    end
  end

  describe "boolean expressions" do
    test "parse boolean" do
      input = "true"
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, true, 1}

      input = "false"
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, false, 1}
    end

    test "parse and" do
      # input = "false and false"
      # {:ok, token} = Parser.parse(input)

      # assert token == {:and_operation, {:boolean, false,1}, {:boolean, false,1}}

      input = "(3>4) and false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {{:strict_more, {{:number, 3, 1}, {:number, 4, 1}}, {:>, 1}},
                 {:boolean, false, 1}}, {:and, 1}}
    end

    test "parse and with multiples factors" do
      input = "false and false and false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {{:and_operation, {{:boolean, false, 1}, {:boolean, false, 1}}, {:and, 1}},
                 {:boolean, false, 1}}, {:and, 1}}

      input = "(3>4) and false and (4<3 and true)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {{:and_operation,
                  {{:strict_more, {{:number, 3, 1}, {:number, 4, 1}}, {:>, 1}},
                   {:boolean, false, 1}}, {:and, 1}},
                 {:and_operation,
                  {{:strict_less, {{:number, 4, 1}, {:number, 3, 1}}, {:<, 1}},
                   {:boolean, true, 1}}, {:and, 1}}}, {:and, 1}}
    end

    test "parse or" do
      input = "true or true"
      {:ok, token} = Parser.parse(input)

      assert token == {:or_operation, {{:boolean, true, 1}, {:boolean, true, 1}}, {:or, 1}}

      input = "(3 > 4) or false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation,
                {{:strict_more, {{:number, 3, 1}, {:number, 4, 1}}, {:>, 1}},
                 {:boolean, false, 1}}, {:or, 1}}

      input = "(4>7) == (true or false)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal,
                {{:strict_more, {{:number, 4, 1}, {:number, 7, 1}}, {:>, 1}},
                 {:or_operation, {{:boolean, true, 1}, {:boolean, false, 1}}, {:or, 1}}},
                {:==, 1}}
    end

    test "parse or with multiples factors" do
      input = "false or false or false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation,
                {{:or_operation, {{:boolean, false, 1}, {:boolean, false, 1}}, {:or, 1}},
                 {:boolean, false, 1}}, {:or, 1}}

      input = "(3>4) or false or (4<3 or true)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation,
                {{:or_operation,
                  {{:strict_more, {{:number, 3, 1}, {:number, 4, 1}}, {:>, 1}},
                   {:boolean, false, 1}}, {:or, 1}},
                 {:or_operation,
                  {{:strict_less, {{:number, 4, 1}, {:number, 3, 1}}, {:<, 1}},
                   {:boolean, true, 1}}, {:or, 1}}}, {:or, 1}}
    end

    test "parse not" do
      input = "not true"
      {:ok, token} = Parser.parse(input)

      assert token == {:not_operation, {:boolean, true, 1}, {:not, 1}}

      input = "not false"
      {:ok, token} = Parser.parse(input)

      assert token == {:not_operation, {:boolean, false, 1}, {:not, 1}}
    end

    test "parse not with operation" do
      input = "not (true == (5<6))"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:not_operation,
                {:equal,
                 {{:boolean, true, 1},
                  {:strict_less, {{:number, 5, 1}, {:number, 6, 1}}, {:<, 1}}}, {:==, 1}},
                {:not, 1}}
    end

    test "parse compare" do
      input = "true < false"
      {:ok, token} = Parser.parse(input)

      assert token == {:strict_less, {{:boolean, true, 1}, {:boolean, false, 1}}, {:<, 1}}

      input = "true > false"
      {:ok, token} = Parser.parse(input)

      assert token == {:strict_more, {{:boolean, true, 1}, {:boolean, false, 1}}, {:>, 1}}

      input = "true >= false"
      {:ok, token} = Parser.parse(input)

      assert token == {:more_equal, {{:boolean, true, 1}, {:boolean, false, 1}}, {:>=, 1}}

      input = "true <= false"
      {:ok, token} = Parser.parse(input)

      assert token == {:less_equal, {{:boolean, true, 1}, {:boolean, false, 1}}, {:<=, 1}}

      input = "3 > 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:strict_more, {{:number, 3, 1}, {:number, 4, 1}}, {:>, 1}}

      input = "3 < 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:strict_less, {{:number, 3, 1}, {:number, 4, 1}}, {:<, 1}}

      input = "3 >= 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:more_equal, {{:number, 3, 1}, {:number, 4, 1}}, {:>=, 1}}

      input = "3 <= 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:less_equal, {{:number, 3, 1}, {:number, 4, 1}}, {:<=, 1}}

      input = "3 + 9 <= (2 - 1)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal,
                {{:plus, {{:number, 3, 1}, {:number, 9, 1}}, {:+, 1}},
                 {:minus, {{:number, 2, 1}, {:number, 1, 1}}, {:-, 1}}}, {:<=, 1}}
    end

    test "parse compare multiple factors" do
      input = "4 > 3 + 9 <= (2 - 1)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal,
                {{:strict_more,
                  {{:number, 4, 1}, {:plus, {{:number, 3, 1}, {:number, 9, 1}}, {:+, 1}}},
                  {:>, 1}}, {:minus, {{:number, 2, 1}, {:number, 1, 1}}, {:-, 1}}}, {:<=, 1}}
    end

    test "parse equals" do
      input = "3 == 3"
      {:ok, token} = Parser.parse(input)

      assert token == {:equal, {{:number, 3, 1}, {:number, 3, 1}}, {:==, 1}}

      input = "3 == (5>6)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal,
                {{:number, 3, 1}, {:strict_more, {{:number, 5, 1}, {:number, 6, 1}}, {:>, 1}}},
                {:==, 1}}
    end

    test "parse equals with multiple factors" do
      input = "3==3==4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal, {{:equal, {{:number, 3, 1}, {:number, 3, 1}}, {:==, 1}}, {:number, 4, 1}},
                {:==, 1}}
    end

    test "parse equals string number and boolean" do
      input = "'no soy igual'== 3 == false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal,
                {{:equal, {{:string, "'no soy igual'", 1}, {:number, 3, 1}}, {:==, 1}},
                 {:boolean, false, 1}}, {:==, 1}}
    end

    test "parse parenthesis" do
      input = "(false) "
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, false, 1}

      input = "(false or true) "
      {:ok, token} = Parser.parse(input)

      assert token == {:or_operation, {{:boolean, false, 1}, {:boolean, true, 1}}, {:or, 1}}

      input = "(true == (5<6))"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal,
                {{:boolean, true, 1},
                 {:strict_less, {{:number, 5, 1}, {:number, 6, 1}}, {:<, 1}}}, {:==, 1}}

      input = "(4 > 3 + 9 <= (2 - 1))"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal,
                {{:strict_more,
                  {{:number, 4, 1}, {:plus, {{:number, 3, 1}, {:number, 9, 1}}, {:+, 1}}},
                  {:>, 1}}, {:minus, {{:number, 2, 1}, {:number, 1, 1}}, {:-, 1}}}, {:<=, 1}}
    end

    test "parse complex boolean expression" do
      input = "((3 + 5 * 2)  / 2^3 + 9%17 == 1 and 6 - 2 >= 3)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {{:equal,
                  {{:plus,
                    {{:divi,
                      {{:plus,
                        {{:number, 3, 1}, {:mult, {{:number, 5, 1}, {:number, 2, 1}}, {:*, 1}}},
                        {:+, 1}}, {:pow, {{:number, 2, 1}, {:number, 3, 1}}, {:^, 1}}}, {:/, 1}},
                     {:mod, {{:number, 9, 1}, {:number, 17, 1}}, {:%, 1}}}, {:+, 1}},
                   {:number, 1, 1}}, {:==, 1}},
                 {:more_equal,
                  {{:minus, {{:number, 6, 1}, {:number, 2, 1}}, {:-, 1}}, {:number, 3, 1}},
                  {:>=, 1}}}, {:and, 1}}
    end
  end

  describe "strings" do
    test "parse string with \"" do
      input = "\"hola mundo\""
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "\"hola mundo\"", 1}
    end

    test "parse string with ''" do
      input = "'hola mundo'"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "'hola mundo'", 1}
    end

    test "parse string with '' with index" do
      input = "'hola mundo'[1]"
      {:ok, token} = Parser.parse(input)
      assert token == {:index, {{:number, 1, 1}, {:string, "'hola mundo'", 1}}}
    end

    test "parse string with '' with an operation in the index" do
      input = "'hola mundo'[1+3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:plus, {{:number, 1, 1}, {:number, 3, 1}}, {:+, 1}},
                 {:string, "'hola mundo'", 1}}}
    end

    test "parse string with a number" do
      input = "'1'"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "'1'", 1}
    end

    test "parse empty string" do
      input = "''"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "''", 1}
    end

    test "concat string" do
      input = "\"hola \" ++ \"mundo\""
      {:ok, token} = Parser.parse(input)
      assert token == {:concat, {{:string, "\"hola \"", 1}, {:string, "\"mundo\"", 1}}, {:++, 1}}
    end

    test "concat n strings" do
      input = "\"hola \" ++ \"mundo\" ++ \", 2\" ++ \"\""
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:concat,
                {{:concat,
                  {{:concat, {{:string, "\"hola \"", 1}, {:string, "\"mundo\"", 1}}, {:++, 1}},
                   {:string, "\", 2\"", 1}}, {:++, 1}}, {:string, "\"\"", 1}}, {:++, 1}}
    end
  end

  describe "lists" do
    test "empty array" do
      input = "[]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, nil}
    end

    test "array with an numeric element" do
      input = "[1]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {:number, 1, 1}}
    end

    test "array with two numeric elements" do
      input = "[1,2]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {{:number, 1, 1}, {:number, 2, 1}}}
    end

    test "array with nested arrays" do
      input = "[[1],2]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {{:list, {:number, 1, 1}}, {:number, 2, 1}}}
    end

    test "array with n numeric elements" do
      input = "[1,2,3,3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list, {{:number, 1, 1}, {{:number, 2, 1}, {{:number, 3, 1}, {:number, 3, 1}}}}}
    end

    test "array with an string element" do
      input = "['1']"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {:string, "'1'", 1}}
    end

    test "array with index" do
      input = "[1-1][2]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:number, 2, 1}, {:list, {:minus, {{:number, 1, 1}, {:number, 1, 1}}, {:-, 1}}}}}
    end

    test "array with an operation in the index" do
      input = "['1',2,3,4,5,6][2+3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:plus, {{:number, 2, 1}, {:number, 3, 1}}, {:+, 1}},
                 {:list,
                  {{:string, "'1'", 1},
                   {{:number, 2, 1},
                    {{:number, 3, 1}, {{:number, 4, 1}, {{:number, 5, 1}, {:number, 6, 1}}}}}}}}}
    end

    test "ifs with index" do
      input = "rolls[i] < rolls[min_index]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:strict_less,
                {{:index, {{:name, "i", 1}, {:name, "rolls", 1}}},
                 {:index, {{:name, "min_index", 1}, {:name, "rolls", 1}}}}, {:<, 1}}
    end

    test "index an nested array" do
      input = "[[1,2],3,[4,5],6][1][0]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:index, {{:number, 1, 1}, {:number, 0, 1}}},
                 {:list,
                  {{:list, {{:number, 1, 1}, {:number, 2, 1}}},
                   {{:number, 3, 1},
                    {{:list, {{:number, 4, 1}, {:number, 5, 1}}}, {:number, 6, 1}}}}}}}
    end

    test "array with an operator in index" do
      input =
        "
      raza = razas[3+5]"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:assignment, {:name, "raza", 2},
                {:index,
                 {{:plus, {{:number, 3, 2}, {:number, 5, 2}}, {:+, 2}}, {:name, "razas", 2}}}}
    end

    test "array with an operation in index" do
      input = "['1'][2+3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:index,
                {{:plus, {{:number, 2, 1}, {:number, 3, 1}}, {:+, 1}},
                 {:list, {:string, "'1'", 1}}}}
    end

    test "array with two string elements" do
      input = "['1',\"2\"]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {{:string, "'1'", 1}, {:string, "\"2\"", 1}}}
    end

    test "array with n string elements" do
      input = "['1','2','3','3']"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list,
                {{:string, "'1'", 1},
                 {{:string, "'2'", 1}, {{:string, "'3'", 1}, {:string, "'3'", 1}}}}}
    end

    test "array with n mix elements" do
      input = "['1',2,'3',true]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list,
                {{:string, "'1'", 1},
                 {{:number, 2, 1}, {{:string, "'3'", 1}, {:boolean, true, 1}}}}}
    end

    test "array with n mix elements and operations" do
      input = "['1'++'2',3+2*(3+3),'3', if true then 3 else 'r' end]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list,
                {{:concat, {{:string, "'1'", 1}, {:string, "'2'", 1}}, {:++, 1}},
                 {{:plus,
                   {{:number, 3, 1},
                    {:mult,
                     {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 3, 1}}, {:+, 1}}},
                     {:*, 1}}}, {:+, 1}},
                  {{:string, "'3'", 1},
                   {:if_then_else, {:boolean, true, 1}, {:number, 3, 1}, {:string, "'r'", 1},
                    {:if, 1}}}}}}
    end

    test "concat arrays" do
      input = "[2,3,1] ++ [4,3]"
      {:ok, result} = Parser.parse(input)

      assert result ==
               {:concat,
                {{:list, {{:number, 2, 1}, {{:number, 3, 1}, {:number, 1, 1}}}},
                 {:list, {{:number, 4, 1}, {:number, 3, 1}}}}, {:++, 1}}
    end

    test "substract arrays" do
      input = "[2,3,1] -- [4,3]"
      {:ok, result} = Parser.parse(input)

      assert result ==
               {:subtract,
                {{:list, {{:number, 2, 1}, {{:number, 3, 1}, {:number, 1, 1}}}},
                 {:list, {{:number, 4, 1}, {:number, 3, 1}}}}, {:--, 1}}
    end
  end

  describe "plus" do
    test "parse plus operation" do
      input = "1+1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}

      input = "1+ 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}

      input = "1 +1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}

      input = "1 + 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}

      input = " 1 + 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}

      input = " 1 + 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}
    end

    test "parse plus operation with n operators" do
      input = "1+1+3+4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {{:plus, {{:plus, {{:number, 1, 1}, {:number, 1, 1}}, {:+, 1}}, {:number, 3, 1}},
                  {:+, 1}}, {:number, 4, 1}}, {:+, 1}}
    end
  end

  describe "negative" do
    test "parse negative operation" do
      input = "- 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1, 1}, {:-, 1}}
    end

    test "parse negation of negation" do
      input = "- - 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:negative, {:number, 1, 1}, {:-, 1}}, {:-, 1}}
    end

    test "parse negation inside parenthesis" do
      input = "(- 1)"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1, 1}, {:-, 1}}
    end

    test "parse negation outside parenthesis" do
      input = "-( 1)"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1, 1}, {:-, 1}}
    end

    test "test negative in a operation with and without parenthesis" do
      input = "1+ (-3) +3 -2 +4 "
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {{:minus,
                  {{:plus,
                    {{:plus, {{:number, 1, 1}, {:negative, {:number, 3, 1}, {:-, 1}}}, {:+, 1}},
                     {:number, 3, 1}}, {:+, 1}}, {:number, 2, 1}}, {:-, 1}}, {:number, 4, 1}},
                {:+, 1}}
    end
  end

  describe "minus" do
    test "parse minus operation" do
      input = "1 - 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:minus, {{:number, 1, 1}, {:number, 1, 1}}, {:-, 1}}
    end

    test "parse minus minus operation" do
      input = "(-3 +3 -2 *3)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:minus,
                {{:plus, {{:negative, {:number, 3, 1}, {:-, 1}}, {:number, 3, 1}}, {:+, 1}},
                 {:mult, {{:number, 2, 1}, {:number, 3, 1}}, {:*, 1}}}, {:-, 1}}
    end

    test "parse minus operation with n operators" do
      input = "1-1-3-4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:minus,
                {{:minus,
                  {{:minus, {{:number, 1, 1}, {:number, 1, 1}}, {:-, 1}}, {:number, 3, 1}},
                  {:-, 1}}, {:number, 4, 1}}, {:-, 1}}
    end
  end

  describe "multiplication" do
    test "parse mult operation" do
      input = "1*1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}

      input = "1* 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}

      input = "1 *1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}

      input = "1 * 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}

      input = " 1 * 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}

      input = " 1 * 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}
    end

    test "parse mult operation with n operators" do
      input = "1*1*3*4+5"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {{:mult,
                  {{:mult,
                    {{:mult, {{:number, 1, 1}, {:number, 1, 1}}, {:*, 1}}, {:number, 3, 1}},
                    {:*, 1}}, {:number, 4, 1}}, {:*, 1}}, {:number, 5, 1}}, {:+, 1}}
    end
  end

  describe "division " do
    test "parse div operation" do
      input = "1/1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}

      input = "1/ 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}

      input = "1 /1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}

      input = "1 / 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}

      input = " 1 / 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}

      input = " 1 / 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {{:number, 1, 1}, {:number, 1, 1}}, {:/, 1}}
    end
  end

  describe "pow" do
    test "parse simple pow" do
      input = "2^3"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {{:number, 2, 1}, {:number, 3, 1}}, {:^, 1}}

      input = "2^-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {{:number, 2, 1}, {:negative, {:number, 1, 1}, {:-, 1}}}, {:^, 1}}

      input = "-2^1"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {{:negative, {:number, 2, 1}, {:-, 1}}, {:number, 1, 1}}, {:^, 1}}

      input = "-2^-1"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow,
                {{:negative, {:number, 2, 1}, {:-, 1}}, {:negative, {:number, 1, 1}, {:-, 1}}},
                {:^, 1}}
    end

    test "parse concat pows" do
      input = "2^2^2^2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow,
                {{:number, 2, 1},
                 {:pow, {{:number, 2, 1}, {:pow, {{:number, 2, 1}, {:number, 2, 1}}, {:^, 1}}},
                  {:^, 1}}}, {:^, 1}}
    end

    test "parse pows with operations" do
      input = "(3+2)^2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {{:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}, {:number, 2, 1}},
                {:^, 1}}

      input = "2^(3+2)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}},
                {:^, 1}}

      input = "2^(3+2)^2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow,
                {{:number, 2, 1},
                 {:pow, {{:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}, {:number, 2, 1}},
                  {:^, 1}}}, {:^, 1}}
    end
  end

  describe "mod" do
    test "parse simple mod" do
      input = "2%3"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {{:number, 2, 1}, {:number, 3, 1}}, {:%, 1}}

      input = "2%-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {{:number, 2, 1}, {:negative, {:number, 1, 1}, {:-, 1}}}, {:%, 1}}

      input = "-2%1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {{:negative, {:number, 2, 1}, {:-, 1}}, {:number, 1, 1}}, {:%, 1}}

      input = "-2%-1"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod,
                {{:negative, {:number, 2, 1}, {:-, 1}}, {:negative, {:number, 1, 1}, {:-, 1}}},
                {:%, 1}}
    end

    test "parse concat mods" do
      input = "2%2%3%4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod,
                {{:mod, {{:mod, {{:number, 2, 1}, {:number, 2, 1}}, {:%, 1}}, {:number, 3, 1}},
                  {:%, 1}}, {:number, 4, 1}}, {:%, 1}}
    end

    test "parse mods with operations" do
      input = "(3+2)%2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {{:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}, {:number, 2, 1}},
                {:%, 1}}

      input = "2%(3+2)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}},
                {:%, 1}}

      input = "2%(3+2)%2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod,
                {{:mod, {{:number, 2, 1}, {:plus, {{:number, 3, 1}, {:number, 2, 1}}, {:+, 1}}},
                  {:%, 1}}, {:number, 2, 1}}, {:%, 1}}
    end
  end

  describe "round division" do
    test "parse div operation" do
      input = "1//2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}

      input = "1//2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}

      input = "1 //2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}

      input = "1 // 2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}

      input = " 1 // 2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}

      input = " 1 // 2 "
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {{:number, 1, 1}, {:number, 2, 1}}, {:"//", 1}}
    end
  end

  describe "variables" do
    test "parse var" do
      input =
        "x"

      {:ok, token} = Parser.parse(input)

      assert token == {:name, "x", 1}

      input =
        "hola"

      {:ok, token} = Parser.parse(input)

      assert token == {:name, "hola", 1}
    end

    test "parse assignament" do
      input = "x = 6"
      {:ok, token} = Parser.parse(input)

      assert token == {:assignment, {:name, "x", 1}, {:number, 6, 1}}
    end

    test "array assignment with index" do
      input = "x = ['1',2,3,4,5,6]
      x[0] = 1
      x"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {{:assignment, {:name, "x", 1},
                 {:list,
                  {{:string, "'1'", 1},
                   {{:number, 2, 1},
                    {{:number, 3, 1}, {{:number, 4, 1}, {{:number, 5, 1}, {:number, 6, 1}}}}}}}},
                {{:assignment, {:index, {{:number, 0, 2}, {:name, "x", 2}}}, {:number, 1, 2}},
                 {:name, "x", 3}}}
    end

    test "parse assignament with result of function" do
      input = "numero_de_razas = contar_longitud(razas)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:assignment, {:name, "numero_de_razas", 1},
                {:call_function, {:name, "contar_longitud", 1},
                 {:parameters, {:name, "razas", 1}}}}
    end
  end

  describe "functions" do
    test "parse basic function" do
      input = "function hola_mundo () do
        'hola mundo'
      end"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:assignment_function, {:function_name, {:name, "hola_mundo", 1}},
                {:parameters, nil}, {:function_code, {:string, "'hola mundo'", 2}}}
    end

    test "parse recursivity" do
      :rand.seed(:exsplus, {1, 2, 3})
      input = "
      function roll_dices(number_of_dices, number_of_face) do
        if (number_of_dices<0 or number_of_face <0 ) then
          -1
        else
          roll = rand(number_of_face)
          roll + roll_dices(number_of_dices - 1, number_of_face)
        end
      end"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:assignment_function, {:function_name, {:name, "roll_dices", 2}},
                {:parameters, {{:name, "number_of_dices", 2}, {:name, "number_of_face", 2}}},
                {:function_code,
                 {:if_then_else,
                  {:or_operation,
                   {{:strict_less, {{:name, "number_of_dices", 3}, {:number, 0, 3}}, {:<, 3}},
                    {:strict_less, {{:name, "number_of_face", 3}, {:number, 0, 3}}, {:<, 3}}},
                   {:or, 3}}, {:negative, {:number, 1, 4}, {:-, 4}},
                  {{:assignment, {:name, "roll", 6},
                    {:call_function, {:name, "rand", 6},
                     {:parameters, {:name, "number_of_face", 6}}}},
                   {:plus,
                    {{:name, "roll", 7},
                     {:call_function, {:name, "roll_dices", 7},
                      {:parameters,
                       {{:minus, {{:name, "number_of_dices", 7}, {:number, 1, 7}}, {:-, 7}},
                        {:name, "number_of_face", 7}}}}}, {:+, 7}}}, {:if, 3}}}}
    end

    test "parse basic function with parameters" do
      input = "function hola_mundo (msg, range) do
        for participants <- range do
          msg
        end
      end"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:assignment_function, {:function_name, {:name, "hola_mundo", 1}},
                {:parameters, {{:name, "msg", 1}, {:name, "range", 1}}},
                {:function_code,
                 {:for_loop, {:name, "participants", 2}, {:range, {:name, "range", 2}},
                  {:name, "msg", 3}}}}
    end

    test "apply correctly order" do
      {:ok, token} = Parser.parse("
          function f() do
               5+4
          end
          1-f()
     ")

      assert token ==
               {{:assignment_function, {:function_name, {:name, "f", 2}}, {:parameters, nil},
                 {:function_code, {:plus, {{:number, 5, 3}, {:number, 4, 3}}, {:+, 3}}}},
                {:minus, {{:number, 1, 5}, {:call_function, {:name, "f", 5}, {:parameters, nil}}},
                 {:-, 5}}}
    end

    test "parse basic call function without parameters" do
      input = "hola_mundo()"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:call_function, {:name, "hola_mundo", 1}, {:parameters, nil}}
    end

    test "parse basic call function with parameters" do
      input = "hola_mundo('hola mundo ', 2)"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:call_function, {:name, "hola_mundo", 1},
                {:parameters, {{:string, "'hola mundo '", 1}, {:number, 2, 1}}}}
    end

    test "function in an assignament" do
      input = "x = function hola() do 1 end"
      {:ok, result} = Parser.parse(input)

      assert result ==
               {:assignment, {:name, "x", 1},
                {:assignment_function, {:function_name, {:name, "hola", 1}}, {:parameters, nil},
                 {:function_code, {:number, 1, 1}}}}
    end
  end

  describe "statements" do
    test "parse sentences" do
      input =
        "x = 2;
        y= 3;
        z= 4+x;"

      {:ok, token} = Parser.parse(input)

      expect =
        {{:assignment, {:name, "x", 1}, {:number, 2, 1}},
         {{:assignment, {:name, "y", 2}, {:number, 3, 2}},
          {:assignment, {:name, "z", 3}, {:plus, {{:number, 4, 3}, {:name, "x", 3}}, {:+, 3}}}}}

      assert token == expect

      input =
        "x = 2
        y= 3
        z= 4+x"

      {:ok, token} = Parser.parse(input)
      assert token == expect

      input =
        "x= 6; y = x + 2; x = x +2; z = x+y"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {{:assignment, {:name, "x", 1}, {:number, 6, 1}},
                {{:assignment, {:name, "y", 1},
                  {:plus, {{:name, "x", 1}, {:number, 2, 1}}, {:+, 1}}},
                 {{:assignment, {:name, "x", 1},
                   {:plus, {{:name, "x", 1}, {:number, 2, 1}}, {:+, 1}}},
                  {:assignment, {:name, "z", 1},
                   {:plus, {{:name, "x", 1}, {:name, "y", 1}}, {:+, 1}}}}}}
    end
  end

  describe "numeric expressions" do
    test "parse integer" do
      input = "1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1, 1}

      input = "1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1, 1}

      input = " 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1, 1}

      input = " 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1, 1}
    end

    test "parse with vars" do
      input = "
      x+y"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {{:name, "x", 2}, {:name, "y", 2}}, {:+, 2}}
    end

    test "parse with functions" do
      input = "
      x*y()"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mult, {{:name, "x", 2}, {:call_function, {:name, "y", 2}, {:parameters, nil}}},
                {:*, 2}}
    end

    test "parse with assignment" do
      input = "
      z= 4+x"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:assignment, {:name, "z", 2},
                {:plus, {{:number, 4, 2}, {:name, "x", 2}}, {:+, 2}}}
    end
  end
end
