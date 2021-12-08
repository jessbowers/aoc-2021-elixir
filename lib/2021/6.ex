import AOC

aoc 2021, 6 do
  def p1, do: lanternfish() |> spawn(80) |> count()
  def p2, do: lanternfish() |> spawn(256) |> count()

  defp lanternfish,
    do:
      input_string()
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_integer/1)
      |> Enum.sort()
      |> Enum.frequencies()

  defp spawn(fish, days) do
    # IO.puts("Day #{days}: #{inspect(fish)}")
    if days > 0 do
      baby_count = Map.get(fish, 0, 0)

      fish =
        fish
        |> Map.delete(0)
        |> Map.to_list()
        |> Enum.map(fn {day, count} -> {day - 1, count} end)
        |> Map.new()
        |> Map.put(8, baby_count)
        |> Map.get_and_update(6, fn
          nil -> {nil, baby_count}
          c -> {c, c + baby_count}
        end)
        |> elem(1)

      spawn(fish, days - 1)
    else
      fish
    end
  end

  defp count(fish) do
    fish |> Map.values() |> Enum.sum()
  end
end
