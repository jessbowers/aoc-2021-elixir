import AOC

aoc 2021, 22 do
  def p1, do: parse() |> reboot(50)
  def p2, do: parse() |> reboot(0xFFFFFFFFFFFFFFFF)

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.map(fn ln ->
      Regex.run(~r/(\w+) x=([-\d]+)..([-\d]+),y=([-\d]+)..([-\d]+),z=([-\d]+)..([-\d]+)/, ln)
    end)
    |> Enum.map(fn [_, i, x1, x2, y1, y2, z1, z2] -> {i, [x1, x2, y1, y2, z1, z2]} end)
    |> Enum.map(fn {i, xyz} -> {i, xyz |> Enum.map(&String.to_integer/1)} end)
    |> Enum.map(fn
      {"on", xyz} -> {true, xyz}
      {"off", xyz} -> {false, xyz}
    end)
  end

  defp is_within([x1, x2, y1, y2, z1, z2], dx) do
    x1 >= -dx && x2 <= dx && (y1 >= -dx && y2 <= dx) && (z1 >= -dx && z2 <= dx)
  end

  defp reboot(commands, max) do
    core = MapSet.new()

    commands
    |> Enum.filter(fn {_, xyz} -> is_within(xyz, max) end)
    |> Enum.flat_map(fn {i, [x1, x2, y1, y2, z1, z2]} ->
      for x <- x1..x2, y <- y1..y2, z <- z1..z2, do: {i, {x, y, z}}
    end)
    |> Enum.reduce(core, fn
      {true, xyz}, m -> m |> MapSet.put(xyz)
      {false, xyz}, m -> m |> MapSet.delete(xyz)
    end)
    |> Enum.count()
  end
end
