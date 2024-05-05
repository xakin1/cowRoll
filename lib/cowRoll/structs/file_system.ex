defmodule FileSystem do
  def init_root do
    %DirectoryNode{}
  end

  def add_file(directory, name, content) when is_map(directory) do
    update_in(directory.children, [name], fn _ ->
      %FileNode{content: content}
    end)
  end

  def add_directory(directory, name) when is_map(directory) do
    update_in(directory.children, [name], fn _ ->
      %DirectoryNode{}
    end)
  end

  def list_directory(directory) do
    directory.children
  end
end
