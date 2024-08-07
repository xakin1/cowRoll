defmodule CowRoll.Sheet do
  use CowRoll.File

  @directory_id "directory_id"
  @name "name"
  @user_id "user_id"
  @type_key "type"
  @content "content"
  @codes "codes"
  @pdf "pdf"
  @player "player"
  @file_system "file_system"

  def get_attributes(params) do
    base_attributes = get_base_attributes(params)

    Map.merge(base_attributes, %{
      @codes => params["codes"],
      @pdf => params["pdf"],
      @player => params["player"]
    })
  end

  def get_codes(params) do
    params[@codes]
  end

  def get_player(params) do
    params[@player]
  end

  def get_pdf(params) do
    params[@pdf]
  end

  def create_file(user_id, params) do
    params = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
      @content => get_content(params),
      @pdf => get_pdf(params),
      @player => get_player(params),
      @type_key => get_type(params)
    }

    with {:ok, id} <- insert_file(user_id, params) do
      {:ok, id}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec file_to_json(any()) :: %{
          optional(:codes) => list(),
          optional(:content) => any(),
          optional(:directoryId) => any(),
          optional(:id) => any(),
          optional(:name) => any(),
          optional(:pdf) => any(),
          optional(:player) => any(),
          optional(:type) => any()
        }
  def file_to_json(file) do
    if(file != nil) do
      subdirectories =
        Mongo.find(:mongo, @file_system, %{
          @directory_id => get_id(file)
        })
        |> Enum.to_list()

      %{
        id: get_id(file),
        name: get_name(file),
        type: get_type(file),
        content: get_content(file),
        pdf: get_pdf(file),
        player: get_player(file),
        codes:
          Enum.map(subdirectories, fn file ->
            default_file_to_json(file)
          end),
        directoryId: get_directory_id(file)
      }
    else
      %{}
    end
  end
end
