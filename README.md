# ElixirAoc2021

Advent of Code 2021 in Elixir!

## Installation

    mix deps.get

    # in config/config.exs

    import Config

    config :advent_of_code_utils,
    session:
        "... cookie goes here ... "

    config :advent_of_code_utils,
        day: 6,
        year: 2021

## Setting up for a day

    # create scaffold
    mix aoc
    
    # just fetch data:
    mix aoc.get

## Running 

    > iex -S mix
    > recompile()
    > p1()
    > p2()
