defmodule CowRollWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CowRollWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint CowRollWeb.Endpoint

      use CowRollWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import ExUnit.Case
      import Phoenix.ConnTest
      import CowRollWeb.ConnCase
    end
  end

  # Se ejecuta al principio de cada test
  setup _tags do
    Mix.shell.info "Reset all data"
    Mongo.delete_many(:mongo, "code", %{})
    # Se ejecuta al final de cada test
    on_exit(fn ->
      Mongo.delete_many(:mongo, "code", %{})
    end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}

  end
end
