import AOC

aoc 2021, 7 do
  def p1, do: solve(& &1)
  def p2, do: solve(&crab_burn/1)

  defp solve(burn_fn) do
    crabs = start_positions()
    {min, max} = Enum.min_max(crabs)

    min..max
    |> Enum.map(&measure_fuel(crabs, &1, burn_fn))
    |> Enum.sort()
    |> Enum.at(0)
  end

  defp start_positions(),
    do: input_string() |> String.trim() |> String.split(",") |> Enum.map(&String.to_integer/1)

  defp measure_fuel(pos, target, burn_fn),
    do: pos |> Enum.map(&abs(target - &1)) |> Enum.map(burn_fn) |> Enum.sum()

  defp crab_burn(n), do: div(n * (n + 1), 2)
end
