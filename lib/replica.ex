defmodule Replica do
  def start(config, initial_state) do
    self = %{
      config: config,
      state: initial_state,
      slot_in: 1,
      slot_out: 1,
      requests: [], # list of commands
      proposals: Map.new(),
      decisions: Map.new() # map from slot number to command
    }
    Debug.starting(config) # check that replica is initiated
    self |> next()
  end

  def propose(self) do
    %{self | proposals: MapSet.union(self.proposals, self.requests)}
  end

  def perform(%{decisions: decisions, slot_out: so} = self, %Command{client_pid: k, command_id: cid, operation: op} = c) do
    if 1..(so - 1) |> Enum.filter(fn s -> decisions[s] == c end) |> Enum.empty?() do # check if c is already executed
      send(k, %ClientResponse{command_id: cid, result: op.(self.state)}) # TODO FIX THIS LINE
    end
    %{self | slot_out: so + 1}
  end

  def considers_execution(self) do
    if Map.has_key?(self.decisions, self.slot_out) do
      requests = if Map.has_key?(self.proposals, self.slot_out)
      and self.proposals[self.slot_out] != self.decisions[self.slot_out] do
        self.requests ++ [self.proposals[self.slot_out]]
      else
        self.requests
      end
      proposals = Map.delete(self.proposals, self.slot_out)

      %{self | requests: requests, proposals: proposals}
      |> perform(self.decisions[self.slot_out])
      |> considers_execution()
    else
      self
    end
  end

  def next(self) do
    receive do
      %ClientRequest{command: c} ->
        %{self | requests: MapSet.put(self.requests, c)}
        |> propose()
        |> next()
      %Decision{slot_number: s, command: c} ->
        %{self | decisions: Map.put(self.decisions, s, c)}
        |> considers_execution()
        |> propose()
        |> next()
    end
  end
end
