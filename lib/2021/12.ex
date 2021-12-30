import AOC

aoc 2021, 12 do
  def p1, do: input_string() |> parse() |> all_paths() |> Enum.count()
  # def p2, do: input_string() |> parse()

  defp parse(input) do
    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.map(&List.to_tuple/1)
  end

  defp edge_map(input) do
    input
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.concat(input)
    |> Enum.group_by(&elem(&1, 0))
    |> Map.map(fn {_k, lst} -> lst |> Enum.map(&elem(&1, 1)) end)

    # |> Map.reject(fn {k, _} -> k == "end" end)
  end

  defp pop_lowercase(map, key) do
    if String.downcase(key) == key do
      Map.delete(map, key)
    else
      map
    end
  end

  defp explore_node("end", _, parents), do: {:list, ["end" | parents] |> Enum.reverse()}

  defp explore_node(name, map, parents) do
    map
    |> Map.get(name, [])
    |> Enum.map(&explore_node(&1, pop_lowercase(map, name), [name | parents]))
    |> List.flatten()
  end

  defp all_paths(input) do
    explore_node("start", edge_map(input), [])
    |> Enum.map(&elem(&1, 1))
  end
end
