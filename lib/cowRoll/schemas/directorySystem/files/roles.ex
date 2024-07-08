defmodule CowRoll.Rol do
  @file_type "Rol"
  use CowRoll.File, @file_type

  @directory_id "directory_id"
  @name "name"
  @user_id "user_id"
  @type_key "type"
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

  def create_file(user_id, params) do
    params = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
      @image => get_image(params),
      @description => get_description(params),
      @type_key => @file_type
    }

    insert_file(user_id, params)
  end

  def update_file(user_id, params) do
    update_file(user_id, params, @file_type)
  end

  def get_files_with_sheets(params) do
    query = %{
      @type_key => @file_type
    }

    query = Map.merge(query, params)
    get_files(query)
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
