import AOC

aoc 2021, 21 do
  def p1, do: parse() |> play() |> score()
  # def p2, do: parse() |> enhance_image(50) |> count()

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.map(fn ln ->
      Regex.run(~r/Player (\d) starting position: (\d)/, ln)
      |> then(fn [_, p, s] -> {String.to_integer(p), String.to_integer(s)} end)
    end)
  end

  defp roll(die, 0, acc), do: {die, acc}
  defp roll(die, times, acc), do: roll(rem(die, 100) + 1, times - 1, acc + die)

  defp move({player, pos, score}, die) do
    {die, pos} = roll(die, 3, pos)
    pos = rem(pos - 1, 10) + 1
    {{player, pos, score + pos}, die}
  end

  defp play_to([{_p1, _b1, s1}, {p2, _b2, s2}], _d, count, max) when s1 >= max,
    do: {p2, s2, count}

  defp play_to([{p1, _b1, s1}, {_p2, _b2, s2}], _d, count, max) when s2 >= max,
    do: {p1, s1, count}

  defp play_to([player1, player2], die, rolls, max) do
    {player1, die} = move(player1, die)
    play_to([player2, player1], die, rolls + 3, max)
  end

  defp play(players) do
    players
    |> Enum.map(fn {p, i} -> {p, i, 0} end)
    |> play_to(1, 0, 1000)
  end

  defp score({_p, r, s}), do: r * s
end
