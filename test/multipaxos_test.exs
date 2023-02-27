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

  test "nil is smaller than any BallotNumber value" do
    assert nil < %BallotNumber{priority: 1, leader_pid: self()}
  end

  test "Leader.update_proposals replaces proposals with pmax" do
    proposals = %{1 => "a", 2 => "d", 3 => "f"}
    pmax = %{1 => "b", 2 => "d"}
    expected = %{1 => "b", 2 => "d", 3 => "f"}
    assert Leader.update_proposals(proposals, pmax) == expected
  end

  test "PValues.pmax returns a map of slot number to command corresponding to maximum ballot number" do
    pvalues = [
      %PValue{ballot_number: %BallotNumber{priority: 1, leader_pid: self()}, slot_number: 1, command: "a"},
      %PValue{ballot_number: %BallotNumber{priority: 2, leader_pid: self()}, slot_number: 1, command: "b"},
      %PValue{ballot_number: %BallotNumber{priority: 1, leader_pid: self()}, slot_number: 2, command: "c"},
      %PValue{ballot_number: %BallotNumber{priority: 2, leader_pid: self()}, slot_number: 2, command: "d"},
      %PValue{ballot_number: %BallotNumber{priority: 1, leader_pid: self()}, slot_number: 3, command: "e"},
      %PValue{ballot_number: %BallotNumber{priority: 2, leader_pid: self()}, slot_number: 3, command: "f"}
    ]
    expected = %{1 => "b", 2 => "d", 3 => "f"}
    assert PValues.pmax(pvalues) == expected
  end
end
