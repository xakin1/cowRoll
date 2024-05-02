defmodule CowRoll.AttackTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import Attack

<<<<<<< Updated upstream
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
=======
  describe "scrip test" do
    test "command creation sheet" do
      :rand.seed(:exsplus, {1, 2, 3})

      input = "
      function roll_dices(number_of_dices, number_of_face) do
        if (number_of_dices<=0 or number_of_face <0 ) then
        0
        else
        roll = rand(number_of_face)
        roll + roll_dices(number_of_dices - 1, number_of_face)
        end
    end

    function roll_ability_score() do
        rolls = [0,0,0,0]
        for x <- 0..3 do
            rolls[x] = roll_dices(1,6)
        end

        min_index = 0
        for i <- 0..3 do
            if (rolls[i] < rolls[min_index]) then
                min_index = i
            end
        end

        result = 0
        for i <- 0..3 do
            if (i != min_index) then
                result = result + rolls[i];
            end
        end

        result
    end



    clases = {
        barbaro: {
            vida_inicial: 12,
            competencias_armas: ['armas simples', 'armas marciales'],
            competencias_armaduras: ['armaduras ligeras', 'armaduras medias', 'escudos'],
            habilidades: ['rabia', 'sentido salvaje']
        },
        bardo: {
            vida_inicial: 8,
            competencias_armas: ['armas simples', 'armas marciales', 'ballesta ligera', 'espada corta', 'rapier'],
            competencias_armaduras: ['armaduras ligeras'],
            habilidades: ['inspiración', 'magia barda']
        },
        clerigo: {
            vida_inicial: 8,
            competencias_armas: ['armas simples'],
            competencias_armaduras: ['armaduras ligeras', 'armaduras medias', 'escudos'],
            habilidades: ['curación divina', 'canalizar energía divina']
        },
        druida: {
            vida_inicial: 8,
            competencias_armas: ['cuerdas', 'mazas', 'lanzas', 'dardos', 'cuchillos'],
            competencias_armaduras: ['armaduras ligeras', 'escudos (no metálicos)'],
            habilidades: ['transformación en bestia', 'magia druídica']
        },
        hechicero: {
            vida_inicial: 6,
            competencias_armas: ['dagas', 'dardos', 'hondas', 'ballesta ligera'],
            competencias_armaduras: [],
            habilidades: ['conjuros arcanos', 'magia innata']
        },
        mago: {
            vida_inicial: 6,
            competencias_armas: ['ballesta ligera', 'daga'],
            competencias_armaduras: [],
            habilidades: ['escuela de magia', 'conjuros arcanos']
        },
        monje: {
            vida_inicial: 8,
            competencias_armas: ['espadas cortas', 'bastones', 'dardos', 'artes marciales'],
            competencias_armaduras: ['sin armadura', 'monje'],
            habilidades: ['defensa sin armadura', 'golpe desarmado']
        },
        paladin: {
            vida_inicial: 10,
            competencias_armas: ['armas simples', 'armas marciales'],
            competencias_armaduras: ['todas las armaduras', 'escudos'],
            habilidades: ['juramento sagrado', 'divinidad']
        },
        explorador: {
            vida_inicial: 10,
            competencias_armas: ['armas simples', 'armas marciales'],
            competencias_armaduras: ['armaduras ligeras', 'armaduras medias', 'escudos'],
            habilidades: ['rastreo', 'naturalista']
        },
        brujo: {
            vida_inicial: 8,
            competencias_armas: ['dagas', 'dardos', 'hondas', 'ballesta ligera'],
            competencias_armaduras: [],
            habilidades: ['pacto arcana', 'invocaciones']
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      end
=======
    end

    function generar_estadisticas_base() do
        fuerza = roll_ability_score()
        destreza = roll_ability_score()
        constitución = roll_ability_score()
        inteligencia = roll_ability_score()
        sabiduria = roll_ability_score()
        carisma = roll_ability_score()

        {fuerza: fuerza, destreza: destreza, constitucion: constitución, inteligencia: inteligencia, sabiduria: sabiduria, carisma: carisma }
    end

    function generar_ficha(nombre) do
        nombre = nombre
        edad = roll_dices(1,20 + 10)
        estadisticas = generar_estadisticas_base()

        numero_de_clases = rand(contar_longitud(clases_nombres))
        numero_de_razas = rand(contar_longitud(razas_nombres))
        nombre_de_clase = clases_nombres[numero_de_clases]
        nombre_de_raza = razas_nombres[numero_de_razas]
        clase_aleatoria = clases[nombre_de_clase]
        raza_aleatoria =razas[nombre_de_raza]

        vida_por_nivel = obtener_vida_por_nivel(clase_aleatoria)
        nivel = 1

        {nombre: nombre, edad: edad, estadisticas: estadisticas ,
            raza: {nombre_de_raza: nombre_de_raza, detalle: raza_aleatoria}, clase: {nombre: nombre_de_clase, detalle: clase_aleatoria}, nivel: nivel, vida_total: clase_aleatoria['vida_inicial'] + obtener_vida_por_nivel(nombre_de_clase)}
    end

    generar_ficha('PRUEBA')
         "

      result = CowRoll.Interpreter.eval_input(input)

      assert result == %{
               "clase" => %{
                 "detalle" => %{
                   "competencias_armaduras" => [],
                   "competencias_armas" => ["dagas", "dardos", "hondas", "ballesta ligera"],
                   "habilidades" => ["pacto arcana", "invocaciones"],
                   "vida_inicial" => 8
                 },
                 "nombre" => "brujo"
               },
               "edad" => 22,
               "estadisticas" => %{
                 "carisma" => 7,
                 "constitucion" => 7,
                 "destreza" => 11,
                 "fuerza" => 9,
                 "inteligencia" => 6,
                 "sabiduria" => 6
               },
               "nivel" => 1,
               "nombre" => "PRUEBA",
               "raza" => %{
                 "detalle" => %{
                   "proficiencias_armaduras" => [],
                   "proficiencias_armas" => ["espada larga", "espada corta"],
                   "subrazas" => %{
                     "asmodeus" => %{
                       "habilidades_especiales" => [
                         "resistencia a fuego",
                         "conjuro de prestidigitación"
                       ]
                     },
                     "mefistófeles" => %{
                       "habilidades_especiales" => [
                         "resistencia a fuego",
                         "llamas de thamaturgia"
                       ]
                     }
                   },
                   "velocidad" => 30
                 },
                 "nombre_de_raza" => "tiefling"
               },
               "vida_total" => 11
             }
>>>>>>> Stashed changes
    end
  end
end
