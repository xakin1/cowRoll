defmodule CowRoll.AttackTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import Attack

  @json_data %{
    "command" => %{
      "name" => "attack",
      "target" => %{
        "ca" => 12,
        "class" => "warlock",
        "hitPoints" => 18,
        "race" => "tiefling",
        "resistences" => %{
          "fire" => %{
            "phisical" => 0.25,
            "magical" => 0.5
          }
        }
      },
      "weapon" => %{
        "name" => "daga",
        "dice" => %{
          "dice" => "2d4",
          "dmgType" => "phisical piercing"
        },
        "bonus" => "5 + 4",
        "additionalDice" => [
          %{
            "dice" => "1d4",
            "dmgType" => "phisical poison"
          }
        ],
        "attackRoll" => "1d20"
      }
    }
  }

  describe "hit_success?/1" do
    test "returns :ok when attackRoll is defined" do
      resp =
        case hit_success?(@json_data["command"]) do
          {:ok, _} -> true
          _ -> false
        end

      assert resp
    end

    test "shoud be true dice > ca" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => 12,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1d4",
                "dmgType" => "phisical poison"
              }
            ],
            "attackRoll" => "15d20"
          }
        }
      }

      assert hit_success?(json["command"]) == {:ok, true}
    end

    test "shoud return an error ca nil" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => nil,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1d4",
                "dmgType" => "phisical poison"
              }
            ],
            "attackRoll" => "1d10"
          }
        }
      }

      assert hit_success?(json["command"]) == {:error, "No CA was found"}
    end

    test "shoud be false dice < ca" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => 12,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1d4",
                "dmgType" => "phisical poison"
              }
            ],
            "attackRoll" => "1d10"
          }
        }
      }

      assert hit_success?(json["command"]) == {:ok, false}
    end
  end

  describe "do_attack/1" do
    test "shoud return hit and return true" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => 12,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1d4",
                "dmgType" => "phisical poison"
              }
            ],
            "attackRoll" => "12d20"
          }
        }
      }

      resp =
        case do_attack(json["command"]) do
          {:ok, _, _} ->
            true

          {:ok, _} ->
            true

          {:error, _} ->
            false
        end

      assert resp
    end

    test "shoud return fail" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => 12,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1dx",
                "dmgType" => "phisical poison"
              }
            ],
            "attackRoll" => "12d20"
          }
        }
      }

      assert do_attack(json["command"]) == {:error, "Invalid input format"}
    end

    test "shoud apply resistences" do
      json = %{
        "command" => %{
          "name" => "attack",
          "target" => %{
            "ca" => 12,
            "class" => "warlock",
            "hitPoints" => 18,
            "race" => "tiefling",
            "resistences" => %{
              "fire" => %{
                "phisical" => 0.25,
                "magical" => 0.5
              }
            }
          },
          "weapon" => %{
            "name" => "daga",
            "dice" => %{
              "dice" => "2d4",
              "dmgType" => "phisical piercing"
            },
            "bonus" => "5 + 4",
            "additionalDice" => [
              %{
                "dice" => "1d4",
                "dmgType" => "phisical fire"
              }
            ],
            "attackRoll" => "12d20"
          }
        }
      }

      for _ <- 1..100 do
        case do_attack(json["command"]) do
          {:ok, _, total_damage} ->
            check = 2 <= total_damage and total_damage <= 8 + 4 * 0.25

            if false == check do
              IO.puts(to_string(total_damage))
            end

            assert check

          {:error, _} ->
            false
        end
      end
    end
  end
end
