import AOC

aoc 2021, 14 do
  def p1, do: parse() |> solve(10) |> score()
  def p2, do: parse() |> solve(40) |> score()

  defp parse() do
    sections =
      input_string()
      |> String.split("\n\n", trim: true)

    polymer =
      sections
      |> Enum.at(0)
      |> String.graphemes()

    rules =
      sections
      |> Enum.at(1)
      |> String.split("\n", trim: true)
      |> Enum.map(fn str ->
        Regex.run(~r/(\w)(\w) -> (\w)/, str)
        |> then(fn [_, a, b, c] -> {[a, b], c} end)
      end)
      |> Map.new()

    first = polymer |> Enum.at(0)
    last = polymer |> Enum.reverse() |> Enum.at(0)
    end_map = [{first, 2}, {last, 2}] |> Map.new()

    {polymer, rules, end_map}
  end

  # create a frequency map of pairs
  defp frequency_map(polymer) do
    polymer
    |> Enum.chunk_every(2, 1)
    |> Enum.reject(&(length(&1) == 1))
    |> Enum.frequencies()
  end

  defp add_map_value(map, key, count) do
    map
    |> Map.get_and_update(key, fn
      nil -> {nil, count}
      curr -> {curr, curr + count}
    end)
    |> then(&elem(&1, 1))
  end

  defp combine({pairs, _}, 0), do: pairs

  defp combine({pairs, rules}, times) do
    pairs
    |> Enum.map(fn {[a, c], v} -> {a, Map.get(rules, [a, c]), c, v} end)
    |> Enum.flat_map(fn {a, b, c, v} -> [{[a, b], v}, {[b, c], v}] end)
    |> Enum.reduce(Map.new(), fn {k, v}, m -> m |> add_map_value(k, v) end)
    |> then(&combine({&1, rules}, times - 1))
  end

  defp pairs_to_singles(pairs, end_map) do
    pairs
    |> Enum.reduce(end_map, fn {[a, b], v}, m ->
      m
      |> add_map_value(a, v)
      |> add_map_value(b, v)
    end)
    |> Map.map(fn {_, v} -> div(v, 2) end)
  end

  defp solve({polymer, rules, end_map}, steps) do
    combine({frequency_map(polymer), rules}, steps)
    |> pairs_to_singles(end_map)
  end

  defp score(pairs) do
    pairs
    |> Enum.min_max_by(&elem(&1, 1))
    |> then(fn {{_, min}, {_, max}} -> max - min end)
  end
end
