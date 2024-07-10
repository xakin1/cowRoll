defmodule CowRoll.Rol do
  use CowRoll.Directory

  @parent_id "directory_id"
  @name "name"
  @user_id "user_id"
  @description "description"
  @image "image"
  @type_key "type"

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
      @user_id => user_id,
      @parent_id => get_parent_id(params),
      @name => get_name(params),
      @image => get_image(params),
      @description => get_description(params),
      @type_key => get_type(params)
    }

    insert_directory(user_id, to_insert)
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
