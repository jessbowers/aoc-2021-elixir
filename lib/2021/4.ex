import AOC

aoc 2021, 4 do
  def p1 do
    {boards(), moves()} |> find(&first_winner/3) |> solve()
  end

  def p2 do
    {boards(), moves()} |> find(&last_winner/3) |> solve()
  end

  def moves do
    input_string()
    |> String.split("\n\n")
    |> Enum.at(0)
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  def boards do
    input_string()
    |> String.split("\n\n")
    |> Enum.drop(1)
    |> Enum.map(fn i ->
      i
      |> String.split("\n", trim: true)
      |> Enum.map(fn j ->
        j
        |> String.split(" ", trim: true)
        |> Enum.map(&String.to_integer/1)
      end)
    end)
  end

  def find({boards, moves}, search_fn) do
    boards = Enum.map(boards, &{board_to_rows_cols(&1), &1})
    {{_, board}, nums} = search_fn.(boards, [], moves)
    {board, nums}
  end

  def board_to_rows_cols(b) do
    b ++ (Enum.zip(b) |> Enum.map(&Tuple.to_list/1))
  end

  def find_winning_board(boards, nums), do: Enum.find(boards, &is_solved(&1, nums))

  def first_winner(boards, nums, [rem_hd | rem_tail]) do
    if board = find_winning_board(boards, nums) do
      {board, nums}
    else
      first_winner(boards, [rem_hd | nums], rem_tail)
    end
  end

  def last_winner([board], nums, rem), do: first_winner([board], nums, rem)

  def last_winner(boards, nums, [rem_hd | rem_tail]) do
    if board = find_winning_board(boards, nums) do
      last_winner(List.delete(boards, board), nums, [rem_hd | rem_tail])
    else
      last_winner(boards, [rem_hd | nums], rem_tail)
    end
  end

  def is_solved({rows_cols, _board}, nums) do
    Enum.any?(rows_cols, fn rc -> Enum.all?(rc, fn i -> Enum.member?(nums, i) end) end)
  end

  def solve({board, nums}) do
    sum =
      board
      |> Enum.concat()
      |> Enum.reject(&(&1 in nums))
      |> Enum.sum()

    sum * List.first(nums)
  end
end
