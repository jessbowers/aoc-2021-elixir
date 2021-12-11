import AOC

aoc 2021, 10 do
  def p1, do: input_string() |> parse() |> find_bad_syntax() |> score1()
  def p2, do: input_string() |> parse() |> find_incomplete() |> score2()

  defp parse(input) do
    input
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&String.graphemes/1)
    |> Enum.map(&parse_syntax/1)
  end

  defp open_to_close_map(),
    do: Map.new(Enum.zip(String.graphemes("([{<"), String.graphemes(")]}>")))

  # parse the syntax symbol by symbol
  defp reduce_syntax(symbols, closes, m, idx) do
    case {symbols, closes} do
      {[], []} ->
        {:ok}

      # open char
      {[s | tail], _} when is_map_key(m, s) ->
        reduce_syntax(tail, [Map.get(m, s) | closes], m, idx + 1)

      # close char
      {[s | tail], [c | ctail]} when s == c ->
        reduce_syntax(tail, ctail, m, idx + 1)

      # syntax err
      {[s | _], [c | _]} ->
        {:error_syntax, idx, s, c}

      # missing closures error
      {[], closes} ->
        {:error_incomplete, idx, closes}
    end
  end

  # parse a line of the syntax
  defp parse_syntax(line) do
    case reduce_syntax(line, [], open_to_close_map(), 0) do
      {:ok} ->
        {:ok, line}

      {:error_syntax, idx, actual, expect} ->
        {:error_syntax, Enum.join(line), idx, actual, expect}

      {:error_incomplete, idx, closes} ->
        {:error_incomplete, Enum.join(line), idx, closes}
    end
  end

  defp find_bad_syntax(lines) do
    lines
    |> Enum.filter(&(elem(&1, 0) == :error_syntax))
    |> Enum.map(fn {:error_syntax, _, _, actual, _} -> actual end)
  end

  defp find_incomplete(lines) do
    lines
    |> Enum.filter(&(elem(&1, 0) == :error_incomplete))
    |> Enum.map(fn {:error_incomplete, _, _, closes} -> closes end)
  end

  defp score1(strs) do
    # map of scoring values, by close tag
    m = Map.new([{")", 3}, {"]", 57}, {"}", 1197}, {">", 25137}])

    strs
    |> Enum.map(&Map.get(m, &1, 0))
    |> Enum.sum()
  end

  defp score2(lines) do
    # map of scoring values, by close tag
    m = Map.new([{")", 1}, {"]", 2}, {"}", 3}, {">", 4}])

    scores =
      lines
      |> Enum.map(fn
        ln -> Enum.reduce(ln, 0, &(&2 * 5 + Map.get(m, &1, 0)))
      end)
      |> Enum.sort()

    # find the median score
    scores |> Enum.at(div(Enum.count(scores), 2))
  end
end
