import AOC
use Bitwise

aoc 2021, 16 do
  def p1, do: parse() |> parse_packets() |> score()
  def p2, do: parse() |> parse_packets() |> apply_operators()

  defp parse() do
    input_string()
    |> String.split("\n", trim: true)
    |> Enum.at(0)
    |> Base.decode16!()
  end

  # Parse a number packet
  defp number(v, <<1::size(1), word::size(4), tail::bitstring>>, value) do
    number(v, tail, (value <<< 4) + word)
  end

  # 0 indicates end of number packets
  defp number(v, <<0::size(1), word::size(4), tail::bitstring>>, value) do
    [{v, :number, (value <<< 4) + word} | packet(tail)]
  end

  # literal number
  defp packet(<<vers::size(3), 4::size(3), tail::bitstring>>) do
    # IO.puts("version #{vers} number")
    number(vers, tail, 0)
  end

  # Parse an operator with 16 bits
  defp packet(<<vers::size(3), t::size(3), 0::size(1), subpack_size::size(15), tail::bitstring>>) do
    <<sub_bits::bitstring-size(subpack_size), tail::bitstring>> = tail
    [{vers, :operator, t, packet(sub_bits)} | packet(tail)]
  end

  # Parse an operator with 12 bits
  defp packet(<<vers::size(3), t::size(3), 1::size(1), subpack_count::size(11), tail::bitstring>>) do
    {subpackets, tailpackets} = packet(tail) |> Enum.split(subpack_count)
    [{vers, :operator, t, subpackets} | tailpackets]
  end

  # parsing end state
  defp packet(<<>>), do: []
  defp packet(<<_::bits>>), do: []

  # parse all packets in the input
  defp parse_packets(binary) do
    packet(binary)
  end

  # Sum up all the versions
  defp score([]), do: 0
  defp score([{v, :number, _} | tail]), do: v + score(tail)
  defp score([{v, :operator, _, sub} | tail]), do: v + score(sub) + score(tail)

  # evaluate a compare term with a compare function
  defp eval_cmp_term(p, cmp_fn) do
    p
    |> Enum.map(&eval_term/1)
    |> then(fn [a, b] ->
      if cmp_fn.(a, b) do
        1
      else
        0
      end
    end)
  end

  # number
  defp eval_term({_, :number, n}), do: n

  # sum operator
  defp eval_term({_, :operator, 0, p}),
    do: p |> Enum.map(&eval_term/1) |> Enum.sum()

  # product
  defp eval_term({_, :operator, 1, p}),
    do: p |> Enum.map(&eval_term/1) |> Enum.reduce(1, &*/2)

  # min
  defp eval_term({_, :operator, 2, p}),
    do: p |> Enum.map(&eval_term/1) |> Enum.min()

  # max
  defp eval_term({_, :operator, 3, p}),
    do: p |> Enum.map(&eval_term/1) |> Enum.max()

  # gt
  defp eval_term({_, :operator, 5, p}),
    do: eval_cmp_term(p, &>/2)

  # lt
  defp eval_term({_, :operator, 6, p}),
    do: eval_cmp_term(p, &</2)

  # eq
  defp eval_term({_, :operator, 7, p}),
    do: eval_cmp_term(p, &==/2)

  # evaluate & apply all the operators in the packets
  defp apply_operators([]), do: 0
  defp apply_operators([head | tail]), do: eval_term(head) + apply_operators(tail)
end
