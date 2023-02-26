defmodule BallotNumber do
  @enforce_keys [:priority, :leader_pid]
  defstruct [:priority, :leader_pid]

  def cmp(b1 = %BallotNumber{}, b2= %BallotNumber{}) do
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
  defstruct [:ballot_number, :slot_number, :command]
end

defmodule PValues do
  # given a set := {(s, pvalue) | pvalues}, returns the maximum pvalue for each unique slot number
  def pmax(pvalues) do
    pvalues
    |> Enum.group_by(& &1.slot_number)
    |> Enum.map(fn {_, pvals} -> pvals |> Enum.max_by(& &1.ballot_number) end)
  end
end

defmodule Command do
  @enforce_keys [:client_pid, :command_id, :operation]
  defstruct [:client_pid, :command_id, :operation]
end
