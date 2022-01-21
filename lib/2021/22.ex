import AOC

aoc 2021, 22 do
  def p1, do: parse() |> remove(50) |> reboot_brute_force()
  def p2, do: parse() |> reboot()

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
    |> Enum.map(fn {i, xyz} -> {i, xyz |> Enum.chunk_every(2)} end)
    |> Enum.map(fn
      {"on", xyz} -> {true, xyz}
      {"off", xyz} -> {false, xyz}
    end)
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

  # is xyz1 outside xyz2?
  defp is_outside(xyz1, xyz2) do
    [xyz1, xyz2]
    |> Enum.zip()
    |> Enum.any?(fn {[x1, y1], [x2, y2]} -> y1 <= x2 or x1 >= y2 end)
  end

  # is coord empty?
  defp is_zero(xyz1), do: xyz1 |> Enum.any?(fn [a, b] -> b - a <= 0 end)

  # is xy1 overlapping xy2 lower?
  defp is_over_min([x1, y1], [x2, _y2]), do: x1 < x2 and y1 > x2
  defp is_over_max([x1, y1], [_x2, y2]), do: y1 > y2 and x1 < y2

  # remove items within -max, max
  defp remove(commands, max),
    do: commands |> Enum.filter(fn {_, xyz} -> is_within_dx(xyz, max) end)

  defp reboot_brute_force(commands) do
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

  # check to see if we have overlapping minimum
  defp check_min([], _acc), do: {:bounds, false}

  defp check_min([{xy = [x1, x2], mxy = [mx1, _mx2]} | tail], acc) do
    if is_over_min(xy, mxy) do
      {xy_tail, _mask_tail} = tail |> Enum.unzip()
      {:bounds, acc ++ [[mx1, x2] | xy_tail], acc ++ [[x1, mx1] | xy_tail]}
    else
      check_min(tail, acc ++ [xy])
    end
  end

  # check to see if we have overlapping maximum
  defp check_max([], _acc), do: {:bounds, false}

  defp check_max([{xy = [x1, x2], mxy = [_mx1, mx2]} | tail], acc) do
    if is_over_max(xy, mxy) do
      {xy_tail, _mask_tail} = tail |> Enum.unzip()
      {:bounds, acc ++ [[x1, mx2] | xy_tail], acc ++ [[mx2, x2] | xy_tail]}
    else
      check_max(tail, acc ++ [xy])
    end
  end

  # mask xyz cube, splitting into 0 or many parts
  #  non-overlapping cubes will be left alone, fully overlapping will be deleted
  #  and partial overlaps will be split into many parts
  def mask(xyz, mask_xyz, acc) do
    xyz_mask_xyz = [xyz, mask_xyz] |> Enum.zip()

    with {:outside, false} <- {:outside, is_outside(xyz, mask_xyz)},
         {:inside, false} <- {:inside, is_inside(xyz, mask_xyz)},
         {:zero, false} <- {:zero, is_zero(xyz)},
         {:bounds, false} <- check_min(xyz_mask_xyz, []),
         {:bounds, false} <- check_max(xyz_mask_xyz, []) do
      # this condition should not happen
      IO.puts("ERROR - fell thru with statement on: #{inspect(xyz)}")
      []
    else
      {:inside, true} ->
        # skip
        acc

      {:outside, true} ->
        # keep
        [xyz | acc]

      {:bounds, rem_xyz, masked_xyz} ->
        # out of bounds, so split up. "good" portion gets added to the accumulator
        # un-checked portion gets recursed back thru mask()
        mask(rem_xyz, mask_xyz, [masked_xyz | acc])

      {:zero, true} ->
        acc
    end
  end

  # mask a list of regions with the mask
  # this has the effect of removing any points that overlap with the mask, so that
  # there are no duplicate points
  defp mask_regions(regions, mask_xyz),
    do: regions |> Enum.reduce([], fn xyz, acc -> mask(xyz, mask_xyz, acc) end)

  # final state for execute, return the on regions
  defp execute([], regions), do: regions

  # execute cmd
  #   for every command, apply the on/off first by masking all existing cubes
  #   keeping only points that do not overlap with the current cube
  #   then add the current cube to the regions list if it's "on".
  #   because if it's off, we've just cleared the blocks for it. ie keep only "on" points.
  defp execute([{is_on, xyz} | cmd_tail], regions) do
    case {is_on, mask_regions(regions, xyz)} do
      {true, masked} -> execute(cmd_tail, [xyz | masked])
      {false, masked} -> execute(cmd_tail, masked)
    end
  end

  # given a list of cubes, count the total points.
  defp count_points(zones) do
    zones
    |> Enum.map(fn xyz -> xyz |> Enum.map(fn [x, y] -> y - x end) |> Enum.product() end)
    |> Enum.sum()
  end

  # reboot the system
  defp reboot(commands) do
    commands
    |> Enum.map(fn {i, xyz} -> {i, Enum.map(xyz, fn [a, b] -> [a, b + 1] end)} end)
    |> execute([])
    |> count_points()
  end
end
