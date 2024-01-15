defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "lexical error" do
    test "error missing right parenthesis" do
      input = "(3+ 2"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end

      input = "(3+ (2 - (5+3))"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end
    end

    test "error missing left parenthesis" do
      input = "3+ 2)"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing left parenthesis"} -> assert true
      end

      input = "(3+ (2) - 5+3))"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing left parenthesis"} -> assert true
      end
    end

    test "error missing then" do
      input = "if x>5"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing then statement"} -> assert true
      end
    end

    test "two semantic error should return error missing right parenthesis" do
      input = "if ((x>5)"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end
    end

    test "two semantic error should return error missing argument" do
      input = "3*"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end

      input = "3-"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end

      input = "3+"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end
    end
  end

  describe "ifs" do
    test "parse if_then statemen" do
      input = "if false then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:boolean, false}, {:number, 2}, :"$undefined"}
    end

    test "parse if_then_else statemen" do
      input = "if false or true then 2 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else, {:or_operation, {:boolean, false}, {:boolean, true}}, {:number, 2},
                :"$undefined"}
    end

    test "parse if_then statemen with conditions" do
      input = "if (4>7) == (true or false) then 2 end "
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}}, {:number, 2},
                :"$undefined"}
    end

    test "parse if_then_else statemen with conditions" do
      input = "if (4>7) == (true or false) then 2 else 3+5 end"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:if_then_else,
                {:equal, {:stric_more, {:number, 4}, {:number, 7}},
                 {:or_operation, {:boolean, true}, {:boolean, false}}}, {:number, 2},
                {:plus, {:number, 3}, {:number, 5}}}
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
  end

  describe "fors" do
    test "parse for" do
      input = "
      for x <- y do
        x = 2 + 1
      end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:var, "x"}, {:range, {:var, "y"}},
                {:assignment, {:var, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- 1..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:var, "x"}, {:range, {{:number, 1}, {:number, 3}}},
                {:assignment, {:var, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- y..3 do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:var, "x"}, {:range, {{:var, "y"}, {:number, 3}}},
                {:assignment, {:var, "x"}, {:plus, {:number, 2}, {:number, 1}}}}

      input = "for x <- y..z do
                  x = 2 + 1
                end"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {:for_loop, {:var, "x"}, {:range, {{:var, "y"}, {:var, "z"}}},
                {:assignment, {:var, "x"}, {:plus, {:number, 2}, {:number, 1}}}}
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
      input = "false and false"
      {:ok, token} = Parser.parse(input)

      assert token == {:and_operation, {:boolean, false}, {:boolean, false}}

      input = "(3>4) and false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:and_operation, {:stric_more, {:number, 3}, {:number, 4}}, {:boolean, false}}
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
                {:plus, {:number, 2}, {:negative, {:dice, "1d6"}}}}
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

      assert token == {:equal, {:number, 3}, {:equal, {:number, 3}, {:number, 4}}}
    end

    test "parse equals string number and boolean" do
      input = "'no soy igual'== 3 == false"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:equal, {:string, "'no soy igual'"}, {:equal, {:number, 3}, {:boolean, false}}}
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

    test "parse empty string" do
      input = "''"
      {:ok, token} = Parser.parse(input)
      assert token == {:string, "''"}
    end

    test "concat string" do
      input = "\"hola \" + \"mundo\""
      {:ok, token} = Parser.parse(input)
      assert token == {:concat, {:string, "\"hola \""}, {:string, "\"mundo\""}}
    end

    test "concat n strings" do
      input = "\"hola \" + \"mundo\" + \", 2\" + \"\""
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:concat, {:string, "\"hola \""},
                {:concat, {:string, "\"mundo\""},
                 {:concat, {:string, "\", 2\""}, {:string, "\"\""}}}}
    end
  end

  describe "numeric arrays" do
    test "empty array" do
      input = "[]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list_of_number, :"$undefined"}
    end

    test "array with an element" do
      input = "[1]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list_of_number, {:number, 1}}
    end

    test "array with two elements" do
      input = "[1,2]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list_of_number, {{:number, 1}, {:number, 2}}}
    end

    test "array with n elements" do
      input = "[1,2,3,3]"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:list_of_number, {{:number, 1}, {{:number, 2}, {{:number, 3}, {:number, 3}}}}}
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

      assert token == {:plus, {:number, 1}, {:dice, "1d5"}}
    end

    test "parse plus operation with n operators" do
      input = "1+1+3+4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus, {:number, 1}, {:plus, {:number, 1}, {:plus, {:number, 3}, {:number, 4}}}}
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
               {:plus, {:number, 1},
                {:plus, {:negative, {:number, 3}},
                 {:plus, {:number, 3}, {:plus, {:negative, {:number, 2}}, {:number, 4}}}}}
    end
  end

  describe "minus" do
    test "parse minus operation" do
      input = "1-1"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:negative, {:number, 1}}}
    end

    test "parse minus minus operation" do
      input = "1 - (-3)"
      {:ok, token} = Parser.parse(input)

      assert token == {:plus, {:number, 1}, {:negative, {:negative, {:number, 3}}}}
    end

    test "parse minus operation with n operators" do
      input = "1-1-3-4"
      {:ok, token} = Parser.parse(input)

      assert token ==
               {:plus, {:number, 1},
                {:plus, {:negative, {:number, 1}},
                 {:plus, {:negative, {:number, 3}}, {:negative, {:number, 4}}}}}
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
                {:mult, {:number, 1}, {:mult, {:number, 1}, {:mult, {:number, 3}, {:number, 4}}}},
                {:number, 5}}
    end
  end

  describe "division" do
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

  describe "dice" do
    test "parse dice" do
      input = "1d5"
      {:ok, token} = Parser.parse(input)

      assert token == {:dice, "1d5"}
    end

    test "plus dice with a number" do
      input = "5 + 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:plus, {:number, 5}, {:dice, "1d5"}}}
    end

    test "mult dice with a parentesis number" do
      input = "(5 + 3) * 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:mult, {:plus, {:number, 5}, {:number, 3}}, {:dice, "1d5"}}}
    end

    test "div dice and multi a number with a parentesis" do
      input = "(5 + 3) * 1d5 / 3"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok,
                {:mult, {:plus, {:number, 5}, {:number, 3}},
                 {:divi, {:dice, "1d5"}, {:number, 3}}}}
    end
  end

  describe "variables" do
    test "parse var" do
      input =
        "x"

      {:ok, token} = Parser.parse(input)

      assert token == {:var, "x"}

      input =
        "hola"

      {:ok, token} = Parser.parse(input)

      assert token == {:var, "hola"}
    end

    test "parse sentences" do
      input =
        "x = 2;
        y= 3;
        z= 4+x"

      {:ok, token} = Parser.parse(input)

      assert token == {
               {:assignment, {:var, "x"}, {:number, 2}},
               {{:assignment, {:var, "y"}, {:number, 3}},
                {:assignment, {:var, "z"}, {:plus, {:number, 4}, {:var, "x"}}}}
             }

      input =
        "x= 6; y = x + 2; x = x +2; z = x+y"

      {:ok, token} = Parser.parse(input)

      assert token ==
               {{:assignment, {:var, "x"}, {:number, 6}},
                {{:assignment, {:var, "y"}, {:plus, {:var, "x"}, {:number, 2}}},
                 {{:assignment, {:var, "x"}, {:plus, {:var, "x"}, {:number, 2}}},
                  {:assignment, {:var, "z"}, {:plus, {:var, "x"}, {:var, "y"}}}}}}
    end

    test "parse assignament" do
      input = "x = 6"
      {:ok, token} = Parser.parse(input)

      assert token == {:assignment, {:var, "x"}, {:number, 6}}
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
  end
end
