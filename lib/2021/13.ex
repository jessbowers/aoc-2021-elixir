import AOC

aoc 2021, 13 do
  def p1, do: parse() |> fold_first() |> Enum.count()
  def p2, do: parse() |> fold_all() |> print_board()

  defp parse_coords(ln) do
    ln |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1) |> List.to_tuple()
  end

  defp parse_dots() do
    input_string()
    |> String.split("\n\n", trim: true)
    |> Enum.at(0)
    |> String.split("\n")
    |> Enum.map(&parse_coords/1)
    |> MapSet.new()
  end

  defp parse_folds() do
    input_string()
    |> String.split("\n\n", trim: true)
    |> Enum.at(1)
    |> String.split("\n", trim: true)
    |> Enum.map(fn ln ->
      Regex.run(~r/fold along (\w)=(\d+)/, ln)
      |> then(fn [_, axis, val] -> {String.to_atom(axis), String.to_integer(val)} end)
    end)
  end

  defp parse() do
    {parse_dots(), parse_folds()}
  end

  defp fold(dots, []), do: dots

  defp fold(dots, [head | tail]) do
    dots
    |> fold_xy(head)
    |> List.flatten()
    |> MapSet.new()
    |> fold(tail)
  end

  defp fold_xy(dots, {:x, fx}) do
    dots
    |> Enum.map(fn
      {x, y} when x < fx -> {x, y}
      {x, _} when x == fx -> []
      {x, y} when x > fx -> {fx - x + fx, y}
    end)
  end

  defp fold_xy(dots, {:y, fy}) do
    dots
    |> Enum.map(fn
      {x, y} when y < fy -> {x, y}
      {_, y} when y == fy -> []
      {x, y} when y > fy -> {x, fy - y + fy}
    end)
  end

  defp fold_first({dots, [fold | _]}) do
    fold(dots, [fold])
  end

  defp fold_all({dots, folds}) do
    fold(dots, folds)
  end

  defp print_board(dots) do
    max_x = dots |> Enum.map(&elem(&1, 0)) |> Enum.max()
    max_y = dots |> Enum.map(&elem(&1, 1)) |> Enum.max()

    board =
      for y <- 0..max_y do
        for x <- 0..max_x do
          if MapSet.member?(dots, {x, y}) do
            "#"
          else
            "."
          end
        end
      end

    board |> Enum.map(&Enum.join/1)
  end
end
