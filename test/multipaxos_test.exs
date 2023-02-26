defmodule MultipaxosTest do
  use ExUnit.Case
  doctest Multipaxos

  def recurse(acc, [x | xs]) do
    recurse(acc ++ [x], xs)
  end

  def recurse(acc, _xs) do
    acc
  end

  test "pattern match list behaviour in Replica.propose" do
    assert recurse([1,2,3], [4,5,6]) == [1,2,3,4,5,6]
  end

  
end
