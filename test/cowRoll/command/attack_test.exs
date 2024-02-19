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

  describe "scrip test" do
    test "command creation sheet" do
      :rand.seed(:exsplus, {1, 2, 3})

      input = "
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
          }
        }

        razas = {
          enano: {
              velocidad:25,
              proficiencias_armas:['hacha de guerra', 'martillo de guerra', 'ballesta ligera', 'ballesta pesada'],
              proficiencias_armaduras:['armaduras ligeras', 'armaduras intermedias'],
              subrazas: {
                  montaña: {
                      habilidades_especiales: ['portador de armadura enana']
                  },
                  colina: {
                      habilidades_especiales: ['resistencia enana']
                  }
              }
          },
          elfo: {
              velocidad:30,
              proficiencias_armas:['espada larga', 'arco largo', 'espada corta', 'arco corto'],
              proficiencias_armaduras:['armaduras ligeras'],
              subrazas: {
                  alto_elfo: {
                      habilidades_especiales: ['trance élfico', 'conjuro de prestidigitación']
                  },
                  elfo_del_bosque: {
                      habilidades_especiales: ['máscara natural', 'sentido del cazador']
                  }
              }
          },
          humano: {
              velocidad:30,
              proficiencias_armas:['cualquier arma'],
              proficiencias_armaduras:['cualquier armadura'],
              subrazas: {
                  versátil: {
                      habilidades_especiales: ['entrenamiento adicional']
                  }
              }
          },
          halfling: {
              velocidad:25,
              proficiencias_armas:['honda', 'daga', 'cimitarra'],
              proficiencias_armaduras:[],
              subrazas: {
                  ligón: {
                      habilidades_especiales: ['suerte', 'sigiloso']
                  },
                  robusto: {
                      habilidades_especiales: ['resiliencia halfling']
                  }
              }
          },
          mediano: {
              velocidad:25,
              proficiencias_armas:['honda', 'daga', 'cimitarra'],
              proficiencias_armaduras:[],
              subrazas: {
                  ligón: {
                      habilidades_especiales: ['suerte', 'sigiloso']
                  },
                  robusto: {
                      habilidades_especiales: ['resiliencia halfling']
                  }
              }
          },
          dragonborn: {
              velocidad:30,
              proficiencias_armas:['espada larga', 'espada corta', 'ballesta ligera'],
              proficiencias_armaduras:[],
              subrazas: {
                  fuego: {
                      habilidades_especiales: ['aliento de fuego']
                  },
                  hielo: {
                      habilidades_especiales: ['aliento de hielo']
                  }
              }
          },
          gnomo: {
              velocidad:25,
              proficiencias_armas:['espada larga', 'espada corta', 'ballesta ligera'],
              proficiencias_armaduras:[],
              subrazas: {
                  ingeniero: {
                      habilidades_especiales: ['truco de herramientas de ingeniero']
                  },
                  forestal: {
                      habilidades_especiales: ['hablar con pequeñas bestias']
                  }
              }
          },
          tiefling: {
              velocidad:30,
              proficiencias_armas:['espada larga', 'espada corta'],
              proficiencias_armaduras:[],
              subrazas: {
                  asmodeus: {
                      habilidades_especiales: ['resistencia a fuego', 'conjuro de prestidigitación']
                  },
                  mefistófeles: {
                      habilidades_especiales: ['resistencia a fuego', 'llamas de thamaturgia']
                  }
              }
          },
        }

        clases_nombres = ['barbaro', 'bardo', 'clerigo', 'druida', 'hechicero', 'mago', 'monje', 'paladin', 'explorador', 'brujo']
        razas_nombres = ['enano', 'elfo', 'humano', 'halfling', 'mediano', 'dragonborn', 'gnomo', 'tiefling']


        function contar_longitud(lista) do
          longitud = 0
          for elemento <- lista do
              longitud = longitud + 1
          end
          longitud
        end

         function obtener_vida_por_nivel(clase) do
             if clase == 'Bárbaro' then
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
             elseif clase == 'Monje' then
                  1d8
             elseif clase == 'Paladín' then
                  1d10
             elseif clase == 'Pícaro' then
                  1d8
             elseif clase == 'Ranger' then
                  1d10
             elseif clase == 'Sorcerer' then
                  1d6
             elseif clase == 'Warlock' then
                  1d8
             elseif clase == 'Wizard' then
                  1d6
             else
                  0
             end
         end

         function generar_estadisticas_base() do
            fuerza = 10
            destreza = 10
            constitución = 10
            inteligencia = 10
            sabiduria = 10
            carisma = 10

            {fuerza: fuerza, destreza: destreza, constitucion: constitución, inteligencia: inteligencia, sabiduria: sabiduria, carisma: carisma }
         end

         function generar_ficha(nombre) do
            nombre = nombre
            edad = 1d20 + 10
            estadisticas = generar_estadisticas_base()

            numero_de_clases = contar_longitud(clases_nombres)
            numero_de_razas = contar_longitud(razas_nombres)
            clase_aleatoria = razas[1d numero_de_clases]
            raza_aleatoria = clases[1d numero_de_razas]

            vida_por_nivel = obtener_vida_por_nivel(clase)
            nivel = 1

            vida_total = obtener_vida(estadisticas)

            pasivas_raza = obtener_pasivas_raza(raza)
            {nombre: nombre, edad: edad, estadisticas: estadisticas ,
              raza:  razas[raraza_aleatoriaza], clase: clases[clase_aleatoria], nivel: nivel, vida_total: vida_total}
         end

         generar_ficha('PRUEBA')
         "

      try do
        result = Interpreter.eval_input(input)

        assert result == %{
                 "clase" => "Ranger",
                 "edad" => 24,
                 "estadisticas" => %{
                   "carisma" => 10,
                   "constitucion" => 10,
                   "destreza" => 10,
                   "fuerza" => 10,
                   "inteligencia" => 10,
                   "sabiduria" => 10
                 },
                 "nivel" => 1,
                 "nombre" => "PRUEBA",
                 "pasivas_raza" => ["Aliento de dragón", "Resistencia al daño"],
                 "raza" => "Dragonborn",
                 "vida_total" => 6
               }
      rescue
        error -> assert false == error
      end
    end
  end
end
