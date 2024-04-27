defmodule CowRoll.Startup do
  def ensure_indexes do
    IO.puts "Using database #{Application.get_env(:cowRoll, :db)[:name]}"
    Mongo.command(:mongo, %{createIndexes: "code",
      indexes: [ %{ key: %{ user_id: 1 },
                    name: "user_idx",
                    unique: true} ] })
  end
end
