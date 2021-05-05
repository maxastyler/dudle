defmodule Dudle.GameServer.Events do
  @moduledoc """
  This module contains the implementation for all of the game server events
  """
  alias DudleWeb.Endpoint
  alias Dudle.{Presence, Game, Prompt, Round}

  @doc """
  Get a MapSet of the presence players in the room
  """
  @spec presence_players(String.t()) :: MapSet.t(String.t())
  def presence_players(room) do
    Presence.list("presence:#{room}") |> Map.keys() |> MapSet.new()
  end

  @spec construct_players_map(atom(), %{presence_players: MapSet.t(String.t())}) :: %{
          String.t() => %{}
        }
  def construct_players_map(:lobby, %{presence_players: presence_players, game: nil} = _data) do
    Enum.map(presence_players, &{&1, %{online: true}}) |> Map.new()
  end

  def construct_players_map(
        :submit,
        %{
          presence_players: presence_players,
          game: %{players: players, turn_submissions: turn_submissions}
        } = _data
      ) do
    Enum.map(players, fn p ->
      {p, %{online: p in presence_players, submitted: p in turn_submissions}}
    end)
  end

  def presence_diff(%{room: room} = data) do
    players = presence_players(room)

    {:keep_state, Map.put(data, :presence_players, players),
     [{:next_event, :internal, :broadcast_players}]}
  end

  def broadcast_players(state, %{room: room} = data) do
    Endpoint.broadcast("game:#{room}", "broadcast_players", construct_players_map(state, data))
    :keep_state_and_data
  end

  def broadcast_state(:lobby, %{room: room} = _data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", :lobby)
    :keep_state_and_data
  end

  def broadcast_state(:submit, %{room: room} = _data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", :state_updated)
    :keep_state_and_data
  end

  def get_state(from, :lobby, _data, _player) do
    {:keep_state_and_data, [{:reply, from, :lobby}]}
  end

  def get_state(from, :submit, %{game: %{player_prompts: player_prompts}} = data, player) do
    {:keep_state_and_data, [{:reply, from, {:submit, player_prompts[player]}}]}
  end

  def start_game(from, :lobby, %{presence_players: players} = data) do
    with {:ok, game} <- Game.new(players) do
      new_data = %{data | game: game}

      {:next_state, :submit, new_data,
       [{:reply, from, {:ok, :game_started}}, {:next_event, :internal, :broadcast_state}]}
    else
      {:error, e} -> {:keep_state_and_data, [{:reply, from, {:error, e}}]}
    end
  end

  def submit_prompt(
        from,
        :submit,
        %{game: %{players: players, turn_submissions: turn_submissions}} = data,
        %Prompt{submitter: submitter} = prompt
      ) do
    if submitter in players do
      new_turn_submissions = Map.put(turn_submissions, submitter, prompt)

      {:keep_state, put_in(data, [:game, Game.turn_submissions()], new_turn_submissions),
       cond do
         map_size(new_turn_submissions) >= length(players) ->
           [{:reply, from, {:ok, prompt}}, {:next_event, :internal, :add_submissions_to_round}]

         :else ->
           [{:reply, from, {:ok, prompt}}, {:next_event, :internal, :broadcast_players}]
       end}
    else
      {:keep_state_and_data, [{:reply, from, {:error, "submitting player not in game"}}]}
    end
  end

  def submit_prompt(from, _state, _data, _prompt) do
    {:keep_state_and_data, [{:reply, from, {:error, "not in submitting state"}}]}
  end

  def add_submissions_to_round(
        :submit,
        %{
          game: %{
            turn_submissions: turn_submissions,
            round_submissions: round_submissions,
            player_adjacency: player_adjacency
          }
        } = data
      ) do
    new_round_submissions =
      for {player, prompt} <- turn_submissions, reduce: round_submissions do
        rs -> Map.update!(rs, player, &[prompt | &1])
      end

    new_player_prompts =
      for {player, prompt} <- turn_submissions, into: %{}, do: {player_adjacency[player], prompt}

    {:keep_state,
     put_in(data, [:game, Game.round_submissions()], new_round_submissions)
     |> put_in([:game, Game.player_prompts()], new_player_prompts)
     |> put_in([:game, Game.turn_submissions()], %{}),
     cond do
       new_round_submissions |> Enum.map(fn {_, p} -> length(p) end) |> Enum.min() >=
           map_size(new_round_submissions) ->
         [{:next_event, :internal, :move_to_reviewing_state}]

       :else ->
         []
     end}
  end

  def add_submissions_to_round(_state, _data), do: :keep_state_and_data

  def move_to_reviewing_state(:submit, data) do
    {:next_state, {:review, }}
  end

  def move_to_reviewing_state(_state, _data), do: :keep_state_and_data
end
