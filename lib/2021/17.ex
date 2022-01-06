import AOC

aoc 2021, 17 do
  def p1, do: parse() |> find_maxY()
  def p2, do: parse() |> find_all_velocities() |> Enum.count()

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.at(0)
    |> then(&Regex.run(~r/target area: x=(\d+)..(\d+), y=(-?\d+)..(-?\d+)/, &1))
    |> Enum.drop(1)
    |> Enum.map(&String.to_integer/1)
    |> then(fn [x1, x2, y2, y1] -> {{x1, y1}, {x2, y2}} end)
  end

  # calc the sum of numbers 1 - n
  defp triang(n), do: div((n + 1) * n, 2)

  # decal the velocity according to the rules
  defp decay({0, vy}), do: {0, vy - 1}
  defp decay({vx, vy}), do: {vx - 1, vy - 1}

  # is xy in the target area?
  defp in_target({x, y}, {{tx1, ty1}, {tx2, ty2}}),
    do: x >= tx1 && x <= tx2 && y <= ty1 && y >= ty2

  # is xy past the target in either dimension?
  defp missed_target({x, y}, {{_, _}, {tx2, ty2}}),
    do: x > tx2 || y < ty2

  # step the simulation forward one tick
  defp step_sim({x, y}, {vx, vy}, t_area) do
    {x, y} = {x + vx, y + vy}
    {vx, vy} = decay({vx, vy})

    case {in_target({x, y}, t_area), missed_target({x, y}, t_area)} do
      {true, _} ->
        # hit the target
        {:success, %{xy: {x, y}, vx: {vx, vy}}}

      {_, true} ->
        # we are past the target in either dimension
        {:missed, %{xy: {x, y}, vx: {vx, vy}}}

      _ ->
        step_sim({x, y}, {vx, vy}, t_area)
    end
  end

  # simulate with this velocity
  defp velocity(velocity, t_area) do
    step_sim({0, 0}, velocity, t_area)
  end

  # Find the maxY of any of the targets
  # without simulating, the answer is just the triang of the |y velocity min| -1
  defp find_maxY({{_x1, _y1}, {_x2, y2}}), do: triang(-y2 - 1)

  # Find all velocities that hit the target
  defp find_all_velocities(t_area = {{_x1, _y1}, {x2, y2}}) do
    t_area |> IO.inspect()
    # search x where >= 1 and <= the x max
    {min_x, max_x} = {1, x2}
    # search y where >= the max <= min
    # because as we saw with MaxY -y2 value will give the greatest height while still potentially hitting the target
    {min_y, max_y} = {y2, -y2}

    # build array of all xy values
    min_y..max_y
    |> Enum.map(fn y -> min_x..max_x |> Enum.map(&{&1, y}) end)
    |> List.flatten()
    # map them to a velocity simulation
    |> Enum.map(fn vel -> {vel, velocity(vel, t_area)} end)
    # filter out the missed items
    |> Enum.reject(fn
      {_, {:missed, _}} -> true
      {_, {:success, _}} -> false
    end)
  end
end
