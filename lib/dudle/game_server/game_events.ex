defmodule Dudle.GameServer.Events do
  @moduledoc """
  This module contains the implementation for all of the game server events
  """
  alias DudleWeb.Endpoint
  alias Dudle.{Presence, Game, Prompt, Round, Options, GameServer}

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
  def construct_players_map(s, %{presence_players: presence_players, game: nil} = _data)
      when s in [:lobby, :end] do
    Enum.map(presence_players, &{&1, %{online: true}}) |> Map.new()
  end

  def construct_players_map(
        :submit,
        %{
          presence_players: presence_players,
          game: %{players: players, turn_submissions: turn_submissions, scores: scores}
        } = _data
      ) do
    Enum.map(players, fn p ->
      {p, %{online: p in presence_players, submitted: p in turn_submissions, score: scores[p]}}
    end)
    |> Map.new()
  end

  def construct_players_map(
        _,
        %{
          presence_players: presence_players,
          game: %{players: players, scores: scores}
        } = _data
      ) do
    Enum.map(players, fn p ->
      {p, %{online: p in presence_players, score: scores[p]}}
    end)
    |> Map.new()
  end

  defp add_to_player_score(data, _, 0), do: data

  defp add_to_player_score(data, player, amount) do
    update_in(data, [Lens.key(:game) |> Game.scores() |> Lens.key(player)], &(&1 + amount))
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

  defp format_review_state({:review, {player, element} = inner} = _state, %{room: room} = data) do
    {:review,
     {inner,
      get_in(data, [
        Lens.key(:game)
        |> Game.rounds()
        |> Lens.at(0)
        |> Round.prompts()
        |> Lens.key(player)
        |> Lens.at(element),
        Access.at(0)
      ])}}
  end

  def broadcast_state({:review, {player, element}} = state, %{room: room} = data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", format_review_state(state, data))
    :keep_state_and_data
  end

  def broadcast_state({:correct, _} = state, %{room: room} = _data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", state)
    :keep_state_and_data
  end

  def broadcast_state({:vote, _} = state, %{room: room} = _data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", state)
    :keep_state_and_data
  end

  def broadcast_state(:end, %{room: room, game: %{scores: scores}} = data) do
    Endpoint.broadcast("game:#{room}", "broadcast_state", {:end, scores})
    :keep_state_and_data
  end

  def get_players(from, state, data) do
    {:keep_state_and_data, [{:reply, from, construct_players_map(state, data)}]}
  end

  def get_state(from, :lobby, _data, _player) do
    {:keep_state_and_data, [{:reply, from, :lobby}]}
  end

  def get_state(from, :submit, %{game: %{player_prompts: player_prompts}} = data, player) do
    {:keep_state_and_data, [{:reply, from, {:submit, player_prompts[player]}}]}
  end

  def get_state(from, {:review, _} = state, data, _player) do
    {:keep_state_and_data, [{:reply, from, format_review_state(state, data)}]}
  end

  def get_state(from, {:vote, _} = state, data, _player) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  def get_state(from, {:correct, _} = state, data, _player) do
    {:keep_state_and_data, [{:reply, from, state}]}
  end

  def get_state(from, :end, %{game: %{scores: scores}} = _data, _player) do
    {:keep_state_and_data, [{:reply, from, {:end, scores}}]}
  end

  def join_game(from, state, %{presence_players: players} = data, player) do
    cond do
      player in players ->
        {:keep_state_and_data,
         [{:reply, from, {:error, "Cannot join: someone is using that name already"}}]}

      String.length(player) > GameServer.player_name_limit() ->
        {:keep_state_and_data,
         [
           {:reply, from,
            {:error,
             "Cannot join: name is too long (under #{GameServer.player_name_limit()} characters please)"}}
         ]}

      String.length(player) < 1 ->
        {:keep_state_and_data, [{:reply, from, {:error, "Cannot join: name is empty"}}]}

      :else ->
        {:keep_state, %{data | presence_players: MapSet.put(players, player)},
         [{:reply, from, {:ok, player}}]}
    end
  end

  def start_game(
        from,
        _state,
        %{presence_players: players, prompts: prompts, options: options} = data
      ) do
    with {:ok, game} <- Game.new(players, prompts, options) do
      new_data = %{data | game: game}

      {:next_state, :submit, new_data,
       [
         {:reply, from, {:ok, :game_started}},
         {:next_event, :internal, :broadcast_state},
         {:next_event, :internal, :broadcast_players}
       ]}
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
    cond do
      submitter not in players ->
        {:keep_state_and_data, [{:reply, from, {:error, "Submitting player not in game"}}]}

      prompt.type == :text and
          (String.length(prompt.data) > GameServer.prompt_text_max_limit() or
             String.length(prompt.data) < GameServer.prompt_text_min_limit()) ->
        {:keep_state_and_data,
         [
           {:reply, from,
            {:error,
             "Prompt must be between #{GameServer.prompt_text_min_limit()} and #{
               GameServer.prompt_text_max_limit()
             } characters long"}}
         ]}

      :else ->
        new_turn_submissions = Map.put(turn_submissions, submitter, prompt)

        {:keep_state, put_in(data, [:game, Game.turn_submissions()], new_turn_submissions),
         cond do
           map_size(new_turn_submissions) >= length(players) ->
             [{:reply, from, :ok}, {:next_event, :internal, :add_submissions_to_round}]

           :else ->
             [{:reply, from, :ok}, {:next_event, :internal, :broadcast_players}]
         end}
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
       new_round_submissions |> Enum.map(fn {_, p} -> length(p) end) |> Enum.min() >
           map_size(new_round_submissions) ->
         [
           {:next_event, :internal, :move_to_reviewing_state}
         ]

       :else ->
         [
           {:next_event, :internal, :broadcast_players},
           {:next_event, :internal, :broadcast_state}
         ]
     end}
  end

  def add_submissions_to_round(_state, _data), do: :keep_state_and_data

  def move_to_reviewing_state(:submit, %{game: %{players: players}} = data) do
    [first_player | reviewing_players] = players

    new_data =
      update_in(data, [:game], &Game.put_submissions_into_rounds/1)
      |> put_in([:players_left], reviewing_players)

    {:next_state, {:review, {first_player, 0}}, new_data,
     [{:next_event, :internal, :broadcast_state}, {:next_event, :internal, :broadcast_players}]}
  end

  def move_to_reviewing_state(_state, _data), do: :keep_state_and_data

  @spec first_and_last_text_prompts([Prompt.t()]) :: {Prompt.t(), Prompt.t()}
  defp first_and_last_text_prompts(prompts) do
    text_prompts = Enum.filter(prompts, fn %Prompt{type: type} -> type == :text end)
    {List.first(text_prompts), List.last(text_prompts)}
  end

  def advance_review_state(from, {:review, {player, element}}, data, calling_player) do
    [round | _] = data.game.rounds
    n_prompts = round.prompts[player] |> length()

    cond do
      calling_player != player ->
        {:keep_state_and_data,
         [{:reply, from, {:error, "You are not the current reviewing player"}}]}

      element >= (n_prompts - 1) ->
        {:next_state, {:correct, {player, first_and_last_text_prompts(round.prompts[player])}},
         data, [{:reply, from, :ok}, {:next_event, :internal, :broadcast_state}]}

      :else ->
        {:next_state, {:review, {player, element + 1}}, data,
         [{:reply, from, :ok}, {:next_event, :internal, :broadcast_state}]}
    end
  end

  def advance_review_state(from, _, _, _) do
    {:keep_state_and_data, [{:reply, from, {:error, "Not in a reviewing state"}}]}
  end

  @spec put_in_results(%{game: Game.t()}, String.t(), atom(), any()) :: %{game: Game.t()}
  defp put_in_results(data, player, key, value) do
    put_in(
      data,
      [
        Lens.key(:game)
        |> Game.rounds()
        |> Lens.at(0)
        |> Round.results()
        |> Lens.key(player)
        |> Lens.key(key)
      ],
      value
    )
  end

  def submit_correct(
        from,
        {:correct, {player, {_, %Prompt{submitter: submitter}}}},
        %{game: %{players: players}} = data,
        submitting_player,
        correct
      ) do
    cond do
      player != submitting_player ->
        {:keep_state_and_data,
         [{:reply, from, {:error, "You are not the current reviewing player"}}]}

      :else ->
        other_players = Enum.filter(players, &(&1 != player))

        new_data =
          put_in_results(data, player, :correct, correct)
          |> add_to_player_score(submitter, if(correct, do: 3, else: 0))

        {:next_state, {:vote, {player, other_players}}, new_data,
         [
           {:reply, from, :ok},
           {:next_event, :internal, :broadcast_state},
           {:next_event, :internal, :broadcast_players}
         ]}
    end
  end

  def submit_correct(from, _, _, _, _) do
    {:keep_state_and_data, [{:reply, from, {:error, "Can't submit corrections at this time"}}]}
  end

  defp finish_game_or_new_round(from, %{game: game} = data) do
    game_max_score = Map.values(game.scores) |> Enum.max()
    max_score_reached = game.options.max_score != nil and game_max_score >= game.options.max_score
    num_rounds = length(game.rounds)
    round_limit_reached = game.options.max_rounds != nil and num_rounds >= game.options.max_rounds

    reply = [
      {:reply, from, :ok},
      {:next_event, :internal, :broadcast_state},
      {:next_event, :internal, :broadcast_players}
    ]

    if max_score_reached or round_limit_reached do
      {:next_state, :end, data, reply}
    else
      new_data =
        data
        |> put_in([:players_left], nil)
        |> update_in([Lens.key(:game)], &Game.new_round/1)

      {:next_state, :submit, new_data, reply}
    end
  end

  def submit_vote(from, {:vote, {player, others}}, data, submitter, vote) do
    cond do
      player != submitter ->
        {:keep_state_and_data, [{:reply, from, {:error, "You are not the current voter"}}]}

      vote not in others ->
        {:keep_state_and_data,
         [{:reply, from, {:error, "The voted for player is not in the available players"}}]}

      :else ->
        new_data =
          put_in_results(data, player, :favourite, vote)
          |> add_to_player_score(submitter, 1)

        players_left = new_data.players_left

        case players_left do
          [] ->
            finish_game_or_new_round(from, new_data)

          [p | ps] ->
            {:next_state, {:review, {p, 0}}, new_data |> put_in([:players_left], ps),
             [
               {:reply, from, :ok},
               {:next_event, :internal, :broadcast_state},
               {:next_event, :internal, :broadcast_players}
             ]}
        end
    end
  end

  def submit_vote(from, _, _, _, _) do
    {:keep_state_and_data, [{:reply, from, {:error, "Cannot submit a vote at the moment"}}]}
  end

  def set_score_limit(from, state, data, limit) when is_number(limit) do
    {:keep_state, put_in(data, [Lens.key(:options) |> Options.max_score()], limit),
     [{:reply, from, {:ok, limit}}]}
  end

  def set_round_limit(from, state, data, limit) when is_number(limit) do
    {:keep_state, put_in(data, [Lens.key(:options) |> Options.max_rounds()], limit),
     [{:reply, from, {:ok, limit}}]}
  end
end
