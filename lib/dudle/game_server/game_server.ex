defmodule Dudle.GameServer do
  @moduledoc """
  This is an implementation of a game server for playing Dudle.

  The game accepts the 
  """
  use GenStateMachine

  alias Dudle.Game
  import Dudle.GameServer.Events

  def player_name_limit, do: 50

  def room_name_limit, do: 50

  def prompt_text_max_limit, do: 100
  def prompt_text_min_limit, do: 1

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, data, opts)
  end

  @impl true
  def init(%{room: room} = _data) do
    DudleWeb.Endpoint.subscribe("presence:#{room}")
    players = presence_players(room)

    {:ok, :lobby,
     %{
       room: room,
       presence_players: players,
       game: nil,
       prompts: Game.Prompts.prompts()
     }, [{:next_event, :internal, :broadcast_all}]}
  end

  @impl true
  def handle_event(:timeout, _, _, _), do: {:stop, :shutdown}

  def handle_event(:info, %{event: "presence_diff"}, _state, data) do
    presence_diff(data)
  end

  def handle_event(:internal, :broadcast_players, state, data) do
    broadcast_players(state, data)
  end

  def handle_event(:internal, :broadcast_state, state, data) do
    broadcast_state(state, data)
  end

  def handle_event(:internal, :add_submissions_to_round, state, data) do
    add_submissions_to_round(state, data)
  end

  def handle_event(:internal, :move_to_reviewing_state, state, data) do
    move_to_reviewing_state(state, data)
  end

  def handle_event(:internal, :broadcast_all, state, data) do
    broadcast_all(state, data)
  end

  def handle_event({:call, from}, :get_room_name, _state, data) do
    get_room_name(from, data)
  end

  def handle_event({:call, from}, {:get_state, player}, state, data) do
    get_state(from, state, data, player)
  end

  def handle_event({:call, from}, :get_players, state, data) do
    get_players(from, state, data)
  end

  def handle_event({:call, from}, {:join_game, player}, state, data) do
    join_game(from, state, data, player)
  end

  def handle_event({:call, from}, {:start_game, options}, state, data) do
    start_game(from, state, data, options)
  end

  def handle_event({:call, from}, {:submit_prompt, prompt}, state, data) do
    submit_prompt(from, state, data, prompt)
  end

  def handle_event({:call, from}, {:advance_review_state, player}, state, data) do
    advance_review_state(from, state, data, player)
  end

  def handle_event({:call, from}, {:submit_correct, player, correct}, state, data) do
    submit_correct(from, state, data, player, correct)
  end

  def handle_event({:call, from}, {:submit_vote, player, vote}, state, data) do
    submit_vote(from, state, data, player, vote)
  end
end
