import AOC
use Bitwise

aoc 2021, 20 do
  def p1, do: parse() |> enhance_image(2) |> count()
  def p2, do: parse() |> enhance_image(50) |> count()

  defp parse_hashes(<<>>, acc), do: acc
  defp parse_hashes(<<?#, tail::bitstring>>, acc), do: parse_hashes(tail, acc ++ [1])
  defp parse_hashes(<<?., tail::bitstring>>, acc), do: parse_hashes(tail, acc ++ [0])

  defp parse_algo() do
    input_string()
    |> String.split("\n\n", trim: true)
    |> Enum.at(0)
    |> parse_hashes([])
    |> Enum.with_index()
    |> Enum.map(fn {val, x} -> {x, val} end)
    |> Map.new()
  end

  defp parse_data() do
    lines =
      input_string()
      |> String.split("\n\n", trim: true)
      |> Enum.at(1)
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_hashes(&1, []))

    {max_x, max_y} = {Enum.count(Enum.at(lines, 0)), Enum.count(lines)}

    data =
      lines
      |> Enum.with_index()
      |> Enum.flat_map(fn {ln, y} ->
        ln
        |> Enum.with_index()
        |> Enum.map(fn {val, x} -> {{x, y}, val} end)
      end)
      |> Map.new()

    {data, {max_x, max_y}}
  end

  defp parse() do
    {parse_algo(), parse_data()}
  end

  defp blankspace_value(algo, i) do
    max = Enum.count(algo) - 1

    case Map.get(algo, 0) do
      0 -> 0
      _ -> Map.get(algo, rem(i + 1, 2) * max)
    end
  end

  defp all_keys({minX, minY}, {maxX, maxY}), do: for(x <- minX..maxX, y <- minY..maxY, do: {x, y})

  defp adjacents({x, y}) do
    for dx <- -1..1, dy <- -1..1, do: {x + dy, y + dx}
  end

  defp filter(xy, algo, map, default) do
    adjacents(xy)
    |> Enum.map(&Map.get(map, &1, default))
    |> Enum.reduce(0, fn i, acc -> i + (acc <<< 1) end)
    |> then(&{xy, Map.get(algo, &1)})
  end

  defp enhance(_, image_map, 0, {_minX, _minY}, {_maxX, _maxY}),
    do: image_map

  defp enhance(algo, image_map, i, {minX, minY}, {maxX, maxY}) do
    print_map(image_map, {minX, minY}, {maxX, maxY})
    # what value will "blanks" have in the infinite space

    # increase the processing range in all directions by 3
    {minXY, maxXY} = {{minX - 3, minY - 3}, {maxX + 3, maxY + 3}}

    # loop thru all values, apply algo changes
    image_map =
      all_keys(minXY, maxXY)
      |> Enum.map(&filter(&1, algo, image_map, blankspace_value(algo, i)))
      |> Map.new()

    enhance(algo, image_map, i - 1, minXY, maxXY)
  end

  defp enhance_image({algo, {image, maxXY}}, i) do
    enhance(algo, image, i, {0, 0}, maxXY)
  end

  defp map_to_char(freq, {x, y}) do
    case Map.fetch(freq, {x, y}) do
      {:ok, 1} -> ['#']
      _ -> ['.']
    end
  end

  defp print_map(m, {minX, minY}, {maxX, maxY}) do
    for y <- minY..maxY, do: IO.puts(minX..maxX |> Enum.map(&map_to_char(m, {&1, y})))
    m
  end

  defp count(image), do: image |> Map.values() |> Enum.sum()
end
