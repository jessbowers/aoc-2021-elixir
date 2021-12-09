import AOC

aoc 2021, 8 do
  def p1 do
    # target digit lengths
    targets = [1, 4, 7, 8] |> Enum.map(&len_of_digit/1) |> MapSet.new()

    # frequencies by digit lengths
    # check key/length against target lengths
    visible_digits()
    |> List.flatten()
    |> Enum.map(&String.length/1)
    |> Enum.frequencies()
    |> Map.filter(&MapSet.member?(targets, elem(&1, 0)))
    |> Enum.map(&elem(&1, 1))
    |> Enum.sum()
  end

  def p2 do
    displays()
    |> Enum.map(&{Enum.at(&1, 1), solve_display_wirings(Enum.at(&1, 0))})
    |> Enum.map(&decode_displays/1)
    |> Enum.sum()
  end

  # the input string as an array of lines
  defp input(), do: input_string() |> String.trim() |> String.split("\n")

  defp parse_wiring(s), do: s |> String.graphemes() |> MapSet.new()

  defp parse_section(s), do: s |> String.split() |> Enum.map(&parse_wiring/1)

  # parse each display line
  defp parse_line(ln), do: ln |> String.split(" | ") |> Enum.map(&parse_section/1)

  # list of all display lines as [wirings, digits]
  defp displays(), do: input() |> Enum.map(&parse_line/1)

  defp visible_digits(),
    do: input() |> Enum.map(fn s -> String.split(s, " | ") |> Enum.at(1) |> String.split(" ") end)

  defp len_of_digit(digit) do
    case digit do
      0 -> 6
      1 -> 2
      2 -> 5
      3 -> 5
      4 -> 4
      5 -> 5
      6 -> 6
      7 -> 3
      8 -> 7
      9 -> 6
    end
  end

  defp map_of_digit(digit) do
    case digit do
      0 -> MapSet.new(["a", "b", "c", "e", "f", "g"])
      1 -> MapSet.new(["c", "f"])
      2 -> MapSet.new(["a", "c", "d", "e", "g"])
      3 -> MapSet.new(["a", "c", "d", "f", "g"])
      4 -> MapSet.new(["b", "c", "d", "f"])
      5 -> MapSet.new(["a", "b", "d", "f", "g"])
      6 -> MapSet.new(["a", "b", "d", "e", "f", "g"])
      7 -> MapSet.new(["a", "c", "f"])
      8 -> MapSet.new(["a", "b", "c", "d", "e", "f", "g"])
      9 -> MapSet.new(["a", "b", "c", "d", "f", "g"])
    end
  end

  defp is_wiring_digit(wiring, digit), do: MapSet.size(wiring) == len_of_digit(digit)
  defp find_wiring_digit(wirings, digit), do: wirings |> Enum.find(&is_wiring_digit(&1, digit))

  defp delta(digit_map, num1, num2),
    do: MapSet.difference(Map.get(digit_map, num1), Map.get(digit_map, num2))

  defp intersections(list) do
    Enum.reduce(list, nil, fn
      curr, nil -> curr
      curr, prev -> MapSet.intersection(curr, prev)
    end)
  end

  defp solve_display_wirings(wirings) do
    # input is 10 mapSet of wirings
    # solve wiring for a given list of MapSet wiring letters
    # find the chars for the obvious ones

    # 1, 4, 7, 8
    digit_map =
      [1, 4, 7, 8]
      |> Enum.map(&{&1, find_wiring_digit(wirings, &1)})
      |> Map.new()

    # deduction of subsets of letter combos
    # 1 contains C/F
    cf_map = Map.get(digit_map, 1)
    a_map = delta(digit_map, 7, 1)
    bd_map = delta(digit_map, 4, 1)

    # digits with similar lengths
    set_235 =
      wirings
      |> Enum.filter(&is_wiring_digit(&1, 2))
      |> MapSet.new()

    dg_maps =
      set_235
      |> intersections()
      |> MapSet.difference(a_map)

    d_map = MapSet.intersection(bd_map, dg_maps)
    b_map = MapSet.difference(bd_map, d_map)

    # 3, 5, 2 are all the same length; break them out by intersections & looking for unique values
    set_3 =
      set_235
      |> Enum.filter(&(MapSet.intersection(&1, cf_map) |> MapSet.equal?(cf_map)))
      |> Enum.at(0)

    set_5 = set_235 |> Enum.find(&MapSet.subset?(b_map, &1))
    set_2 = set_235 |> MapSet.delete(set_3) |> MapSet.delete(set_5) |> Enum.at(0)

    # 0, 6, 9 digits with same lengths; break them out by finding unique values
    set_069 =
      wirings
      |> Enum.filter(&is_wiring_digit(&1, 0))
      |> MapSet.new()

    set_0 = set_069 |> Enum.find(&(MapSet.subset?(d_map, &1) != true))
    set_6 = set_069 |> Enum.find(&(MapSet.subset?(cf_map, &1) != true))
    set_9 = set_069 |> MapSet.delete(set_0) |> MapSet.delete(set_6) |> Enum.at(0)

    digit_map
    |> Map.put(0, set_0)
    |> Map.put(2, set_2)
    |> Map.put(3, set_3)
    |> Map.put(5, set_5)
    |> Map.put(6, set_6)
    |> Map.put(9, set_9)
    |> Map.to_list()
  end

  defp decode_displays({segments, digit_map}) do
    segments
    |> Enum.map(fn seg ->
      Enum.find(digit_map, &MapSet.equal?(elem(&1, 1), seg))
      |> elem(0)
    end)
    |> Enum.reduce(0, &(&1 + &2 * 10))
  end
end
