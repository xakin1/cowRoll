defmodule CowRoll.TreeNodeTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "tree CRUD Operations" do
    test "new node" do
      node = TreeNode.new(:test)

      expect = %TreeNode{
        id: :"1",
        name: :test,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = TreeNode.new("test")

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
      node = TreeNode.create_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = TreeNode.create_tree()
      assert node == expect
    end

    test "Create tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = TreeNode.create_tree(tree, tree_name)

      expect = %TreeNode{
        id: :"1",
        name: tree_name,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      node = TreeNode.create_tree(tree, tree_name)
      assert node == expect

      node = TreeNode.create_tree()

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
      node = TreeNode.get_tree()

      assert node == false

      TreeNode.create_tree()
      node = TreeNode.get_tree()

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
      node = TreeNode.get_tree(tree, tree_name)
      assert node == false

      TreeNode.create_tree(tree, tree_name)
      node = TreeNode.get_tree()
      assert node == false

      node = TreeNode.get_tree(tree, tree_name)

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
      TreeNode.create_tree()
      node = TreeNode.get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      TreeNode.delete_tree()
      node = TreeNode.get_tree()
      expect = false
      assert node == expect
    end

    test "delete tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = TreeNode.create_tree(tree, tree_name)

      expect = %TreeNode{
        id: :"1",
        name: tree_name,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      TreeNode.delete_tree(tree)
      node = TreeNode.get_tree(tree, tree_name)
      expect = false
      assert node == expect
    end

    test "update tree" do
      node = TreeNode.create_tree()
      node = %TreeNode{node | children: [TreeNode.new(:child)]}

      nodeUpdate = TreeNode.update_tree(node)
      assert node == nodeUpdate
      %TreeNode{node | children: node.children ++ [TreeNode.new(:child)]}
      assert node == nodeUpdate
    end

    test "update tree with parameters" do
      tree = :test
      tree_name = :test_name
      node = TreeNode.create_tree(tree, tree_name)
      node = %TreeNode{node | children: [TreeNode.new(:child)]}

      nodeUpdate = TreeNode.update_tree(tree, tree_name, node)
      assert node == nodeUpdate
      %TreeNode{node | children: node.children ++ [TreeNode.new(:child)]}
      assert node == nodeUpdate
    end
  end

  describe "operation with childes" do
    test "insert scopes" do
      node = TreeNode.create_tree()
      TreeNode.add_scope(node.id, :child)
      node = TreeNode.get_tree()

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

      TreeNode.add_scope(node.id, :tree)
      node = TreeNode.get_tree()

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

      TreeNode.add_scope(:"2", :child_3)
      node = TreeNode.get_tree()

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
      node = TreeNode.create_tree()
      TreeNode.add_scope(node.id, :child)
      node = TreeNode.get_tree()

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

      node = TreeNode.remove_scope(:"2")

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      TreeNode.add_scope(:"1", :child)

      TreeNode.add_scope(:"3", :chil_2)

      node = TreeNode.remove_scope(:"3")

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{},
        children: []
      }

      assert node == expect

      TreeNode.add_scope(:"1", :child)

      TreeNode.add_scope(:"1", :chil_2)

      node = TreeNode.remove_scope(:"5")

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

      node = TreeNode.remove_scope(:"1")

      expect = []

      assert node == expect
    end

    test "insert variables into scopes" do
      node = TreeNode.create_tree()
      TreeNode.add_scope(node.id, :child)
      TreeNode.add_variable_to_scope(:"2", "x", 2)
      node = TreeNode.get_tree()

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

      TreeNode.add_variable_to_scope(:"2", "x", 3)
      node = TreeNode.get_tree()

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

      TreeNode.add_scope(:"2", :child_2)
      TreeNode.add_variable_to_scope(:"3", "x", 4)
      node = TreeNode.get_tree()

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

      TreeNode.add_variable_to_scope(:"3", "y", 4)
      node = TreeNode.get_tree()

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

      TreeNode.add_variable_to_scope(:"3", "z", 4)
      node = TreeNode.get_tree()

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

      TreeNode.add_variable_to_scope(:"2", "z", 4)
      node = TreeNode.get_tree()

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

      TreeNode.add_scope(:"1", :child_3)
      TreeNode.add_variable_to_scope(:"4", "x", 4)
      node = TreeNode.get_tree()

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

      TreeNode.add_variable_to_scope(:"3", "x", 5)
      node = TreeNode.get_tree()

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
      TreeNode.create_tree()
      TreeNode.add_fuction_to_scope("hola_mundo", "msg", "IO.puts(msg)")
      node = TreeNode.get_tree()

      expect = %TreeNode{
        id: :"1",
        name: :tree,
        parent_id: nil,
        value: %{"hola_mundo" => %{parameters: "msg", code: "IO.puts(msg)"}},
        children: []
      }

      assert node == expect
    end

    test "get variables" do
      node_tree = TreeNode.create_tree()
      node_2_id = TreeNode.add_scope(node_tree.id, :child)
      TreeNode.add_variable_to_scope(node_2_id, "x", 2)
      TreeNode.add_variable_to_scope(node_2_id, "x", 3)
      node_3_id = TreeNode.add_scope(node_2_id, :child_2)
      TreeNode.add_variable_to_scope(node_3_id, "x", 5)
      node_4_id = TreeNode.add_scope(node_tree, :child_3)
      TreeNode.add_variable_to_scope(node_4_id, "x", 4)
      TreeNode.add_variable_to_scope(node_4_id, "z", 3)
      TreeNode.get_tree()

      result = TreeNode.get_variable_from_scope(node_4_id, "x")

      assert result == 4
    end

    test "get variables that not exist" do
      node_tree = TreeNode.create_tree()
      node_2_id = TreeNode.add_scope(node_tree.id, :child)
      TreeNode.add_variable_to_scope(node_2_id, "x", 2)
      TreeNode.add_variable_to_scope(node_2_id, "x", 3)
      node_3_id = TreeNode.add_scope(node_2_id, :child_2)
      TreeNode.add_variable_to_scope(node_3_id, "x", 5)
      node_4_id = TreeNode.add_scope(node_tree, :child_3)
      TreeNode.add_variable_to_scope(node_4_id, "x", 4)
      TreeNode.add_variable_to_scope(node_4_id, "z", 3)
      TreeNode.get_tree()

      result = TreeNode.get_variable_from_scope(:"-1", "x")

      assert result == false
    end

    test "get function" do
      TreeNode.create_tree()
      TreeNode.add_fuction_to_scope("hola_mundo", "msg", "IO.puts(msg)")
      {parameters, code} = TreeNode.get_fuction_from_scope("hola_mundo")

      assert parameters == "msg"
      assert code == "IO.puts(msg)"

      {parameters, code} = TreeNode.get_fuction_from_scope("hola_mundo")

      assert parameters == "msg"
      assert code == "IO.puts(msg)"

      TreeNode.add_fuction_to_scope("hola_mundo2", nil, "IO.puts(msg)")
      {parameters, code} = TreeNode.get_fuction_from_scope("hola_mundo2")

      assert parameters == nil
      assert code == "IO.puts(msg)"

      exists? = TreeNode.get_fuction_from_scope("hola_mundo3")

      assert exists? == false
    end
  end
end
