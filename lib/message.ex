defmodule P1A do
  @enforce_keys [:scout_pid, :ballot_number]
  defstruct [:scout_pid, :ballot_number]
end

defmodule P1B do
  @enforce_keys [:acceptor_pid, :ballot_number, :accepted_pvalues]
  defstruct [:acceptor_pid, :ballot_number, :accepted_pvalues] # accepted_pvalues is a set of pvalues
end

defmodule P2A do
  @enforce_keys [:commander_pid, :pvalue]
  defstruct [:commander_pid, :pvalue]
end

defmodule P2B do
  @enforce_keys [:acceptor_pid, :ballot_number]
  defstruct [:acceptor_pid, :ballot_number]
end

defmodule Propose do
  @enforce_keys [:slot_number, :command]
  defstruct [:slot_number, :command]
end

defmodule ClientRequest do
  @enforce_keys [:command]
  defstruct [:command]
end

defmodule ClientResponse do
  @enforce_keys [:command_id, :result]
  defstruct [:command_id, :result]
end

defmodule Decision do
  @enforce_keys [:slot_number, :command]
  defstruct [:slot_number, :command]
end

defmodule Adopted do
  @enforce_keys [:ballot_number, :accepted_pvalues] # accepted_pvalues is a set of pvalues
  defstruct [:ballot_number, :accepted_pvalues]
end

defmodule Preempted do
  @enforce_keys [:ballot_number]
  defstruct [:ballot_number]
end
