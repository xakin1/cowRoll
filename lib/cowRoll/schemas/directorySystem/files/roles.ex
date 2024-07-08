defmodule CowRoll.Rol do
  use CowRoll.File

  @directory_id "directory_id"
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

  def create_file(user_id, params) do
    params = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
      @image => get_image(params),
      @description => get_description(params),
      @type_key => get_type(params)
    }

    insert_file(user_id, params)
  end

  def file_to_json(file) do
    if(file != nil) do
      %{
        id: get_id(file),
        name: get_name(file),
        type: get_type(file),
        image: get_image(file),
        description: get_description(file),
        directoryId: get_directory_id(file)
      }
    else
      %{}
    end
  end
end
