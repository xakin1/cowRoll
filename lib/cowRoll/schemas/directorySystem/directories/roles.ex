defmodule CowRoll.Rol do
  use CowRoll.Directory

  @description "description"
  @image "image"

  def get_attributes(params) do
    base_attributes = get_base_attributes(params)

    Map.merge(base_attributes, %{
      @description => params["description"],
      @image => params["image"]
    })
  end

  defp get_description(params) do
    params[@description]
  end

  defp get_image(params) do
    params[@image]
  end

  def create_directory(user_id, params) do
    to_insert = %{
      get_user_id_key() => user_id,
      get_parent_id_key() => get_parent_id(params),
      get_name_key() => get_name(params),
      @image => get_image(params),
      @description => get_description(params),
      get_type_key() => get_type(params)
    }

    {:ok, id} = insert_directory(user_id, to_insert)
    name = "Sheets"

    CowRoll.Directory.create_directory(user_id, %{
      get_name_key() => name,
      get_parent_id_key() => id
    })

    name = "Codes"

    CowRoll.Directory.create_directory(user_id, %{
      get_name_key() => name,
      get_parent_id_key() => id
    })

    {:ok, id}
  end

  def directory_to_json(directory) do
    if(directory != nil) do
      %{
        id: get_id(directory),
        name: get_name(directory),
        type: get_type(directory),
        image: get_image(directory),
        description: get_description(directory),
        parentId: get_parent_id(directory)
      }
    else
      %{}
    end
  end
end
