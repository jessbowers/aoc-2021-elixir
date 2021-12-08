import AOC

aoc 2021, 6 do
  def p1, do: lanternfish() |> spawn(80) |> Enum.count()
  def p2, do: lanternfish() |> spawn(256) |> Enum.count()

  defp lanternfish,
    do: input_string() |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)

  defp spawn(fish, days) do
    if days > 0 do
      babies = fish |> Enum.filter(&(&1 == 0)) |> Enum.map(&(&1 + 8))

      fish =
        Enum.map(fish, fn
          day when day > 0 -> day - 1
          day when day == 0 -> 6
        end) ++
          babies

      spawn(fish, days - 1)
    else
      fish
    end
  end
end
