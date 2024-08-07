defmodule CowRoll.TreeNodeTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import TreeNode
  import Verifier

  describe "tree CRUD Operations" do
    test "new node" do
      # Reiniciamos el contador de IDs únicos antes de cada prueba
      node = new(:test)

      case node do
        %TreeNode{
          id: _,
          name: :test,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      node = new("test")

      case node do
        %TreeNode{
          id: _,
          name: "test",
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "Create tree" do
      :erlang.system_flag(:microstate_accounting, :reset)

      node = create_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      node = create_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "Create tree with parameters" do
      :erlang.system_flag(:microstate_accounting, :reset)

      tree = :test
      tree_name = :test_name
      node = create_tree(tree, tree_name)

      case node do
        %TreeNode{
          id: _,
          name: ^tree_name,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      node = create_tree(tree, tree_name)

      case node do
        %TreeNode{
          id: _,
          name: ^tree_name,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      node = create_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "get tree" do
      :erlang.system_flag(:microstate_accounting, :reset)

      node = get_tree()

      assert node == false

      create_tree()
      node = get_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "get tree with parameters" do
      :erlang.system_flag(:microstate_accounting, :reset)

      tree = :test
      tree_name = :test_name
      node = get_tree(tree, tree_name)
      assert node == false

      create_tree(tree, tree_name)
      node = get_tree()
      assert node == false

      node = get_tree(tree, tree_name)

      case node do
        %TreeNode{
          id: _,
          name: ^tree_name,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "delete tree" do
      :erlang.system_flag(:microstate_accounting, :reset)

      create_tree()
      node = get_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      delete_tree()
      node = get_tree()
      expect = false
      assert node == expect
    end

    test "delete tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = create_tree(tree, tree_name)

      case node do
        %TreeNode{
          id: _,
          name: ^tree_name,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true

        _ ->
          assert false
      end

      delete_tree(tree)
      node = get_tree(tree, tree_name)
      expect = false
      assert node == expect
    end

    test "update tree" do
      :erlang.system_flag(:microstate_accounting, :reset)

      node = create_tree()
      node = %TreeNode{node | children: [new(:child)]}

      nodeUpdate = update_tree(node)
      assert node == nodeUpdate
      %TreeNode{node | children: node.children ++ [new(:child)]}
      assert node == nodeUpdate
    end

    test "update tree with parameters" do
      :erlang.system_flag(:microstate_accounting, :reset)

      tree = :test
      tree_name = :test_name
      node = create_tree(tree, tree_name)
      node = %TreeNode{node | children: [new(:child)]}

      nodeUpdate = update_tree(tree, tree_name, node)
      assert node == nodeUpdate
      %TreeNode{node | children: node.children ++ [new(:child)]}
      assert node == nodeUpdate
    end
  end

  describe "operation with childes" do
    test "insert scopes" do
      node = create_tree()
      add_scope(node.id, :child)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{},
              children: []
            }
          ]
        } ->
          assert id1 != id2

        _ ->
          assert false
      end

      add_scope(node.id, :tree)
      node = get_tree()

      id2 =
        case node do
          %TreeNode{
            id: id1,
            name: :tree,
            parent_id: nil,
            value: %{},
            children: [
              %TreeNode{
                id: id3,
                name: :tree,
                parent_id: id1,
                value: %{},
                children: []
              },
              %TreeNode{
                id: id2,
                name: :child,
                parent_id: id1,
                value: %{},
                children: []
              }
            ]
          } ->
            assert are_all_different([id1, id2, id3])
            id2

          _ ->
            assert false
        end

      add_scope(id2, :child_3)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{},
              children: [
                %TreeNode{
                  id: id4,
                  name: :child_3,
                  parent_id: id2,
                  value: %{},
                  children: []
                }
              ]
            },
            %TreeNode{
              id: id3,
              name: :tree,
              parent_id: id1,
              value: %{},
              children: []
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3, id4])

        _ ->
          assert false
      end
    end

    test "delete scopes" do
      node = create_tree()
      add_scope(node.id, :child)
      node = get_tree()

      id2 =
        case node do
          %TreeNode{
            id: id1,
            name: :tree,
            parent_id: nil,
            value: %{},
            children: [
              %TreeNode{
                id: id2,
                name: :child,
                parent_id: id1,
                value: %{},
                children: []
              }
            ]
          } ->
            assert id1 != id2
            id2

          _ ->
            assert false
        end

      node = remove_scope(id2)

      id1 =
        case node do
          %TreeNode{
            id: id1,
            name: :tree,
            parent_id: nil,
            value: %{},
            children: []
          } ->
            assert true
            id1

          _ ->
            assert false
        end

      id3 = add_scope(id1, :child)

      add_scope(id3, :chil_2)

      node = remove_scope(id3)

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: []
        } ->
          assert true
          id1

        _ ->
          assert false
      end

      add_scope(id1, :child)

      id5 = add_scope(id1, :chil_2)

      node = remove_scope(id5)

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id4,
              name: :child,
              parent_id: id1,
              value: %{},
              children: []
            }
          ]
        } ->
          assert id4 != id1

        _ ->
          assert false
      end

      node = remove_scope(id1)

      expect = []

      assert node == expect
    end

    test "insert variables into scopes" do
      node = create_tree()
      id1 = node.id
      id2 = add_scope(id1, :child)
      add_variable_to_scope(id2, "x", 2)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 2},
              children: []
            }
          ]
        } ->
          assert id1 != id2
          id2

        _ ->
          assert false
      end

      add_variable_to_scope(id2, "x", 3)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 3},
              children: []
            }
          ]
        } ->
          assert id1 != id2

        _ ->
          assert false
      end

      id3 = add_scope(id2, :child_2)
      add_variable_to_scope(id3, "x", 4)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3])

        _ ->
          assert false
      end

      add_variable_to_scope(id3, "y", 4)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{"y" => 4},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3])

        _ ->
          assert false
      end

      add_variable_to_scope(id3, "z", 4)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{"y" => 4, "z" => 4},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3])

        _ ->
          assert false
      end

      add_variable_to_scope(id2, "z", 4)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 4, "z" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{"y" => 4, "z" => 4},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3])

        _ ->
          assert false
      end

      id4 = add_scope(id1, :child_3)
      add_variable_to_scope(id4, "x", 4)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id4,
              name: :child_3,
              parent_id: id1,
              value: %{"x" => 4},
              children: []
            },
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 4, "z" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{"y" => 4, "z" => 4},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3, id4])

        _ ->
          assert false
      end

      add_variable_to_scope(id3, "x", 5)
      node = get_tree()

      case node do
        %TreeNode{
          id: id1,
          name: :tree,
          parent_id: nil,
          value: %{},
          children: [
            %TreeNode{
              id: id4,
              name: :child_3,
              parent_id: id1,
              value: %{"x" => 4},
              children: []
            },
            %TreeNode{
              id: id2,
              name: :child,
              parent_id: id1,
              value: %{"x" => 5, "z" => 4},
              children: [
                %TreeNode{
                  id: id3,
                  name: :child_2,
                  parent_id: id2,
                  value: %{"y" => 4, "z" => 4},
                  children: []
                }
              ]
            }
          ]
        } ->
          assert are_all_different([id1, id2, id3, id4])

        _ ->
          assert false
      end
    end

    test "insert fucntions into scopes" do
      create_tree()
      add_function_to_scope({:name, "hola_mundo", 1}, "msg", "IO.puts(msg)")
      node = get_tree()

      case node do
        %TreeNode{
          id: _,
          name: :tree,
          parent_id: nil,
          value: %{
            {:name, "hola_mundo"} => %{
              code: "IO.puts(msg)",
              type: :code,
              parameters: "msg"
            }
          },
          children: []
        } ->
          assert true

        _ ->
          assert false
      end
    end

    test "get variables" do
      node_tree = create_tree()
      node_2_id = add_scope(node_tree.id, :child)
      add_variable_to_scope(node_2_id, "x", 2)
      add_variable_to_scope(node_2_id, "x", 3)
      node_3_id = add_scope(node_2_id, :child_2)
      add_variable_to_scope(node_3_id, "x", 5)
      node_4_id = add_scope(node_tree, :child_3)
      add_variable_to_scope(node_4_id, "x", 4)
      add_variable_to_scope(node_4_id, "z", 3)
      get_tree()

      result = get_variable_from_scope(node_4_id, "x")

      assert result == 4
    end

    test "get variables that not exist" do
      node_tree = create_tree()
      node_2_id = add_scope(node_tree.id, :child)
      add_variable_to_scope(node_2_id, "x", 2)
      add_variable_to_scope(node_2_id, "x", 3)
      node_3_id = add_scope(node_2_id, :child_2)
      add_variable_to_scope(node_3_id, "x", 5)
      node_4_id = add_scope(node_tree, :child_3)
      add_variable_to_scope(node_4_id, "x", 4)
      add_variable_to_scope(node_4_id, "z", 3)
      get_tree()

      result = get_variable_from_scope(:"-1", "x")

      assert result == :not_found
    end

    test "get function" do
      create_tree()
      add_function_to_scope({:name, "hola_mundo", 1}, "msg", "IO.puts(msg)")
      {parameters, code} = get_fuction_from_scope({:name, "hola_mundo", 1})

      assert parameters == "msg"
      assert code == "IO.puts(msg)"

      {parameters, code} = get_fuction_from_scope({:name, "hola_mundo", 1})

      assert parameters == "msg"
      assert code == "IO.puts(msg)"

      add_function_to_scope({:name, "hola_mundo2", 1}, nil, "IO.puts(msg)")
      {parameters, code} = get_fuction_from_scope({:name, "hola_mundo2", 1})

      assert parameters == nil
      assert code == "IO.puts(msg)"

      exists? = get_fuction_from_scope({:name, "hola_mundo3", 1})

      assert exists? == {false, "hola_mundo3", 1}
    end
  end
end
