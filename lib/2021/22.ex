import AOC

aoc 2021, 22 do
  def p1, do: parse() |> remove(50) |> reboot()
  # def p2, do: parse() |> reboot()

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.map(fn ln ->
      Regex.run(
        ~r/(\w+) x=([-\d]+)\.\.([-\d]+),y=([-\d]+)\.\.([-\d]+),z=([-\d]+)\.\.([-\d]+)/,
        ln
      )
    end)
    |> Enum.map(fn [_, i, x1, x2, y1, y2, z1, z2] -> {i, [x1, x2, y1, y2, z1, z2]} end)
    |> Enum.map(fn {i, xyz} -> {i, xyz |> Enum.map(&String.to_integer/1)} end)
    |> Enum.map(fn
      {"on", xyz} -> {true, xyz}
      {"off", xyz} -> {false, xyz}
    end)
    |> Enum.map(fn {i, xyz} -> {i, xyz |> Enum.chunk_every(2)} end)
  end

  # is the coord within -dx, dx
  defp is_within_dx(xyz, dx),
    do: xyz |> Enum.all?(fn [a, b] -> a >= -dx && b <= dx end)

  # is xyz1 fully within xyz2?
  defp is_inside(xyz1, xyz2) do
    [xyz1, xyz2]
    |> Enum.zip()
    |> Enum.all?(fn {[x1, y1], [x2, y2]} -> x1 >= x2 and y1 <= y2 end)
  end

  defp is_outside(xyz1, xyz2) do
    [xyz1, xyz2]
    |> Enum.zip()
    |> Enum.any?(fn {[x1, y1], [x2, y2]} -> y1 <= x2 or x1 >= y2 end)
  end

  # remove items within -max, max
  defp remove(commands, max),
    do: commands |> Enum.filter(fn {_, xyz} -> is_within_dx(xyz, max) end)

  defp reboot1(commands) do
    core = MapSet.new()

    commands
    |> Enum.flat_map(fn {i, [[x1, x2], [y1, y2], [z1, z2]]} ->
      for x <- x1..x2, y <- y1..y2, z <- z1..z2, do: {i, {x, y, z}}
    end)
    |> Enum.reduce(core, fn
      {true, xyz}, m -> m |> MapSet.put(xyz)
      {false, xyz}, m -> m |> MapSet.delete(xyz)
    end)
    |> Enum.count()
  end

  # min xyz
  # defp min_xyz(xyz), do: xyz |> Enum.map(fn [a, b] -> min(a, b) end)

  # defp max_xyz(xyz), do: xyz |> Enum.map(fn [a, b] -> max(a, b) end)

  defp deltoid_min([[x1, x2], [y1, y2], [z1, z2]], [[mx1, mx2], [my1, my2], [mz1, mz2]]),
    do: [x2 - mx1, y2 - my1, z2 - mz1]

  defp deltoid_max([[x1, x2], [y1, y2], [z1, z2]], [[mx1, mx2], [my1, my2], [mz1, mz2]]),
    do: [x1 - mx2, y1 - my2, z1 - mz2]

  # mask xyz cube, splitting into 0 or many
  # defp mask(xyz, mask_xyz, acc) -> []
  def mask(xyz, mask_xyz, acc) do
    [[x1, x2], [y1, y2], [z1, z2]] = xyz
    [[mx1, mx2], [my1, my2], [mz1, mz2]] = mask_xyz

    IO.puts("")
    IO.puts("mask\nxyz: #{inspect(xyz)}\nmask_xyz: #{inspect(mask_xyz)} \nacc: #{inspect(acc)}")

    with {:outside, false} <- {:outside, is_outside(xyz, mask_xyz)},
         {:inside, false} <- {:inside, is_inside(xyz, mask_xyz)} do
      IO.puts("deltoids: min/max/inside")
      IO.inspect(deltoid_min(xyz, mask_xyz))
      IO.inspect(deltoid_max(xyz, mask_xyz))

      case {deltoid_min(xyz, mask_xyz), deltoid_max(xyz, mask_xyz), is_inside(xyz, mask_xyz)} do
        # x-min
        {[mx, _, _], [_, _, _], _} when mx > 0 ->
          mask([[mx1, x2], [y1, y2], [z1, z2]], mask_xyz, [
            [[x1, mx1], [y1, y2], [z1, z2]] | acc
          ])

        # x-max
        {[mx, my, mz], [xx, xy, xz], _} when xx < 0 ->
          mask([[x1, mx2], [y1, y2], [z1, z2]], mask_xyz, [
            [[mx2, x2], [y1, y2], [z1, z2]] | acc
          ])

        # y-min
        {[mx, my, mz], [xx, xy, xz], _} when my > 0 ->
          mask([[x1, x2], [my1, y2], [z1, z2]], mask_xyz, [
            [[x1, x2], [y1, my1], [z1, z2]] | acc
          ])

        # y-max
        {[mx, my, mz], [xx, xy, xz], _} when xy < 0 ->
          mask([[x1, x2], [y1, my2], [z1, z2]], mask_xyz, [
            [[x1, x2], [my2, y2], [z1, z2]] | acc
          ])

        # z-min
        {[mx, my, mz], [xx, xy, xz], _} when mz > 0 ->
          mask([[x1, x2], [y1, y2], [mz1, z2]], mask_xyz, [
            [[x1, x2], [y1, y2], [z1, mz1]] | acc
          ])

        # x-max
        {[mx, my, mz], [xx, xy, xz], _} when xz < 0 ->
          mask([[x1, x2], [y1, y2], [z1, mz2]], mask_xyz, [
            [[x1, x2], [y1, y2], [mz2, z2]] | acc
          ])
      end
    else
      {:inside, true} ->
        IO.puts("inside")
        acc

      {:outside, true} ->
        IO.puts("outside")
        [xyz | acc]
    end
  end

  # mask a list of regions with the mask
  defp mask_regions(regions, mask_xyz),
    do: regions |> Enum.reduce([], fn xyz, acc -> mask(xyz, mask_xyz, acc) end)

  # final state for execute, return the on regions
  defp execute([], regions), do: regions

  # execute cmd
  defp execute([{is_on, xyz} | cmd_tail], regions) do
    case {is_on, mask_regions(regions, xyz)} do
      {true, regions} -> execute(cmd_tail, [xyz | regions])
      {false, regions} -> execute(cmd_tail, regions)
    end
  end

  defp reboot(commands) do
    commands
    |> Enum.map(fn {i, xyz} -> {i, Enum.map(xyz, fn [a, b] -> [a, b + 1] end)} end)
    |> Enum.take(3)
    |> IO.inspect()
    |> execute([])
    # |> IO.inspect()
    |> Enum.count()
  end
end
