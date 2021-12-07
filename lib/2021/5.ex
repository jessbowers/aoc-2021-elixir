import AOC

aoc 2021, 5 do
  def p1, do: vents() |> horiz_vert_lines() |> overlaps()
  def p2, do: vents() |> hvd_lines() |> overlaps()

  defp read_coordinates(line) do
    line
    |> String.split(" -> ")
    |> Enum.map(fn cs ->
      String.split(cs, ",")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end)
  end

  defp vents() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.map(&read_coordinates/1)
  end

  defp is_horz_or_vertical([{x1, y1}, {x2, y2}]), do: x1 == x2 || y1 == y2

  defp horiz_vert_lines(lines), do: Enum.filter(lines, &is_horz_or_vertical/1)

  defp is_diagonal_45([{x1, y1}, {x2, y2}]), do: abs(x2 - x1) == abs(y2 - y1)

  defp diagonal_lines(lines), do: Enum.filter(lines, &is_diagonal_45/1)

  defp hvd_lines(lines) do
    (horiz_vert_lines(lines) ++ diagonal_lines(lines)) |> Enum.dedup()
  end

  defp add_direction(lines) do
    lines
    |> Enum.map(fn line ->
      [{x1, y1}, {x2, y2}] = line
      steps = Enum.max([abs(x2 - x1), abs(y2 - y1)])
      {line, {div(x2 - x1, steps), div(y2 - y1, steps)}}
    end)
  end

  defp points_on_line({[pt1, pt2], {dx, dy}}) do
    [{_x1, _y1}, {x2, y2}] = [pt1, pt2]
    # IO.puts("add points for #{inspect(pt1)}, #{inspect(pt2)} with delta #{dx}, #{dy}")
    case pt1 do
      {^x2, ^y2} ->
        [pt1]

      {x, y} ->
        nextPt = {x + dx, y + dy}
        # IO.puts("next point: #{inspect(nextPt)}")
        [pt1 | points_on_line({[nextPt, pt2], {dx, dy}})]
    end
  end

  defp map_to_char(freq, {x, y}) do
    case Map.fetch(freq, {x, y}) do
      {:ok, c} -> Integer.to_charlist(c)
      :error -> ['.']
    end
  end

  defp print_map(freq) do
    for y <- 0..9 do
      IO.puts(0..9 |> Enum.map(&map_to_char(freq, {&1, y})))
    end

    freq
  end

  defp overlaps(lines) do
    lines
    |> add_direction()
    |> Enum.map(&points_on_line/1)
    |> List.flatten()
    |> Enum.frequencies()
    |> print_map()
    |> Map.to_list()
    |> Enum.filter(&(elem(&1, 1) >= 2))
    |> Enum.count()
  end
end
