import AOC

aoc 2021, 15 do
  def p1, do: parse() |> find_shortest_path()
  def p2, do: parse() |> explode_to_25() |> find_shortest_path()

  # parse a line into {x,y, val}
  defp parse_line_xy(line, y) do
    line
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(fn i, x -> {{x, y}, {{x, y}, i}} end)
  end

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.with_index(&parse_line_xy/2)
    |> List.flatten()
    |> Map.new()
  end

  # assuming a consistent length of rows, return max cols, rows
  defp max_xy(map), do: map |> Enum.max_by(&elem(&1, 0)) |> then(&elem(&1, 0))

  # return adjacent cells in map
  defp adjacents_to(map, {x, y}) do
    [{-1, 0}, {0, -1}, {1, 0}, {0, 1}]
    |> Enum.map(fn {dx, dy} -> {dx + x, dy + y} end)
    |> Enum.map(fn k -> Map.get(map, k, nil) end)
    |> Enum.filter(& &1)
  end

  defp member_of_queue?(queue, value) do
    queue
    |> PriorityQueue.to_list()
    |> Enum.filter(fn {_k, v} -> v == value end)
    |> then(fn
      # nothing returned from the filter
      [] -> {:missing}
      [{val, xy}] -> {xy, val}
      _ -> {:error}
    end)
  end

  # priority queue, replaces a value for a given key
  defp replace_in_queue(queue, value, key) do
    queue
    |> PriorityQueue.to_list()
    |> Enum.reject(fn {_k, v} -> v == value end)
    |> Enum.reduce(PriorityQueue.new(), fn {k, v}, acc -> acc |> PriorityQueue.put(k, v) end)
    |> PriorityQueue.put(key, value)
  end

  # Uniform Cost Search
  # Algo based on Dijkstra priority queue optimization https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm#Practical_optimizations_and_infinite_graphs
  defp uniform_cost_search({{curr_risk, curr_xy}, _frontier}, target, _explored, _map)
       when curr_xy == target do
    curr_risk
  end

  defp uniform_cost_search({{curr_risk, curr_xy}, frontier}, target, explored, map) do
    # add curr node to the explored set
    explored = explored |> MapSet.put(curr_xy)

    # update the frontier, looking at the neighbors
    frontier =
      map
      # get list of neighbors that are not explored
      |> adjacents_to(curr_xy)
      |> Enum.reject(fn {xy, _} -> explored |> MapSet.member?(xy) end)
      # add whether this value is in the frontier
      |> Enum.map(fn {xy, val} -> {xy, val, frontier |> member_of_queue?(xy)} end)
      |> Enum.reduce(frontier, fn
        # add those not in the frontier to it
        {xy, val, {:missing}}, acc ->
          acc |> PriorityQueue.put(curr_risk + val, xy)

        # replace any with risk values that are < current risk
        {xy, val, {_, risk}}, acc when curr_risk + val < risk ->
          acc |> replace_in_queue(xy, curr_risk + val)

        # default, risk is greater, etc
        _, acc ->
          acc
      end)

    # explore the next closest node
    uniform_cost_search(PriorityQueue.pop(frontier), target, explored, map)
  end

  defp find_shortest_path(map) do
    source = {0, 0}
    target = max_xy(map)
    frontier = PriorityQueue.new()
    explored = MapSet.new()
    uniform_cost_search({{0, source}, frontier}, target, explored, map)
  end

  # 5x5 grid
  defp grid_25() do
    for y <- 0..4 do
      for x <- 0..4 do
        {x, y}
      end
    end
    |> List.flatten()
  end

  # take the map and duplicate it horizontal & vertical to 25 tiles
  defp explode_to_25(map) do
    {max_x, max_y} = max_xy(map)

    grid_25()
    |> Enum.map(fn {dx, dy} ->
      map
      |> Enum.map(fn {{x, y}, {{_, _}, val}} ->
        # new x,y
        xy2 = {(max_x + 1) * dx + x, (max_y + 1) * dy + y}
        # new map value
        # value is mod 9, 1-9
        {xy2, {xy2, rem(val + dx + dy - 1, 9) + 1}}
      end)
    end)
    |> Enum.concat()
    |> Map.new()
  end
end
