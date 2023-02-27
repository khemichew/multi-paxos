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
  # given a set := {(s, pvalue) | pvalues}, returns a map of slot number
  # to command corresponding to maximum ballot number
  def pmax(pvalues) do
    pvalues
    |> Enum.group_by(& &1.slot_number)
    |> Enum.reduce(Map.new(), fn {slot_number, pvals}, acc ->
      %PValue{command: cmd} = Enum.max_by(pvals, fn pval -> pval.ballot_number end)
      Map.put(acc, slot_number, cmd)
    end)
  end
end
