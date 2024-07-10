defmodule CowRoll.DirectoryBehaviour do
  @callback get_attributes(map()) :: map()
  @callback directory_to_json(map()) :: map()
  @callback update_directory(any(), map()) :: {:error, any()} | {:ok, any()}
  @callback create_directory(any(), map()) :: {:error, any()} | {:ok, any()}
end
