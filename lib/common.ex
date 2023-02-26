# Khemi Chew (kjc20)

defmodule BallotNumber do
  @enforce_keys [:priority, :leader_pid]
  @type priority:: non_neg_integer
  @type leader_pid:: PID
  defstruct [:priority, :leader_pid]

  def cmp(b1 = %BallotNumber{}, b2 = %BallotNumber{}) do
    cond do
      b1.priority < b2.priority -> :lt
      b1.priority > b2.priority -> :gt
      b1.leader_pid < b2.leader_pid -> :lt
      b1.leader_pid > b2.leader_pid -> :gt
      true -> :eq
    end
  end
end

defmodule PValue do
  @enforce_keys [:ballot_number, :slot_number, :command]
  @type ballot_number:: BallotNumber
  @type slot_number:: non_neg_integer
  defstruct [:ballot_number, :slot_number, :command]
end

defmodule PValues do
  # given a set := {(s, pvalue) | pvalues}, returns the maximum pvalue for each unique slot number
  def pmax(pvalues) do
    pvalues
    |> Enum.group_by(& &1.slot_number)
    |> Enum.map(fn {_, pvals} -> pvals |> Enum.max_by(& &1.ballot_number) end)
    |> Enum.reduce(Map.new(), fn pval, acc -> Map.put(acc, pval.slot_number, pval.command) end)
  end
end

# defmodule Test do
#   def main do
#     # proposals map slot number to command
#     proposals = %{1 => "a", 2 => "d", 3 => "f"}
#     expected = %{1 => "b", 2 => "d", 3 => "f"}
#     pvalues = MapSet.new([
#       %PValue{ballot_number: %BallotNumber{priority: 101, leader_pid: self()}, slot_number: 1, command: "a"},
#       %PValue{ballot_number: %BallotNumber{priority: 102, leader_pid: self()}, slot_number: 1, command: "b"},
#       %PValue{ballot_number: %BallotNumber{priority: 101, leader_pid: self()}, slot_number: 2, command: "c"},
#       %PValue{ballot_number: %BallotNumber{priority: 102, leader_pid: self()}, slot_number: 2, command: "d"}])

#     IO.inspect(PValues.pmax(pvalues))
#     f = Map.merge(proposals, PValues.pmax(pvalues), fn _k, _p1, p2 -> p2 end)
#     IO.inspect(f)
#     IO.inspect(expected)
#   end
# end

# defmodule Command do
#   @enforce_keys [:client_pid, :command_id, :operation]
#   @type client_pid:: PID
#   @type command_id:: non_neg_integer
#   @type operation:: String.t()
#   defstruct [:client_pid, :command_id, :operation]
# end
