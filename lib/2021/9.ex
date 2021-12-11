import AOC

aoc 2021, 9 do
  def p1 do
    input() |> find_points(&lower/2) |> Enum.map(&(elem(&1, 0) + 1)) |> Enum.sum()
  end

  def p2 do
    input()
    |> find_basins()
    |> Enum.map(&Enum.count/1)
    |> Enum.sort(:desc)
    |> Enum.take(3)
    |> Enum.product()
  end

  defp input(),
    do: input_string() |> String.trim() |> String.split("\n") |> Enum.map(&parse_ints/1)

  defp parse_ints(i), do: i |> String.graphemes() |> Enum.map(&String.to_integer/1)

  defp verticals(lst), do: lst |> Enum.zip() |> Enum.map(&Tuple.to_list/1)

  defp find_points(lines, cmp_fn) do
    horiz = lines |> points_on_lines(cmp_fn)
    vert = verticals(lines) |> points_on_lines(cmp_fn) |> Enum.map(&flip_xy/1)
    MapSet.intersection(MapSet.new(horiz), MapSet.new(vert)) |> MapSet.to_list()
  end

  defp points_on_lines(lines, cmp_fn) do
    lines
    |> Enum.with_index()
    |> Enum.map(&points_on_line(&1, cmp_fn))
    |> List.flatten()
  end

  defp points_on_line({line, y}, cmp_fn) do
    [first | tail] = line |> Enum.with_index()

    pol_reducer(nil, first, tail, cmp_fn)
    |> Enum.map(&{elem(&1, 0), {elem(&1, 1), y}})
  end

  # First element special case
  defp pol_reducer(nil, curr, [next | tail], cmp_fn) do
    if cmp_fn.(curr, next) do
      [curr | pol_reducer(curr, next, tail, cmp_fn)]
    else
      pol_reducer(curr, next, tail, cmp_fn)
    end
  end

  # Usual case
  defp pol_reducer(prev, curr, [next | tail], cmp_fn) do
    if cmp_fn.(curr, prev) && cmp_fn.(curr, next) do
      [curr | pol_reducer(curr, next, tail, cmp_fn)]
    else
      pol_reducer(curr, next, tail, cmp_fn)
    end
  end

  # Last case
  defp pol_reducer(prev, curr, [], cmp_fn) do
    if cmp_fn.(curr, prev) do
      [curr]
    else
      []
    end
  end

  defp lower(a, b), do: elem(a, 0) < elem(b, 0)

  defp flip_xy({val, {x, y}}), do: {val, {y, x}}

  defp find_basins(lines) do
    {max_x, max_y} = {Enum.count(Enum.at(lines, 0)), Enum.count(lines)}

    lines
    |> find_points(&lower/2)
    |> Enum.map(&find_all_in_basin(&1, {lines, {max_x, max_y}}))
  end

  defp find_all_in_basin(center, data), do: find_adjacents([center], data, MapSet.new())

  defp adjacent_cells({_, {x, y}}, {lines, {max_x, max_y}}) do
    [{-1, 0}, {0, -1}, {1, 0}, {0, 1}]
    |> Enum.flat_map(fn {dx, dy} ->
      {x2, y2} = {x + dx, y + dy}

      if x2 >= 0 && x2 < max_x && y2 >= 0 && y2 < max_y do
        {cell_val, cell_pt} = {Enum.at(Enum.at(lines, y2), x2), {x2, y2}}

        if cell_val < 9 do
          [{cell_val, cell_pt}]
        else
          []
        end
      else
        []
      end
    end)
  end

  defp find_adjacents(centers, data, acc) do
    case centers do
      [] ->
        acc

      list ->
        new_pts =
          list
          |> Enum.map(&adjacent_cells(&1, data))
          |> List.flatten()
          |> Enum.dedup()
          |> Enum.reject(&MapSet.member?(acc, &1))

        acc = new_pts |> MapSet.new() |> MapSet.union(acc)
        find_adjacents(new_pts, data, acc)
    end
  end
end
