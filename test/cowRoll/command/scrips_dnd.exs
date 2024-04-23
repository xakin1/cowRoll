defmodule CowRoll.ScripsDndTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "scrip test" do
    test "command creation sheet" do
      :rand.seed(:exsplus, {1, 2, 3})

      input = "
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

          function obtener_pasivas_raza(raza) do
              if raza == 'Humano' then
                   ['Versatilidad', 'Conocimiento adicional']
              elseif raza == 'Elfo' then
                   ['Sentidos agudos', 'Hablar con animales']
              elseif raza == 'Enano' then
                   ['Resistencia a venenos', 'Visión en la oscuridad']
              elseif raza == 'Gnomo' then
                   ['Conocimiento de la ilusión', 'Ingenio gnómico']
              elseif raza == 'Mediano' then
                   ['Aptitud para sigilo', 'Suerte de los mediano']
              elseif raza == 'Dragonborn' then
                   ['Aliento de dragón', 'Resistencia al daño']
              elseif raza == 'Orco' then
                   ['Furia', 'Resistencia implacable']
              elseif raza == 'Tiefling' then
                   ['Infernal Legacy', 'Resistencia al fuego']
              else
                   []
              end
          end

          function generar_ficha(nombre) do
              nombre = nombre
              edad = 1d20 + 10
              fuerza = 1d10
              inteligencia = 1d10

              razas = ['Humano', 'Elfo', 'Enano', 'Gnomo', 'Mediano', 'Dragonborn', 'Orco', 'Tiefling']
              clases = ['Bárbaro', 'Bardo', 'Clérigo', 'Druida', 'Hechicero', 'Mago', 'Monje', 'Paladín', 'Pícaro', 'Ranger', 'Sorcerer', 'Warlock', 'Wizard']
              numero_de_razas = contar_longitud(razas)
              numero_de_clases = contar_longitud(clases)
              raza = razas[1d numero_de_razas]
              clase = clases[1d numero_de_clases]

              vida_por_nivel = obtener_vida_por_nivel(clase)
              nivel = 1d10

              vida_total = nivel * vida_por_nivel

              pasivas_raza = obtener_pasivas_raza(raza)
              {nombre: nombre, edad: edad, fuerza: fuerza, inteligencia: inteligencia,
                 raza:  raza, pasivas_raza: pasivas_raza, clase: clase, nivel: nivel, vida_total: vida_total}
          end

          generar_ficha('PRUEBA')
          "

      try do
        result = Interpreter.eval_input(input)
        IO.inspect(result)

        assert result == %{
                 "nombre" => "PRUEBA",
                 "edad" => 24,
                 "fuerza" => 3,
                 "inteligencia" => 8,
                 "raza" => "Humano",
                 "pasivas_raza" => "Wizard",
                 "clase" => "Paladin",
                 "nivel" => 0,
                 "vida_total" => 12
               }
      rescue
        error -> assert false == error
      end
    end
  end
end
