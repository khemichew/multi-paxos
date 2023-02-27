# Khemi Chew (kjc20)


defmodule P1A do
  @enforce_keys [:scout_pid, :ballot_number]
  @type scout_pid:: PID
  @type ballot_number:: BallotNumber
  defstruct [:scout_pid, :ballot_number]
end

defmodule P1B do
  @enforce_keys [:acceptor_pid, :ballot_number, :accepted_pvalues]
  # accepted_pvalues is a set of pvalues
  @type acceptor_pid:: PID
  @type ballot_number:: BallotNumber
  @type accepted_pvalues:: MapSet.t(PValue)
  defstruct [:acceptor_pid, :ballot_number, :accepted_pvalues]
end

defmodule P2A do
  @enforce_keys [:commander_pid, :pvalue]
  @type commander_pid:: PID
  @type pvalue:: PValue
  defstruct [:commander_pid, :pvalue]
end

defmodule P2B do
  @enforce_keys [:acceptor_pid, :ballot_number]
  @type acceptor_pid:: PID
  @type ballot_number:: BallotNumber
  defstruct [:acceptor_pid, :ballot_number]
end

defmodule Propose do
  @enforce_keys [:slot_number, :command]
  @type slot_number:: non_neg_integer
  defstruct [:slot_number, :command]
end

defmodule Decision do
  @enforce_keys [:slot_number, :command]
  @type slot_number:: non_neg_integer
  defstruct [:slot_number, :command]
end

defmodule Adopted do
  # accepted_pvalues is a set of pvalues
  @enforce_keys [:ballot_number, :accepted_pvalues]
  @type ballot_number:: BallotNumber
  @type accepted_pvalues:: MapSet.t(PValue)
  defstruct [:ballot_number, :accepted_pvalues]
end

defmodule Preempted do
  @enforce_keys [:ballot_number]
  @type ballot_number:: BallotNumber
  defstruct [:ballot_number]
end
