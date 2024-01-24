defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  # describe "lexical error" do
  #   test "error missing right parenthesis" do
  #     input = "(3+ 2"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error ->
  #         assert error == {:error, "error at the end of: (3+ in line 1"}
  #     end

  #     input = "(true"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error ->
  #         assert error == {:error, "error at the end of: (true in line 1"}
  #     end

  #     input = "('gl'"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error ->
  #         assert error == {:error, "error at the end of: ('gl' in line 1"}
  #     end

  #     input = "(3+ (2 - (5+3))"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error ->
  #         assert error == {:error, "error at the end of: (3+ in line 1"}
  #     end
  #   end

  #   test "error missing left parenthesis" do
  #     input = "3+ 2)"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error -> assert error == {:error, "error at the end of: 3+ in line 1"}
  #     end

  #     input = "(3+ (2) - 5+3))"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error -> assert error == {:error, "error at the end of: (3+ in line 1"}
  #     end
  #   end

  #   test "error missing then" do
  #     input = "if (x>5"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error -> assert error == {:error, "error at the end of: (x>5 in line 1"}
  #     end

  #     input = "if (x>5)"

  #     try do
  #       Parser.parse(input)
  #       assert false
  #     catch
  #       error -> assert error == {:error, "error at the end of: (x>5) in line 1"}
  #     end
  #   end
  # end

  describe "ifs" do
    test "parse if_then statemen" do
      input = "if false then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:boolean, false}, {:number, 2}, nil}
    end

    test "parse if_then_else statemen" do
      input = "if false or true then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:or_operation, {:boolean, false}, {:boolean, true}}, {:number, 2},
                nil}
    end

    test "parse if_then statemen with conditions" do
      input = "if (4>7) == (true or false) then 2 end "
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}}, {:number, 2}, nil}
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
               {{:assignment, {:name, "x"}, {:number, 1}},
                {{:assignment, {:name, "y"}, {:number, 3}},
                 {:if_then_else, {:boolean, true},
                  {{:assignment, {:name, "x"}, {:number, 2}},
                   {:assignment, {:name, "y"}, {:plus, {:name, "y"}, {:name, "x"}}}}, nil}}}
    end

    test "parse if_then_else statemen with conditions and returning differents types" do
      input = "if (4>7) == (true or false) then 2 else '3' end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}}, {:number, 2},
                {:string, "'3'"}}
    end

    test "parse if_then_else statemen with conditions and nested if_then_else in the if" do
      input = "if (4>7) == (true or false) then if true then 2 else 1 end else 3+5 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}},
                {:if_then_else, {:boolean, true}, {:number, 2}, {:number, 1}},
                {:plus, {:number, 3}, {:number, 5}}}
    end

    test "parse if_then_else statemen with conditions and nested if_then_else in the if and else" do
      input =
        "if (4>7) == (true or false) then if true then 2 else 1 end else if false then 3+5 else 0 end end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}},
                {:if_then_else, {:boolean, true}, {:number, 2}, {:number, 1}},
                {:if_then_else, {:boolean, false}, {:plus, {:number, 3}, {:number, 5}},
                 {:number, 0}}}
    end

    test "parse elseif" do
      input =
        "        if clase == 'Bárbaro' then
                        1d12
                  elseif clase == 'Bardo' then
                        1d8
                  elseif clase == 'Clérigo' then
                        1d8
                  elseif clase == 'Druida' then
                        1d8
                  elseif clase == 'Hechicero' then
                        1d6
                  elseif clase == 'Mago' then
                        1d6
                  else
                        0
                  end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Bárbaro'"}},
                {:dice, {:number, 1}, {:number, 12}},
                {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Bardo'"}},
                 {:dice, {:number, 1}, {:number, 8}},
                 {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Clérigo'"}},
                  {:dice, {:number, 1}, {:number, 8}},
                  {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Druida'"}},
                   {:dice, {:number, 1}, {:number, 8}},
                   {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Hechicero'"}},
                    {:dice, {:number, 1}, {:number, 6}},
                    {:if_then_else, {:equal, {:name, "clase"}, {:string, "'Mago'"}},
                     {:dice, {:number, 1}, {:number, 6}}, {:number, 0}}}}}}}
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
               {:for_loop, {:name, "x"}, {:range, {:name, "y"}},
                {:assignment, {:name, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- 1..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x"}, {:range, {{:number, 1}, {:number, 3}}},
                {:assignment, {:name, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- y..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x"}, {:range, {{:name, "y"}, {:number, 3}}},
                {:assignment, {:name, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- y..z do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:name, "x"}, {:range, {{:name, "y"}, {:name, "z"}}},
                {:assignment, {:name, "x"}, {:plus, {:number, 2}, {:number, 1}}}}
    end
  end

  describe "boolean expressions" do
    test "parse boolean" do
      input = "true"
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, true}

      input = "false"
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, false}
    end

    test "parse and" do
      # input = "false and false"
      # {:ok, token} = Parser.parse(input)

      # assert token == {:and_operation, {:boolean, false}, {:boolean, false}}

      input = "(3>4) and false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation, {:stric_more, {:number, 3}, {:number, 4}}, {:boolean, false}}
    end

    test "parse and with multiples factors" do
      input = "false and false and false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation, {:and_operation, {:boolean, false}, {:boolean, false}},
                {:boolean, false}}

      input = "(3>4) and false and (4<3 and true)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {:and_operation, {:stric_more, {:number, 3}, {:number, 4}}, {:boolean, false}},
                {:and_operation, {:stric_less, {:number, 4}, {:number, 3}}, {:boolean, true}}}
    end

    test "parse or" do
      input = "true or true"
      {:ok, token} = Parser.parse(input)

      assert token == {:or_operation, {:boolean, true}, {:boolean, true}}

      input = "(3 > 4) or false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation, {:stric_more, {:number, 3}, {:number, 4}}, {:boolean, false}}

      input = "(4>7) == (true or false)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                {:or_operation, {:boolean, true}, {:boolean, false}}}

      # input = "(3) or false"
      # {:ok, token} = Parser.parse(input)

      # assert token == {:number, 3}}
    end

    test "parse or with multiples factors" do
      input = "false or false or false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation, {:or_operation, {:boolean, false}, {:boolean, false}},
                {:boolean, false}}

      input = "(3>4) or false or (4<3 or true)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:or_operation,
                {:or_operation, {:stric_more, {:number, 3}, {:number, 4}}, {:boolean, false}},
                {:or_operation, {:stric_less, {:number, 4}, {:number, 3}}, {:boolean, true}}}
    end

    test "parse not" do
      input = "not true"
      {:ok, token} = Parser.parse(input)

      assert token == {:not_operation, {:boolean, true}}

      input = "not false"
      {:ok, token} = Parser.parse(input)

      assert token == {:not_operation, {:boolean, false}}
    end

    test "parse not with operation" do
      input = "not (true == (5<6))"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:not_operation,
                {:equal, {:boolean, true}, {:stric_less, {:number, 5}, {:number, 6}}}}
    end

    test "parse compare" do
      input = "true < false"
      {:ok, token} = Parser.parse(input)

      assert token == {:stric_less, {:boolean, true}, {:boolean, false}}

      input = "true > false"
      {:ok, token} = Parser.parse(input)

      assert token == {:stric_more, {:boolean, true}, {:boolean, false}}

      input = "true >= false"
      {:ok, token} = Parser.parse(input)

      assert token == {:more_equal, {:boolean, true}, {:boolean, false}}

      input = "true <= false"
      {:ok, token} = Parser.parse(input)

      assert token == {:less_equal, {:boolean, true}, {:boolean, false}}

      input = "3 > 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:stric_more, {:number, 3}, {:number, 4}}

      input = "3 < 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:stric_less, {:number, 3}, {:number, 4}}

      input = "3 >= 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:more_equal, {:number, 3}, {:number, 4}}

      input = "3 <= 4"
      {:ok, token} = Parser.parse(input)

      assert token == {:less_equal, {:number, 3}, {:number, 4}}

      input = "3 + 9 <= (2 - 1d6)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal, {:plus, {:number, 3}, {:number, 9}},
                {:minus, {:number, 2}, {:dice, {:number, 1}, {:number, 6}}}}
    end

    test "parse compare multiple factors" do
      input = "4 > 3 + 9 <= (2 - 1d6)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal, {:stric_more, {:number, 4}, {:plus, {:number, 3}, {:number, 9}}},
                {:minus, {:number, 2}, {:dice, {:number, 1}, {:number, 6}}}}
    end

    test "parse equals" do
      input = "3 == 3"
      {:ok, token} = Parser.parse(input)

      assert token == {:equal, {:number, 3}, {:number, 3}}

      input = "3 == (5>6)"
      {:ok, token} = Parser.parse(input)

      assert token == {:equal, {:number, 3}, {:stric_more, {:number, 5}, {:number, 6}}}
    end

    test "parse equals with multiple factors" do
      input = "3==3==4"
      {:ok, token} = Parser.parse(input)

      assert token == {:equal, {:equal, {:number, 3}, {:number, 3}}, {:number, 4}}
    end

    test "parse equals string number and boolean" do
      input = "'no soy igual'== 3 == false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal, {:equal, {:string, "'no soy igual'"}, {:number, 3}}, {:boolean, false}}
    end

    test "parse parenthesis" do
      input = "(false) "
      {:ok, token} = Parser.parse(input)

      assert token == {:boolean, false}

      input = "(false or true) "
      {:ok, token} = Parser.parse(input)

      assert token == {:or_operation, {:boolean, false}, {:boolean, true}}

      input = "(true == (5<6))"
      {:ok, token} = Parser.parse(input)

      assert token == {:equal, {:boolean, true}, {:stric_less, {:number, 5}, {:number, 6}}}

      input = "(4 > 3 + 9 <= (2 - 1d6))"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:less_equal, {:stric_more, {:number, 4}, {:plus, {:number, 3}, {:number, 9}}},
                {:minus, {:number, 2}, {:dice, {:number, 1}, {:number, 6}}}}
    end

    test "parse complex boolean expression" do
      input = "((3 + 5 * 2)  / 2^3 + 9%17 == 1 and 6 - 2 >= 3)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation,
                {:equal,
                 {:plus,
                  {:divi, {:plus, {:number, 3}, {:mult, {:number, 5}, {:number, 2}}},
                   {:pow, {:number, 2}, {:number, 3}}}, {:mod, {:number, 9}, {:number, 17}}},
                 {:number, 1}}, {:more_equal, {:minus, {:number, 6}, {:number, 2}}, {:number, 3}}}
    end
  end

  describe "string expressions" do
    test "parse string with \"" do
      input = "\"hola mundo\""
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "\"hola mundo\""}
    end

    test "parse string with ''" do
      input = "'hola mundo'"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "'hola mundo'"}
    end

    test "parse string with a number" do
      input = "'1'"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "'1'"}
    end

    test "parse empty string" do
      input = "''"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "''"}
    end

    test "concat string" do
      input = "\"hola \" + \"mundo\""
      {:ok, token} = Parser.parse(input)
      assert token == {:plus, {:string, "\"hola \""}, {:string, "\"mundo\""}}
    end

    test "concat n strings" do
      input = "\"hola \" + \"mundo\" + \", 2\" + \"\""
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {:plus, {:plus, {:string, "\"hola \""}, {:string, "\"mundo\""}},
                 {:string, "\", 2\""}}, {:string, "\"\""}}
    end
  end

  describe "arrays" do
    test "empty array" do
      input = "[]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, nil}
    end

    test "array with an numeric element" do
      input = "[1]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {:number, 1}}
    end

    test "array with two numeric elements" do
      input = "[1,2]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {{:number, 1}, {:number, 2}}}
    end

    test "array with n numeric elements" do
      input = "[1,2,3,3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list, {{:number, 1}, {{:number, 2}, {{:number, 3}, {:number, 3}}}}}
    end

    test "array with an string element" do
      input = "['1']"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {:string, "'1'"}}
    end

    test "array with two string elements" do
      input = "['1',\"2\"]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list, {{:string, "'1'"}, {:string, "\"2\""}}}
    end

    test "array with n string elements" do
      input = "['1','2','3','3']"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list,
                {{:string, "'1'"}, {{:string, "'2'"}, {{:string, "'3'"}, {:string, "'3'"}}}}}
    end

    test "array with n mix elements" do
      input = "['1',2,'3',true]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list, {{:string, "'1'"}, {{:number, 2}, {{:string, "'3'"}, {:boolean, true}}}}}
    end

    test "array with n mix elements and operations" do
      input = "['1'+'2',3+2*(3+3),'3', if true then 3 else 'r' end]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list,
                {{:plus, {:string, "'1'"}, {:string, "'2'"}},
                 {{:plus, {:number, 3},
                   {:mult, {:number, 2}, {:plus, {:number, 3}, {:number, 3}}}},
                  {{:string, "'3'"},
                   {:if_then_else, {:boolean, true}, {:number, 3}, {:string, "'r'"}}}}}}
    end
  end

  describe "plus" do
    test "parse plus operation" do
      input = "1+1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = "1+ 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = "1 +1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = "1 + 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = " 1 + 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = " 1 + 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:number, 1}}

      input = " 1 + 1d5"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:dice, {:number, 1}, {:number, 5}}}
    end

    test "parse plus operation with n operators" do
      input = "1+1+3+4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus, {:plus, {:plus, {:number, 1}, {:number, 1}}, {:number, 3}}, {:number, 4}}
    end
  end

  describe "negative" do
    test "parse negative operation" do
      input = "- 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1}}
    end

    test "parse negation of negation" do
      input = "- - 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:negative, {:number, 1}}}
    end

    test "parse negation inside parenthesis" do
      input = "(- 1)"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1}}
    end

    test "parse negation outside parenthesis" do
      input = "-( 1)"
      {:ok, token} = Parser.parse(input)

      assert token == {:negative, {:number, 1}}
    end

    test "test negative in a operation with and without parenthesis" do
      input = "1+ (-3) +3 -2 +4 "
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {:minus, {:plus, {:plus, {:number, 1}, {:negative, {:number, 3}}}, {:number, 3}},
                 {:number, 2}}, {:number, 4}}
    end
  end

  describe "minus" do
    test "parse minus operation" do
      input = "1-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:minus, {:number, 1}, {:number, 1}}
    end

    test "parse minus minus operation" do
      input = "(-3 +3 -2 *3)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:minus, {:plus, {:negative, {:number, 3}}, {:number, 3}},
                {:mult, {:number, 2}, {:number, 3}}}
    end

    test "parse minus operation with n operators" do
      input = "1-1-3-4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:minus, {:minus, {:minus, {:number, 1}, {:number, 1}}, {:number, 3}},
                {:number, 4}}
    end
  end

  describe "multiplication" do
    test "parse mult operation" do
      input = "1*1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}

      input = "1* 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}

      input = "1 *1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}

      input = "1 * 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}

      input = " 1 * 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}

      input = " 1 * 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:number, 1}, {:number, 1}}
    end

    test "parse mult operation with n operators" do
      input = "1*1*3*4+5"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus,
                {:mult, {:mult, {:mult, {:number, 1}, {:number, 1}}, {:number, 3}}, {:number, 4}},
                {:number, 5}}
    end
  end

  describe "division " do
    test "parse div operation" do
      input = "1/1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}

      input = "1/ 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}

      input = "1 /1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}

      input = "1 / 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}

      input = " 1 / 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}

      input = " 1 / 1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:divi, {:number, 1}, {:number, 1}}
    end
  end

  describe "pow" do
    test "parse simple pow" do
      input = "2^3"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {:number, 2}, {:number, 3}}

      input = "2^-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {:number, 2}, {:negative, {:number, 1}}}

      input = "-2^1"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {:negative, {:number, 2}}, {:number, 1}}

      input = "-2^-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:pow, {:negative, {:number, 2}}, {:negative, {:number, 1}}}
    end

    test "parse concat pows" do
      input = "2^2^3^4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {:pow, {:pow, {:number, 2}, {:number, 2}}, {:number, 3}}, {:number, 4}}
    end

    test "parse pows with operations" do
      input = "(3+2)^2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {:plus, {:number, 3}, {:number, 2}}, {:number, 2}}

      input = "2^(3+2)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {:number, 2}, {:plus, {:number, 3}, {:number, 2}}}

      input = "2^(3+2)^2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:pow, {:pow, {:number, 2}, {:plus, {:number, 3}, {:number, 2}}}, {:number, 2}}
    end
  end

  describe "mod" do
    test "parse simple mod" do
      input = "2%3"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {:number, 2}, {:number, 3}}

      input = "2%-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {:number, 2}, {:negative, {:number, 1}}}

      input = "-2%1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {:negative, {:number, 2}}, {:number, 1}}

      input = "-2%-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:mod, {:negative, {:number, 2}}, {:negative, {:number, 1}}}
    end

    test "parse concat mods" do
      input = "2%2%3%4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {:mod, {:mod, {:number, 2}, {:number, 2}}, {:number, 3}}, {:number, 4}}
    end

    test "parse mods with operations" do
      input = "(3+2)%2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {:plus, {:number, 3}, {:number, 2}}, {:number, 2}}

      input = "2%(3+2)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {:number, 2}, {:plus, {:number, 3}, {:number, 2}}}

      input = "2%(3+2)%2"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:mod, {:mod, {:number, 2}, {:plus, {:number, 3}, {:number, 2}}}, {:number, 2}}
    end
  end

  describe "round division" do
    test "parse div operation" do
      input = "1//2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}

      input = "1//2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}

      input = "1 //2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}

      input = "1 // 2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}

      input = " 1 // 2"
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}

      input = " 1 // 2 "
      {:ok, token} = Parser.parse(input)

      assert token == {:round_div, {:number, 1}, {:number, 2}}
    end
  end

  describe "dice" do
    test "parse dice" do
      input = "1d5"
      {:ok, token} = Parser.parse(input)

      assert token == {:dice, {:number, 1}, {:number, 5}}
    end

    test "plus dice with a number" do
      input = "5 + 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:plus, {:number, 5}, {:dice, {:number, 1}, {:number, 5}}}}
    end

    test "mult dice with a parentesis number" do
      input = "(5 + 3) * 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok,
                {:mult, {:plus, {:number, 5}, {:number, 3}}, {:dice, {:number, 1}, {:number, 5}}}}
    end

    test "div dice and multi a number with a parentesis" do
      input = "(5 + 3) * 1d5 / 3"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:divi,
                {:mult, {:plus, {:number, 5}, {:number, 3}}, {:dice, {:number, 1}, {:number, 5}}},
                {:number, 3}}
    end

    test "test priority" do
      input = "1d6 * 3"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:mult, {:dice, {:number, 1}, {:number, 6}}, {:number, 3}}
    end
  end

  describe "variables" do
    test "parse var" do
      input =
        "x"

      {:ok, token} = Parser.parse(input)

      assert token == {:name, "x"}

      input =
        "hola"

      {:ok, token} = Parser.parse(input)

      assert token == {:name, "hola"}
    end

    test "parse assignament" do
      input = "x = 6"
      {:ok, token} = Parser.parse(input)

      assert token == {:assignment, {:name, "x"}, {:number, 6}}
    end

    test "parse assignament with result of function" do
      input = "numero_de_razas = contar_longitud(razas)"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:assignment, {:name, "numero_de_razas"},
                {:call_function, {:name, "contar_longitud"}, {:parameters, {:name, "razas"}}}}
    end

    test "parse dice with variables" do
      input = "1d numero_de_razas"
      {:ok, token} = Parser.parse(input)

      assert token == {{:number, 1}, {{:name, "d "}, {:name, "numero_de_razas"}}}
    end
  end

  describe "functions" do
    test "parse basic function" do
      input = "function hola_mundo () do
        'hola mundo'
      end"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:assignment_function, {:function_name, {:name, "hola_mundo"}}, {:parameters, nil},
                {:function_code, {:string, "'hola mundo'"}}}
    end

    test "parse basic function with parameters" do
      input = "function hola_mundo (msg, range) do
        for participants <- range do
          msg
        end
      end"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:assignment_function, {:function_name, {:name, "hola_mundo"}},
                {:parameters, {{:name, "msg"}, {:name, "range"}}},
                {:function_code,
                 {:for_loop, {:name, "participants"}, {:range, {:name, "range"}}, {:name, "msg"}}}}
    end

    test "parse basic call function without parameters" do
      input = "hola_mundo()"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:call_function, {:name, "hola_mundo"}, {:parameters, nil}}
    end

    test "parse basic call function with parameters" do
      input = "hola_mundo('hola mundo ', 2)"
      {:ok, tokens} = Parser.parse(input)

      assert tokens ==
               {:call_function, {:name, "hola_mundo"},
                {:parameters, {{:string, "'hola mundo '"}, {:number, 2}}}}
    end
  end

  describe "statements" do
    test "parse sentences" do
      input =
        "x = 2;
        y= 3;
        z= 4+x;"

      {:ok, token} = Parser.parse(input)

      expect = {
        {:assignment, {:name, "x"}, {:number, 2}},
        {{:assignment, {:name, "y"}, {:number, 3}},
         {:assignment, {:name, "z"}, {:plus, {:number, 4}, {:name, "x"}}}}
      }

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
               {{:assignment, {:name, "x"}, {:number, 6}},
                {{:assignment, {:name, "y"}, {:plus, {:name, "x"}, {:number, 2}}},
                 {{:assignment, {:name, "x"}, {:plus, {:name, "x"}, {:number, 2}}},
                  {:assignment, {:name, "z"}, {:plus, {:name, "x"}, {:name, "y"}}}}}}
    end
  end

  describe "numeric expressions" do
    test "parse integer" do
      input = "1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1}

      input = "1 "
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1}

      input = " 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1}

      input = " 1"
      {:ok, token} = Parser.parse(input)

      assert token == {:number, 1}
    end

    test "parse with vars" do
      input = "
      x+y"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:name, "x"}, {:name, "y"}}
    end

    test "parse with functions" do
      input = "
      x*y()"
      {:ok, token} = Parser.parse(input)

      assert token == {:mult, {:name, "x"}, {:call_function, {:name, "y"}, {:parameters, nil}}}
    end

    test "parse with assignment" do
      input = "
      z= 4+x"
      {:ok, token} = Parser.parse(input)

      assert token == {:assignment, {:name, "z"}, {:plus, {:number, 4}, {:name, "x"}}}
    end
  end
end
