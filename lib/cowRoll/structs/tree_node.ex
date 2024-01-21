defmodule TreeNode do
  # def create_new_map do
  #   tree_name \\ @tree_name = create_unique_id()
  #   create_varMap(tree_name \\ @tree_name)
  #   tree_name \\ @tree_name
  # end

  @tree :tree

  @tree_name :tree

  # id: unico en todo el arbol
  # name: unico entre hermanos y con algun descendiente directo
  # referencia del poadre, si es nil indicará que estamos en el primer nodo
  defstruct id: nil, name: nil, parent_id: nil, value: %{}, children: []

  defp create_unique_id do
    var_map_name =
      String.to_atom("#{:erlang.unique_integer([:positive, :monotonic])}")

    var_map_name
  end

  def new(name, parent_id \\ nil) do
    %TreeNode{id: create_unique_id(), name: name, parent_id: parent_id, value: %{}, children: []}
  end

  @spec delete_tree() :: true
  def delete_tree(name \\ @tree) do
    :ets.delete(name)
  end

  @spec create_tree() :: any()
  def create_tree(tree \\ @tree, tree_name \\ @tree_name) do
    # Comprobamos si existe
    case :lists.member(tree, :ets.all()) do
      false ->
        :ets.new(tree, [:named_table, read_concurrency: true, write_concurrency: true])
        node = new(tree_name)
        :ets.insert(tree, {tree_name, node})
        node

      true ->
        :ets.lookup_element(tree, tree_name, 2)
    end
  end

  @spec get_tree(any()) :: any()
  def get_tree(tree \\ @tree, tree_name \\ @tree_name) do
    try do
      :ets.lookup_element(tree, tree_name, 2)
    rescue
      _ -> false
    end
  end

  @spec update_tree(atom() | :ets.tid(), any(), any()) :: any()
  def update_tree(tree \\ @tree, tree_name \\ @tree_name, node) do
    case get_tree(tree_name) do
      false ->
        :ets.insert(tree, {tree_name, node})
        get_tree(tree, tree_name)

      _ ->
        :ets.update_element(tree, tree_name, {2, node})
        get_tree(tree, tree_name)
    end
  end

  # Función auxiliar recursiva para eliminar un scope
  defp remove_scope_recursive(node, node_target_id) do
    case node.id do
      ^node_target_id ->
        []

      _ ->
        updated_children =
          for node_child <- node.children, do: remove_scope_recursive(node_child, node_target_id)

        %TreeNode{node | children: remove_empty_nodes(updated_children)}
    end
  end

  defp remove_empty_nodes(nodes) do
    Enum.filter(nodes, fn child -> child != [] end)
  end

  def remove_scope(tree \\ @tree, tree_name \\ @tree_name, node_target_id) do
    tree_node = get_tree(tree, tree_name)
    updated_tree = remove_scope_recursive(tree_node, node_target_id)
    update_tree(updated_tree)
  end

  defp insert_value_recursive(node, node_target_id, var_name, value) do
    if node.id == node_target_id or
         (Map.has_key?(node.value, var_name) and parent_of_target_node?(node, node_target_id)) do
      # Encontramos el nodo padre, agregamos la variable
      values_updates = Map.put(node.value, var_name, value)
      %TreeNode{node | value: values_updates}
    else
      # No es el nodo buscado, continuamos buscando en los hijos
      updated_children =
        Enum.map(node.children, fn node_child ->
          insert_value_recursive(node_child, node_target_id, var_name, value)
        end)

      %TreeNode{node | children: updated_children}
    end
  end

  # Si la variable ya existe en ese scope simplemente actualiza el valor
  @spec add_variable_to_scope(any(), any(), any()) :: any()
  def add_variable_to_scope(node_id, var_name, value) do
    tree = get_tree()
    updated_tree = insert_value_recursive(tree, node_id, var_name, value)
    update_tree(updated_tree)
    value
  end

  # No hace falta el id del nodo pues siempre se declararan como funciones globales
  @spec add_fuction_to_scope(any(), any(), any()) :: any()
  def add_fuction_to_scope(function_name, parameters, code) do
    tree = get_tree()
    tree = %TreeNode{tree | value: %{function_name => %{parameters: parameters, code: code}}}
    update_tree(tree)
    code
  end

  defp parent_of_target_node?(node, node_target_id) do
    if node.id == node_target_id do
      true
    else
      # No es el nodo buscado, continuamos buscando en los hijos
      kinship =
        Enum.map(node.children, fn node_child ->
          parent_of_target_node?(node_child, node_target_id)
        end)

      Enum.reduce(kinship, false, fn is_parent, acc -> is_parent or acc end)
    end
  end

  defp get_value_recursive(node, node_target_id, var_name) do
    if node.id == node_target_id or
         (Map.has_key?(node.value, var_name) and parent_of_target_node?(node, node_target_id)) do
      # Encontramos el nodo padre, agregamos la variable
      case Map.fetch(node.value, var_name) do
        {:ok, value} -> value
        _ -> false
      end
    else
      # No es el nodo buscado, continuamos buscando en los hijos
      Enum.reduce(node.children, false, fn node_child, acc ->
        case get_value_recursive(node_child, node_target_id, var_name) do
          false ->
            acc

          value ->
            value
        end
      end)
    end
  end

  def get_variable_from_scope(node_id, var_name) do
    tree = get_tree()
    get_value_recursive(tree, node_id, var_name)
  end

  @spec add_scope(any(), any()) :: any()
  def add_scope(tree \\ @tree, tree_name \\ @tree_name, node_parent_id, scope_name) do
    tree_node = get_tree(tree, tree_name)

    case add_scope_recursive(tree_node, node_parent_id, scope_name) do
      {update_tree, nil} ->
        node = update_tree(update_tree)
        node.id

      {update_tree, new_node} ->
        update_tree(update_tree)
        new_node.id
    end
  end

  # Función auxiliar recursiva para agregar un scope
  defp add_scope_recursive(node, node_target_id, scope_name) do
    if node.id == node_target_id do
      # Encontramos el nodo padre, agregamos el scope
      new_node = new(scope_name, node.id)
      updated_children = [new_node | node.children]
      {%TreeNode{node | children: updated_children}, new_node}
    else
      # No es el nodo buscado, continuamos buscando en los scope
      {updated_children, new_node} =
        Enum.reduce(node.children, {[], nil}, fn node_child, {acc, created_node} ->
          case add_scope_recursive(node_child, node_target_id, scope_name) do
            {child_updated_children, nil} ->
              {[child_updated_children | acc], created_node}

            {child_updated_children, child_new_node} ->
              {[child_updated_children | acc], child_new_node}
          end
        end)

      {%TreeNode{node | children: updated_children}, new_node}
    end
  end
end
