# Khemi Chew (kjc20)

defmodule Acceptor do
  def start(config) do
    self = %{
      config: config,
      ballot_number: nil,
      # set of pvalues
      accepted: MapSet.new()
    }

    # check that acceptor is initiated
    Debug.starting(config)
    self |> next()
  end

  def next(self) do
    receive do
      %P1A{scout_pid: pid, ballot_number: b} ->
        self = if b > self.ballot_number, do: %{self | ballot_number: b}, else: self

        send(pid, %P1B{
          acceptor_pid: self(),
          ballot_number: self.ballot_number,
          accepted_pvalues: self.accepted
        })

        self |> next()

      %P2A{commander_pid: pid, pvalue: %PValue{ballot_number: b, slot_number: _s, command: _c} = pvalue} ->
        accepted =
          if b == self.ballot_number, do: self.accepted |> MapSet.put(pvalue), else: self.accepted

        self = %{self | accepted: accepted}
        send(pid, %P2B{acceptor_pid: self(), ballot_number: self.ballot_number})
        self |> next()

      unexpected ->
        Helper.node_halt "Database: unexpected message #{inspect unexpected}"
    end
  end
end
