defmodule DirectoryNode do
  defstruct type: "directory", children: %{}
end

defmodule FileNode do
  defstruct type: "file", content: ""
end
