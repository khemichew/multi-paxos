defmodule Acceptor do
  def start(config) do
    self = %{
      config: config,
      ballot_number: :nil,
      accepted: MapSet.new() # set of pvalues
    }
    Debug.starting(config) # check that acceptor is initiated
    self |> next()
  end

  def next(self) do
    receive do
      %P1A{scout_pid: pid, ballot_number: b} ->
        self = if b > self.ballot_number, do: %{self | ballot_number: b}, else: self
        send(pid, %P1B{acceptor_pid: self(), ballot_number: self.ballot_number, accepted_pvalues: self.accepted})
        self |> next()
      %P2A{commander_pid: pid, pvalue: %PValue{ballot_number: b} = pvalue} ->
        accepted = if b == self.ballot_number, do: self.accepted |> MapSet.put(pvalue), else: self.accepted
        self = Map.put(self, :accepted, accepted)
        send(pid, %P2B{acceptor_pid: self(), ballot_number: self.ballot_number})
        self |> next()
    end
  end
end
