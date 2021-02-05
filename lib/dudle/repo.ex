defmodule Dudle.Repo do
  use Ecto.Repo,
    otp_app: :dudle,
    adapter: Ecto.Adapters.Postgres
end
