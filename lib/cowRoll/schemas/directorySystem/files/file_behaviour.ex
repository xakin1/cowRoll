defmodule CowRoll.FileBehaviour do
  @callback get_attributes(map()) :: map()
  @callback file_to_json(map()) :: map()
  @callback update_file(any(), map()) :: {:error, any()} | {:ok, any()}
  @callback create_file(any(), map()) :: {:error, any()} | {:ok, any()}
end
