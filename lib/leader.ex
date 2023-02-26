defmodule Leader do
  def start(config) do
    self = %{
      config: config,
      ballot_number: %BallotNumber{priority: 0, leader_pid: self()},
      active: false,
      proposals: Map.new(),
    }
    # Debug.starting(self) # check that leader is initiated
    self |> next()
  end

  # Updates the set of proposals, replacing for each slot number the command corresponding to the
  # maximum pvalue in pvals/pmax, if any.
  def update_proposals(proposals, pmax) do
    Map.merge(proposals, pmax, fn _k, _p1, p2 -> p2 end)
  end

  def next(self) do
    receive do
      {:BIND, acceptors, replicas} -> # acceptors and replicas are lists of pids
        %{self | acceptors: acceptors, replicas: replicas} |> next()

      %Propose{slot_number: s, command: c} = proposal ->
        if not Map.has_key?(self.proposals, s) do
          self = %{self | proposals: Map.put(self.proposals, s, proposal)}
          if self.active do
            pvalue = %PValue{ballot_number: self.ballot_number, slot_number: s, command: c}
            spawn(Commander, :start, [self(), self.acceptors, self.replicas, pvalue])
          end
        end
        self |> next()

      %Adopted{ballot_number: b, accepted_pvalues: pvalues} ->
        proposals = update_proposals(self.proposals, PValues.pmax(pvalues))
        self = %{self | proposals: proposals, active: true}
        for %PValue{slot_number: s, command: c} <- proposals do
          spawn(Commander, :start, [self(), self.acceptors, self.replicas, %PValue{ballot_number: b, slot_number: s, command: c}])
        end
        self |> next()

      %Preempted{ballot_number: %BallotNumber{priority: p} = b} ->
        self = if b > self.ballot_number do
          ballot_number = %BallotNumber{priority: p + 1, leader_pid: self()}
          spawn(Scout, :start, [self(), self.acceptors, ballot_number])
          %{self | active: false, ballot_number: ballot_number}
        else
          self
        end
        self |> next()
        
    end
  end
end
