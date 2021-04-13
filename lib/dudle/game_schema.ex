defmodule Dudle.GameSchema do
  use Ecto.Schema

  embedded_schema do
    field :name, :string
  end
end

defmodule Dudle.PromptMap do
  use Ecto.Schema

  embedded_schema do
    # field :mappy, {:map, Dudle.GameSchema}
  end
end

