defmodule CowRoll.ScripsDndTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import Interpreter

  #   test "command creation sheet" do
  #     input = "
  #       function contar_longitud(lista) do
  #         longitud = 0
  #         for elemento <- lista do
  #             longitud = longitud + 1
  #         end
  #         longitud
  #       end

  #       function obtener_vida_por_nivel(clase) do
  #           if clase == 'Bárbaro' then
  #                1d12
  #           elseif clase == 'Bardo' then
  #                1d8
  #           elseif clase == 'Clérigo' then
  #                1d8
  #           elseif clase == 'Druida' then
  #                1d8
  #           elseif clase == 'Hechicero' then
  #                1d6
  #           elseif clase == 'Mago' then
  #                1d6
  #           elseif clase == 'Monje' then
  #                1d8
  #           elseif clase == 'Paladín' then
  #                1d10
  #           elseif clase == 'Pícaro' then
  #                1d8
  #           elseif clase == 'Ranger' then
  #                1d10
  #           elseif clase == 'Sorcerer' then
  #                1d6
  #           elseif clase == 'Warlock' then
  #                1d8
  #           elseif clase == 'Wizard' then
  #                1d6
  #           else
  #                0
  #           end
  #       end

  #       function obtener_pasivas_raza(raza) do
  #           if raza == 'Humano' then
  #                ['Versatilidad', 'Conocimiento adicional']
  #           else if raza == 'Elfo' then
  #                ['Sentidos agudos', 'Hablar con animales']
  #           else if raza == 'Enano' then
  #                ['Resistencia a venenos', 'Visión en la oscuridad']
  #           else if raza == 'Gnomo' then
  #                ['Conocimiento de la ilusión', 'Ingenio gnómico']
  #           else if raza == 'Mediano' then
  #                ['Aptitud para sigilo', 'Suerte de los mediano']
  #           else if raza == 'Dragonborn' then
  #                ['Aliento de dragón', 'Resistencia al daño']
  #           else if raza == 'Orco' then
  #                ['Furia', 'Resistencia implacable']
  #           else if raza == 'Tiefling' then
  #                ['Infernal Legacy', 'Resistencia al fuego']
  #           else
  #                []
  #           end
  #       end

  #       function generar_ficha(nombre) do
  #           nombre = nombre
  #           edad = 1d20 + 10
  #           fuerza = 1d10
  #           inteligencia = 1d10

  #           razas = ['Humano', 'Elfo', 'Enano', 'Gnomo', 'Mediano', 'Dragonborn', 'Orco', 'Tiefling']
  #           clases = ['Bárbaro', 'Bardo', 'Clérigo', 'Druida', 'Hechicero', 'Mago', 'Monje', 'Paladín', 'Pícaro', 'Ranger', 'Sorcerer', 'Warlock', 'Wizard']
  #           numero_de_razas = contar_longitud(razas)
  #           numero_de_clases = contar_longitud(clases)
  #           raza = razas[1dnumero_de_razas)]
  #           clase = clases[1dnumero_de_clases)]

  #           vida_por_nivel = obtener_vida_por_nivel(clase)
  #           nivel = 1d10

  #           vida_total = nivel * vida_por_nivel

  #           pasivas_raza = obtener_pasivas_raza(raza)
  #           [nombre, edad, fuerza, inteligencia, raza, pasivas_raza, clase,nivel, vidad_total]
  #       end

  #       generar_ficha('PRUEBA')
  #       "

  #     try do
  #       result = eval_input(input)
  #       assert result == [~c"hola mundo ", ~c"hola mundo "]
  #     rescue
  #       error -> assert false == error
  #     end
  #   end
end
