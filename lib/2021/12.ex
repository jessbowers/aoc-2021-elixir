import AOC

aoc 2021, 12 do
  def p1, do: input_string() |> parse() |> edge_map() |> once_paths() |> Enum.count()
  def p2, do: input_string() |> parse() |> edge_map() |> twice_paths() |> Enum.count()

  # create a list of edges
  defp parse(input) do
    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.map(&List.to_tuple/1)
  end

  # create a map of rooms : {name, max, next}
  #    where next is a connecting room
  #    max is the max # times a room can be visited
  defp edge_map(edges) do
    edges
    # duplicate the other way round
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.concat(edges)
    |> Enum.group_by(&elem(&1, 0))
    # list of just keys
    |> Map.map(fn {_k, lst} -> lst |> Enum.map(&elem(&1, 1)) end)
    |> Map.map(fn {k, lst} -> %{name: k, next: lst} end)
    |> Map.map(&put_visit_max/1)
  end

  # update the max visits in a room, based on case
  defp put_visit_max({key, room}) do
    if String.downcase(key) == key do
      Map.put(room, :max, 1)
    else
      Map.put(room, :max, 99)
    end
  end

  # increment the max visits allowed for a room
  defp increment_room(map, key), do: modify_room(map, key, &(&1 + 1))

  # decrement the max visits allowed for a room
  defp decrement_room(map, key), do: modify_room(map, key, &(&1 - 1))

  defp modify_room(map, key, mod_fn) do
    map
    |> Map.get_and_update(key, fn room ->
      {_, r2} = Map.get_and_update(room, :max, &{&1, mod_fn.(&1)})
      {room, r2}
    end)
    |> then(&elem(&1, 1))
  end

  # explore the end node. So we're done, return the reversed list
  defp explore_node("end", _, parents), do: {:list, ["end" | parents] |> Enum.reverse()}

  # explore every other node, recursively exploring next nodes
  defp explore_node(name, map, parents) do
    case Map.get(map, name, %{next: []}) do
      # no more visits allowed.
      %{max: max} when max <= 0 ->
        # empty return, since we are not the end node
        # will be cleaned up by the List.flatten below
        []

      # normal room
      room ->
        # recursively explore next rooms with a decremented max for this room
        # and an updated parents list
        room.next
        |> Enum.map(&explore_node(&1, decrement_room(map, name), [name | parents]))
        |> List.flatten()
    end
  end

  # Find runs using the given edge_map
  defp once_paths(map) do
    explore_node("start", map, [])
    |> Enum.map(&Enum.join(elem(&1, 1), ","))
    |> MapSet.new()
  end

  # Find all room keys with max of 1
  defp find_single_room_keys(map) do
    map
    |> Enum.filter(fn {_k, v} -> v.max == 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.reject(&(&1 == "start" || &1 == "end"))
  end

  # Find runs where there are 1 lower-case room in each run that can have 2 max
  defp twice_paths(map) do
    map
    |> find_single_room_keys()
    |> Enum.map(&increment_room(map, &1))
    |> Enum.map(&once_paths/1)
    # union all runs with the original all-1-max map
    |> Enum.reduce(once_paths(map), &MapSet.union/2)
  end
end
