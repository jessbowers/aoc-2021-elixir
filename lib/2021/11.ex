import AOC

aoc 2021, 11 do
  def p1, do: input_string() |> parse() |> energy_steps(0, 100) |> score()
  def p2, do: input_string() |> parse() |> find_all_flash()

  # Create a Map of x,y -> val
  defp parse(input) do
    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.flat_map(fn {ln, y} ->
      ln
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.with_index()
      |> Enum.map(fn {val, x} -> {{x, y}, val} end)
    end)
    |> Map.new()

    # |> print_energy()
  end

  defp adj_coords(), do: [{0, 1}, {0, -1}, {1, 0}, {1, -1}, {1, 1}, {-1, -1}, {-1, 0}, {-1, 1}]

  defp find_adjs({x, y}, m) do
    adj_coords()
    |> Enum.map(fn {dx, dy} -> {x + dx, y + dy} end)
    |> Enum.map(fn pt -> {pt, Map.get(m, pt)} end)
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Map.new()
  end

  # increment some of the points in the map
  defp increment_map_points(pts, {flash_count, energy_map}) do
    # IO.puts("increment map points #{inspect(pts)}")
    # Add 1 to all values for pts
    # find values > 9, look for adjacents, add 1 to those, repeat

    pts = pts |> Map.map(fn {_k, v} -> v + 1 end)

    # merge the incremented points into the whole
    energy_map = energy_map |> Map.merge(pts)

    # determine & count the flashes
    flashes = pts |> Enum.filter(fn {_k, v} -> v == 10 end)
    fc = flash_count + Enum.count(flashes)
    # IO.puts("#{Enum.count(flashes)} flashes #{inspect(flashes)}")
    # IO.inspect(flashes)

    # recurse into adjacents for flashes
    flashes
    |> Enum.reduce({fc, energy_map}, fn
      {pt, _v}, {fc, emap} ->
        # IO.puts("adacents for #{inspect(pt)}")
        find_adjs(pt, emap) |> increment_map_points({fc, emap})
    end)
    |> then(fn {fc, emap} ->
      # _ = print_energy(emap)
      {fc, emap}
    end)
  end

  defp energy_steps(map, count, steps) do
    1..steps |> Enum.reduce({0, map}, &do_step/2)
  end

  defp do_step(step, {count, map}) do
    map
    |> increment_map_points({count, map})
    |> then(fn {fc, m} ->
      emap =
        m
        |> Map.map(fn
          {_k, v} when v > 9 ->
            0

          {_k, v} ->
            v
        end)

      {fc, emap}
    end)
    |> then(fn {fc, emap} ->
      IO.puts("step #{step}")
      print_energy(emap)
      {fc, emap}
    end)
  end

  defp score({count, _map}) do
    count
  end

  defp print_energy(emap) do
    emap
    |> Map.to_list()
    |> Enum.sort(fn {{x1, y1}, _v}, {{x2, y2}, _v2} -> y1 < y2 || (y1 == y2 && x1 < x2) end)
    |> Enum.map(fn {_k, v} -> Integer.to_string(v) end)
    |> Enum.chunk_every(10)
    |> Enum.map(&Enum.join/1)
    |> Enum.join("\n")
    |> then(fn m ->
      IO.puts(m)
      emap
    end)
  end

  defp find_all_flash(map) do
    Enum.reduce_while(1..1000, {0, map}, fn
      i, acc ->
        {fc, emap} = do_step(i, acc)
        target = Map.get(emap, {0, 0}, 0)

        if Enum.all?(emap, fn {_k, v} -> v == target end) do
          print_energy(emap)
          {:halt, i}
        else
          {:cont, {fc, emap}}
        end
    end)
  end
end
