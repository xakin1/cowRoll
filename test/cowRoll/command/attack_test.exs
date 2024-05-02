defmodule CowRoll.AttackTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "scrip test" do
    test "command creation sheet" do
      :rand.seed(:exsplus, {1, 2, 3})

      input = "
      function roll_dices(number_of_dices, number_of_face) do
        if (number_of_dices<=0 or number_of_face <0 ) then
        -1
        else
        roll = rand(number_of_face) - 1
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
        }
    }

    clases_nombres = ['barbaro', 'bardo', 'clerigo', 'druida', 'hechicero', 'mago', 'monje', 'paladin', 'explorador', 'brujo']
    razas_nombres = ['enano', 'elfo', 'humano', 'halfling', 'mediano', 'dragonborn', 'gnomo', 'tiefling']


    function contar_longitud(lista) do
        longitud = -1
        for elemento <- lista do
            longitud = longitud + 1
        end
        if longitud == -1 then nil else longitud end
        longitud
    end

    function obtener_vida_por_nivel(clase) do
        if clase == 'barbaro' then
            roll_dices(1,12)
        elseif clase == 'bardo' then
            roll_dices(1,8)
        elseif clase == 'clerigo' then
            roll_dices(1,8)
        elseif clase == 'fruida' then
            roll_dices(1,8)
        elseif clase == 'hechicero' then
            roll_dices(1,6)
        elseif clase == 'mago' then
            roll_dices(1,6)
        elseif clase == 'monje' then
            roll_dices(1,8)
        elseif clase == 'paladín' then
            roll_dices(1,10)
        elseif clase == 'pícaro' then
            roll_dices(1,8)
        elseif clase == 'ranger' then
            roll_dices(1,10)
        elseif clase == 'brujo' then
            roll_dices(1,8)
        else
            0
        end
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

        numero_de_clases = contar_longitud(clases_nombres)
        numero_de_razas = contar_longitud(razas_nombres)
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
    end
  end
end
