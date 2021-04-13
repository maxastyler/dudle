defmodule Dudle.Presence do
  use Phoenix.Presence, otp_app: :dudle, pubsub_server: Dudle.PubSub
end
