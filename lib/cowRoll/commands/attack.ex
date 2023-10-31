defmodule Attack do
  use DiceRoller, :roll_dice

  @spec __using__(any()) ::
          {:import, [{:column, 7} | {:context, Attack}, ...], [{:__aliases__, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Attack
    end
  end

  # Comprobamos si podemos atacar -> atacamos -> calculamos daños
  @spec do_attack(nil | maybe_improper_list() | map()) ::
          {:error, any()} | {:ok, false} | {:ok, any(), any()}
  def do_attack(command) do
    case hit_success?(command) do
      {:ok, true} -> do_hits(command)
      {:ok, :critical_success} -> critical_hit(command)
      {:ok, false} -> {:ok, false}
      {:error, error} -> {:error, error}
    end
  end

  # comprobamos si podemos atacar, faltaría sumarle algún bonificador
  # dependiendo de sus atributos
  @spec hit_success?(nil | maybe_improper_list() | map()) ::
          {:error, <<_::64, _::_*8>>} | {:ok, :critical_success | false | true}
  def hit_success?(command) do
    case roll_dice(command["weapon"]["attackRoll"]) do
      {:ok, dice} ->
        case dice do
          # una pifia siempre falla
          1 ->
            {:ok, false}

          # un critico siempre acierta y además tiras dos veces todos los dados
          20 ->
            {:ok, :critical_success}

          _ ->
            case command["target"]["ca"] do
              nil ->
                {:error, "No CA was found"}

              ca ->
                {:ok, dice > ca}
            end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # en un cr itico lanzamos otra vez todos los dados
  defp critical_hit(command) do
    case get_list_of_dices(command) do
      {:ok, list_of_dices} ->
        case calc_total_dmg(list_of_dices ++ list_of_dices, command["target"]) do
          {:ok, list_of_results, total_damage} -> {:ok, :critical, list_of_results, total_damage}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_hits(command) do
    case get_list_of_dices(command) do
      {:ok, list_of_dices} ->
        case calc_total_dmg(list_of_dices, command["target"]) do
          {:ok, list_of_results, total_damage} -> {:ok, list_of_results, total_damage}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp calc_total_dmg(list_of_dices, target) do
    try do
      results =
        Enum.reduce(list_of_dices, {[], 0}, fn item, {dice_results, acc} ->
          case roll_dice(item["dice"]) do
            {:ok, dice} ->
              # Guardamos la lista de dados para mostrarlos en el resultado
              list_of_dice_results = [{item, dice} | dice_results]
              # Hay que tener en cuenta las reducciones de daño, ya que el daño no es
              # solo el valor del dado
              total_acc = acc + calc_dmg_of_dice(dice, item["dmgType"], target)
              {list_of_dice_results, total_acc}

            {:error, error} ->
              throw({:error, error})
          end
        end)

      # Obtiene la lista de resultados de los dados
      dice_results = elem(results, 0)
      # Obtiene el daño total
      total_damage = elem(results, 1)

      {:ok, dice_results, total_damage}
    catch
      {:error, error} -> {:error, error}
    end
  end

  # Daño total que le vamos a realizar al enemigo
  defp calc_dmg_of_dice(dice, type_of_damage, target) do
    [nature_of_damage, element_of_damage] = String.split(type_of_damage, " ")

    case target["resistences"][element_of_damage][nature_of_damage] do
      nil -> dice
      # Realmente aqui sería a eleccion si truncar o redondear
      damage_reduction -> round(dice * damage_reduction)
    end
  end

  # Obtenemos todos los dados que van a hacer daño
  defp get_list_of_dices(command) do
    try do
      list_of_dices =
        case command["weapon"]["additionalDice"] do
          nil -> [command["weapon"]["dice"]]
          additional_dice -> [command["weapon"]["dice"] | additional_dice]
        end

      {:ok, list_of_dices}
    rescue
      _ -> {:error, "Error: can't get all dices"}
    end
  end
end
