defmodule CowRollWeb.CommandTest do
  use CowRollWeb.ConnCase, async: true
  @n 100
  @target %{
    level: 3,
    hitPoints: 18,
    ca: 12,
    race: "tiefling",
    class: "warlock",
    actualHitPoints: 10,
    resistences: %{
      fire: %{
        phisical: 1 / 4,
        magical: 1 / 2
      }
    },
    stats: %{
      strength: 10,
      dextery: 15,
      constitutions: 12,
      inteligence: 10,
      wisdom: 12,
      charisma: 18
    },
    salvationRoll: %{
      dice: "1d20",
      bonus: "charisma"
    }
  }
  @json_data %{
    command: %{
      name: "attack",
      weapon: %{
        name: "daga",
        dice: %{
          dice: "2d4",
          dmgType: "phisical piercing"
        },
        additionalDice: [
          %{
            dice: "1d4",
            dmgType: "phisical poison"
          }
        ],
        bonus: "5 + 4",
        attackRoll: "1d20"
      },
      target: @target
    }
  }

  test "GET /api/command returns success" do
    conn = get(build_conn(), "/api/command")
    assert conn.status == 200
    assert text_response(conn, 200) == "Solicitud GET exitosa"
  end

  test "Post /api/command Unknow command" do
    conn =
      build_conn()
      |> post("/api/command")

    assert conn.status == 200
    assert text_response(conn, 200) == "Unknow command"
  end

  describe "API Command  attack Tests" do
    test "Post /api/command getting attack dices 2d4 without aditional dices and bonus" do
      number_of_dices = 2
      number_of_faces = 4

      withOut_additionalDices =
        %{
          command: %{
            name: "attack",
            weapon: %{
              name: "daga",
              dice: %{
                dice: to_string(number_of_dices) <> "d" <> to_string(number_of_faces),
                dmgType: "phisical piercing"
              },
              attackRoll: "1d20"
            },
            target: @target
          }
        }

      for _ <- 1..@n do
        conn =
          build_conn()
          |> put_req_header("content-type", "application/json")
          |> post("/api/command", Poison.encode!(withOut_additionalDices))

        case conn.status do
          200 ->
            resp = text_response(conn, 200)

            aux =
              case resp do
                "Result: Missed hit" ->
                  true

                "Result:" <> _ ->
                  true
              end

            assert aux

          _ ->
            assert false
        end
      end
    end

    test "Post /api/command getting invalid notation" do
      incorrect_json =
        %{
          command: %{
            name: "attack",
            weapon: %{
              name: "daga",
              dice: %{
                dice: "f",
                dmgType: "phisical piercing"
              },
              additionalDice: [
                %{
                  dice: "1d4",
                  dmgType: "phisical poison"
                }
              ],
              bonus: "5 + 4",
              attackRoll: "15d20"
            },
            target: @target
          }
        }

      for _ <- 1..@n do
        conn =
          build_conn()
          |> put_req_header("content-type", "application/json")
          |> post("/api/command", Poison.encode!(incorrect_json))

        assert conn.status == 500

        resp =
          case conn.resp_body do
            "Error: Input has a invalid notation" -> true
            "Result: Missed hit" -> true
            _ -> false
          end

        assert resp
      end
    end

    test "Post /api/command getting invalid type" do
      incorrect_json =
        %{
          command: %{
            name: "attack",
            weapon: %{
              name: "daga",
              dice: %{
                dice: 5,
                dmgType: "phisical piercing"
              },
              additionalDice: [
                %{
                  dice: "1d4",
                  dmgType: "phisical poison"
                }
              ],
              bonus: "5 + 4",
              attackRoll: "15d20"
            },
            target: @target
          }
        }

      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/api/command", Poison.encode!(incorrect_json))

      assert conn.status == 500
      assert conn.resp_body == "Error: Invalid type"
    end

    test "Post /api/command trying attack without dice" do
      incorrect_json =
        %{
          command: %{
            name: "attack",
            weapon: %{
              name: "daga",
              dice: %{
                dmgType: "phisical piercing"
              },
              additionalDice: [
                %{
                  dice: "1d4",
                  dmgType: "phisical poison"
                }
              ],
              bonus: "5 + 4",
              attackRoll: "15d20"
            },
            target: @target
          }
        }

      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/api/command", Poison.encode!(incorrect_json))

      assert conn.status == 500
      assert conn.resp_body == "Error: Invalid type"
    end

    test "Post /api/command getting without target" do
      incorrect_json =
        %{
          command: %{
            name: "attack",
            weapon: %{
              name: "daga",
              dice: %{
                dmgType: "phisical piercing"
              },
              additionalDice: [
                %{
                  dice: "1d4",
                  dmgType: "phisical poison"
                }
              ],
              bonus: "5 + 4",
              attackRoll: "1d20"
            }
          }
        }

      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post("/api/command", Poison.encode!(incorrect_json))

      assert conn.status == 500
      assert conn.resp_body == "Error: No CA was found"
    end

    test "Post /api/command getting with additional dice without bonus" do
      number_of_dices = 2
      number_of_faces = 4

      aditional_number_of_dices = 1
      aditional_number_of_faces = 4

      %{
        command: %{
          name: "attack",
          weapon: %{
            name: "daga",
            dice: %{
              dice: to_string(number_of_dices) <> "d" <> to_string(number_of_faces),
              dmgType: "phisical piercing"
            },
            additionalDice: [
              %{
                dice:
                  to_string(aditional_number_of_dices) <>
                    "d" <> to_string(aditional_number_of_faces),
                dmgType: "phisical poison"
              }
            ],
            bonus: "5 + 4",
            attackRoll: "15d20"
          },
          target: @target
        }
      }

      for _ <- 1..@n do
        conn =
          build_conn()
          |> put_req_header("content-type", "application/json")
          |> post("/api/command", Poison.encode!(@json_data))

        case conn.status do
          200 ->
            resp = text_response(conn, 200)

            aux =
              case resp do
                "Result: Missed hit" ->
                  true

                "Result:" <> _ ->
                  true
              end

            assert aux

          _ ->
            assert false
        end
      end
    end
  end
end
