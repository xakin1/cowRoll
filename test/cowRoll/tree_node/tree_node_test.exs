defmodule CowRoll.TreeNodeTest do
  alias CowRoll.TreeNodeTest
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import TreeNode

  describe "tree CRUD Operations" do
    test "new node" do
      node = new(:test)

      expect = %TreeNode{
        id: :"1",
        name: :test,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = new("test")

      expect = %TreeNode{
        id: :"2",
        name: "test",
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect
    end

    test "Create tree" do
      node = create_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = create_tree()
      assert node == expect
    end

    test "Create tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = create_tree(tree, tree_name)

      expect = %TreeNode{
        id: :"1",
        name: tree_name,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = create_tree(tree, tree_name)
      assert node == expect

      node = create_tree()

      expect = %TreeNode{
        id: :"2",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect
    end

    test "get tree" do
      node = get_tree()

      assert node == false

      create_tree()
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect
    end

    test "get tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = get_tree(tree, tree_name)
      assert node == false

      create_tree(tree, tree_name)
      node = get_tree()
      assert node == false

      node = get_tree(tree, tree_name)

      expect = %TreeNode{
        id: :"1",
        name: tree_name,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect
    end

    test "delete tree" do
      create_tree()
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      delete_tree()
      node = get_tree()
      expect = false
      assert node == expect
    end

    test "delete tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = create_tree(tree, tree_name)

      expect = %TreeNode{
        id: :"1",
        name: tree_name,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      delete_tree(tree)
      node = get_tree(tree, tree_name)
      expect = false
      assert node == expect
    end

    test "update tree" do
      node = create_tree()
      node = %TreeNode{node | children: [new(:child)]}

      nodeUpdate = update_tree(node)
      assert node == nodeUpdate
      %TreeNode{node | children: node.children ++ [new(:child)]}
      assert node == nodeUpdate
    end

    test "update tree with parameters" do
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

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{},
            children: []
          }
        ]
      }

      assert node == expect

      add_scope(node.id, :tree)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"3",
            name: :tree,
            parent_id: :"1",
            value: %{},
            children: []
          },
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{},
            children: []
          }
        ]
      }

      assert node == expect

      add_scope(:"2", :child_3)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{},
            children: [
              %TreeNode{
                id: :"4",
                name: :child_3,
                parent_id: :"2",
                value: %{},
                children: []
              }
            ]
          },
          %TreeNode{
            id: :"3",
            name: :tree,
            parent_id: :"1",
            value: %{},
            children: []
          }
        ]
      }

      assert node == expect
    end

    test "delete scopes" do
      node = create_tree()
      add_scope(node.id, :child)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{},
            children: []
          }
        ]
      }

      assert node == expect

      node = remove_scope(:"2")

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      add_scope(:"1", :child)

      add_scope(:"3", :chil_2)

      node = remove_scope(:"3")

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      add_scope(:"1", :child)

      add_scope(:"1", :chil_2)

      node = remove_scope(:"5")

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"6",
            name: :chil_2,
            parent_id: :"1",
            value: %{},
            children: []
          }
        ]
      }

      assert node == expect

      node = remove_scope(:"1")

      expect = []

      assert node == expect
    end

    test "insert variables into scopes" do
      node = create_tree()
      add_scope(node.id, :child)
      add_variable_to_scope(:"2", "x", 2)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 2},
            children: []
          }
        ]
      }

      assert node == expect

      add_variable_to_scope(:"2", "x", 3)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 3},
            children: []
          }
        ]
      }

      assert node == expect

      add_scope(:"2", :child_2)
      add_variable_to_scope(:"3", "x", 4)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect

      add_variable_to_scope(:"3", "y", 4)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{"y" => 4},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect

      add_variable_to_scope(:"3", "z", 4)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{"y" => 4, "z" => 4},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect

      add_variable_to_scope(:"2", "z", 4)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 4, "z" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{"y" => 4, "z" => 4},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect

      add_scope(:"1", :child_3)
      add_variable_to_scope(:"4", "x", 4)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"4",
            name: :child_3,
            parent_id: :"1",
            value: %{"x" => 4},
            children: []
          },
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 4, "z" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{"y" => 4, "z" => 4},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect

      add_variable_to_scope(:"3", "x", 5)
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: [
          %TreeNode{
            id: :"4",
            name: :child_3,
            parent_id: :"1",
            value: %{"x" => 4},
            children: []
          },
          %TreeNode{
            id: :"2",
            name: :child,
            parent_id: :"1",
            value: %{"x" => 5, "z" => 4},
            children: [
              %TreeNode{
                id: :"3",
                name: :child_2,
                parent_id: :"2",
                value: %{"y" => 4, "z" => 4},
                children: []
              }
            ]
          }
        ]
      }

      assert node == expect
    end

    test "insert fucntions into scopes" do
      create_tree()
      add_function_to_scope({:name, "hola_mundo", 1}, "msg", "IO.puts(msg)")
      node = get_tree()

      expect = %TreeNode{
        id: :"1",
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
      }

      assert node == expect
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

      assert result == false
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
