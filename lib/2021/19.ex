import AOC

aoc 2021, 19 do
  def p1, do: parse() |> solve() |> then(&Enum.count(elem(&1, 0)))
  def p2, do: parse() |> solve() |> max_scanner_distance()
  # def p2, do: parse() |> add_all()

  # parse a line containing x,y,z
  defp parse_point(p),
    do:
      p
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

  # parse a section containing scanner data
  defp parse_scanner(lines) do
    lines
    |> String.split("\n", trim: true)
    # drop header
    |> Enum.drop(1)
    |> Enum.map(&parse_point/1)
  end

  defp parse() do
    input_string()
    |> String.split("\n\n", trim: true)
    |> Enum.map(&parse_scanner/1)
  end

  defp rotations() do
    [
      fn {x, y, z} -> {x, y, z} end,
      fn {x, y, z} -> {y, z, x} end,
      fn {x, y, z} -> {z, x, y} end,
      fn {x, y, z} -> {-x, z, y} end,
      fn {x, y, z} -> {z, y, -x} end,
      fn {x, y, z} -> {y, -x, z} end,
      fn {x, y, z} -> {x, z, -y} end,
      fn {x, y, z} -> {z, -y, x} end,
      fn {x, y, z} -> {-y, x, z} end,
      fn {x, y, z} -> {x, -z, y} end,
      fn {x, y, z} -> {-z, y, x} end,
      fn {x, y, z} -> {y, x, -z} end,
      fn {x, y, z} -> {-x, -y, z} end,
      fn {x, y, z} -> {-y, z, -x} end,
      fn {x, y, z} -> {z, -x, -y} end,
      fn {x, y, z} -> {-x, y, -z} end,
      fn {x, y, z} -> {y, -z, -x} end,
      fn {x, y, z} -> {-z, -x, y} end,
      fn {x, y, z} -> {x, -y, -z} end,
      fn {x, y, z} -> {-y, -z, x} end,
      fn {x, y, z} -> {-z, x, -y} end,
      fn {x, y, z} -> {-x, -z, -y} end,
      fn {x, y, z} -> {-z, -y, -x} end,
      fn {x, y, z} -> {-y, -x, -z} end
    ]
  end

  ########### K-D tree

  # create a 3d k-d tree
  defp kdtree([pt], _depth), do: {:leaf, pt}

  defp kdtree(points, depth) do
    idx = dim_index(depth)

    points
    |> Enum.sort_by(&elem(&1, idx))
    |> Enum.split(div(length(points), 2))
    |> then(fn {low, [mid | high]} ->
      left = kdtree(low, depth + 1)
      right = kdtree([mid | high], depth + 1)
      mid = {elem(mid, idx), idx}
      {:fork, mid, left, right}
    end)
  end

  # every level uses alternating split dimension index: x,y,z
  defp dim_index(depth), do: rem(depth, 3)

  # euclidian distance between two points
  # note to save cycles don't find sq. root
  # absolute distane (always positive)
  defp delta({x1, y1, z1}, {x2, y2, z2}),
    do: (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2

  # return the closer point to the target
  defp closer(pt1, [], target), do: [{pt1, delta(target, pt1)}]

  defp closer(pt1, [{pt2, dx2} | tail], target) do
    case {delta(target, pt1), dx2} do
      {d1, d2} when d1 <= d2 ->
        [{pt1, d1}, {pt2, dx2}]

      _ ->
        [{pt2, dx2} | closer(pt1, tail, target)] |> Enum.take(2)
    end
  end

  ## Find Nearest Points

  # consider the current index, recurse left & right
  # on the way back up, consider dist < on the current idx and recurse down
  defp nearest({:leaf, pt}, target, cst) when pt == target, do: cst
  defp nearest({:leaf, pt}, target, cst), do: closer(pt, cst, target)

  defp nearest({:fork, {mid, idx}, left, right}, target, cst) when elem(target, idx) < mid,
    do: nearest_fork({{mid, idx}, left, right}, target, cst)

  defp nearest({:fork, {mid, idx}, left, right}, target, cst) when elem(target, idx) >= mid,
    do: nearest_fork({{mid, idx}, right, left}, target, cst)

  defp nearest_fork({{mid, idx}, first, second}, target, closests) do
    # what is the delta from target -> mid value on this dimension?
    target_val = elem(target, idx)
    mid_dx = abs(target_val - mid)

    case nearest(first, target, closests) do
      [hd, sec] when abs(target_val - elem(elem(sec, 0), idx)) >= mid_dx ->
        # if 1st, 2nd are both farther away than the mid_dx, look on the other branch
        # this won't catch every nearest point, but should catch 90% of them & be faster
        second |> nearest(target, [hd, sec])

      [hd, sec] ->
        # normal case, only two elements, not closer to mid, just return
        [hd, sec]

      cst ->
        # all other cases, go ahead and search 2nd branch
        second |> nearest(target, cst)
    end
  end

  # only take the top two nearest points
  defp reduce_near_pts(ns), do: ns |> Enum.take(2) |> Enum.map(&elem(&1, 1)) |> List.to_tuple()

  # build a list of nearest
  defp all_nearest({tree, scan}) do
    scan
    |> Enum.map(&{nearest(tree, &1, []), &1})
    |> Enum.map(fn {ns, pt} -> {reduce_near_pts(ns), pt} end)
  end

  ## Common Points

  # find all common points between two scanners
  defp common_points({nears1, nears2}) do
    (nears1 ++ nears2)
    |> Enum.frequencies_by(&elem(&1, 0))
    # filter only values found in both
    |> Enum.filter(fn {_, f} -> f >= 2 end)
    # populate the list with just the two points, one from each scanner
    |> Enum.map(fn {dx, _} -> {List.keyfind(nears1, dx, 0), List.keyfind(nears2, dx, 0)} end)
    |> Enum.flat_map(fn
      {{_dx, pt1}, {_, pt2}} -> [{pt1, pt2}]
      {nil, _} -> []
      {_, nil} -> []
    end)
  end

  # brute force solve rotation for a given set of common pts
  defp solve_rotation(_common_pts, []), do: nil

  defp solve_rotation(common_pts, [rot | tail]) do
    rot_pts =
      common_pts
      |> Enum.map(fn {pt1, pt2} -> {pt1, rot.(pt2)} end)

    deltas =
      rot_pts
      |> Enum.map(fn {pt1, pt2} -> delta(pt1, pt2) end)
      |> Enum.frequencies()
      |> Map.keys()

    case length(deltas) do
      1 ->
        rot_pts
        |> Enum.at(0)
        |> then(fn {{x1, y1, z1}, {x2, y2, z2}} -> {rot, {x1 - x2, y1 - y2, z1 - z2}} end)

      _ ->
        solve_rotation(common_pts, tail)
    end
  end

  # given set of points, rotate & transform
  defp transform_points(pts, {rot, {dx, dy, dz}}) do
    pts
    |> Enum.map(fn {d, pt} -> {d, rot.(pt)} end)
    |> Enum.map(fn {d, {x, y, z}} -> {d, {x + dx, y + dy, z + dz}} end)
  end

  # find all the common points from the scanner at head to the base (accumulator)
  # then determine rotation / translation, apply to all points & add to the base
  defp find_commons([], base, scanners), do: {base, scanners}

  defp find_commons([head | tail], base, scanners) do
    with {:common, pts} when length(pts) > 10 <- {:common, common_points({base, head})} do
      rot_dx =
        pts
        |> solve_rotation(rotations())

      base =
        head
        |> transform_points(rot_dx)
        |> Enum.concat(base)
        |> Enum.uniq()

      scanner =
        [{0, {0, 0, 0}}] |> transform_points(rot_dx) |> Enum.map(&elem(&1, 1)) |> Enum.at(0)

      find_commons(tail, base, [scanner | scanners])
    else
      {:common, _} ->
        find_commons(tail ++ [head], base, scanners)
    end
  end

  # take the original scan[0] try adding each of the other scans to it
  defp fit_scans(scans) do
    # use the first scanner as the base
    # for all the others, find the next one with overlap
    # determine the translation and then add it to the accumulator
    [base | tail] = scans
    find_commons(tail, base, [{0, 0, 0}])
  end

  defp solve(scans) do
    scans
    # create kdtrees
    |> Enum.map(&{kdtree(&1, 0), &1})
    # find top two nearest points
    |> Enum.map(&all_nearest/1)
    # fit the scans into a single field
    |> fit_scans()
  end

  # alt distance (manhattan method) between two points (for pt 2)
  defp manhattan({x1, y1, z1}, {x2, y2, z2}), do: abs(x1 - x2) + abs(y1 - y2) + abs(z1 - z2)

  # given list of scanners, what's the max distance between them
  defp max_scanner_distance({_, scanners}) do
    distances =
      for x <- scanners,
          y <- scanners,
          x != y do
        manhattan(x, y)
      end

    distances |> Enum.max()
  end
end
