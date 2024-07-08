defmodule CowRoll.Sheet do
  use CowRoll.File

  @directory_id "directory_id"
  @name "name"
  @user_id "user_id"
  @type_key "type"
  def get_attributes(params) do
    get_base_attributes(params)
  end

  def create_file(user_id, params) do
    params = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
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
        content: get_content(file),
        directoryId: get_directory_id(file)
      }
    else
      %{}
    end
  end
end
