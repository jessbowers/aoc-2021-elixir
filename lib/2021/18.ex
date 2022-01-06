import AOC

aoc 2021, 18 do
  def p1, do: parse() |> Enum.reduce(&add(&2, &1)) |> IO.inspect() |> magnitude()
  # def p2, do: parse() |> find_all_velocities() |> Enum.count()

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line(&1, []))
  end

  # parsing end state
  defp parse_line(<<>>, [stack]), do: stack

  # parsing, open brace
  defp parse_line(<<?[, tail::bytes>>, stack), do: parse_line(tail, stack)

  # parsing, number
  defp parse_line(<<n, tail::bytes>>, stack) when n >= ?0 and n <= ?9,
    do: parse_line(tail, [n - 48 | stack])

  # ignore comma
  defp parse_line(<<?,, tail::bytes>>, stack), do: parse_line(tail, stack)

  # closing brace
  defp parse_line(<<?], tail::bytes>>, [s1, s2 | stack]), do: parse_line(tail, [[s2, s1] | stack])

  # Addition
  # add just combines the two elements into a new pair
  # reduction is necessary
  defp add(l, r), do: [l, r] |> reduce()

  # reduction, taking into account explosions and splits rules
  defp reduce(terms) do
    with pair when is_list(pair) <- explode(terms, 0),
         pair when not is_tuple(pair) <- split(terms) do
      pair
    else
      {:explode, pair, _, _} ->
        pair |> reduce()

      {:split, pair} ->
        pair |> reduce()
    end
  end

  # check for explode case and handle it
  defp explode([a, b], depth) when is_integer(a) and is_integer(b) and depth >= 4,
    do: {:explode, 0, a, b}

  defp explode(a, _depth) when is_integer(a), do: a

  defp explode([l, r], depth) do
    with {:l, l} when not is_tuple(l) <- {:l, explode(l, depth + 1)},
         {:r, r} when not is_tuple(r) <- {:r, explode(r, depth + 1)} do
      [l, r]
    else
      # initial result from an explode, converts to 0
      {:l, {:explode, 0, dl, dr}} ->
        {r, dr} = accumulate(:l, r, dr)
        {:explode, [0, r], dl, dr}

      # initial result from an explode, converts to 0
      {:r, {:explode, 0, dl, dr}} ->
        {l, dl} = accumulate(:r, l, dl)
        {:explode, [l, 0], dl, dr}

      # final result from explode with no more adds
      {:l, {:explode, pair, 0, 0}} ->
        {:explode, [pair, r], 0, 0}

      # final result from explode with no more adds
      {:r, {:explode, pair, 0, 0}} ->
        {:explode, [l, pair], 0, 0}

      # left explode
      {:l, {:explode, pair, dl, dr}} ->
        {r, dr} = accumulate(:l, r, dr)
        {:explode, [pair, r], dl, dr}

      {:r, {:explode, pair, dl, dr}} ->
        {l, dl} = accumulate(:r, l, dl)
        {:explode, [l, pair], dl, dr}
    end
  end

  # add the appropriate item to the appropriate side of the pair
  defp accumulate(_, x, dx) when is_integer(x), do: {x + dx, 0}

  defp accumulate(:l, [l, r], dx) do
    {l, dx} = accumulate(:l, l, dx)
    {[l, r], dx}
  end

  defp accumulate(:r, [l, r], dx) do
    {r, dx} = accumulate(:r, r, dx)
    {[l, r], dx}
  end

  # check for split condition
  defp split(a) when is_integer(a) and a >= 10, do: {:split, [div(a, 2), ceil(a / 2)]}
  defp split(a) when is_integer(a), do: a

  defp split([l, r]) do
    with {:l, a} when not is_tuple(a) <- {:l, split(l)},
         {:r, b} when not is_tuple(b) <- {:r, split(r)} do
      [a, b]
    else
      {:l, {:split, a}} -> {:split, [a, r]}
      {:r, {:split, b}} -> {:split, [l, b]}
    end
  end

  defp magnitude(a) when is_integer(a), do: a
  defp magnitude([a, b]) when is_integer(a) and is_integer(b), do: 3 * a + 2 * b

  defp magnitude([a, b]) do
    with a <- magnitude(a),
         b <- magnitude(b) do
      magnitude([a, b])
    end
  end
end
