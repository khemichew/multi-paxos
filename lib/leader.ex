# Khemi Chew (kjc20)

defmodule Leader do
  def start(config) do
    receive do
      # acceptors and replicas are lists of pids
      {:BIND, acceptors, replicas} ->
        self = %{
          config: config,
          ballot_number: %BallotNumber{priority: 0, leader_pid: self()},
          active: false,
          proposals: Map.new(),
          acceptors: Enum.into(acceptors, MapSet.new()),
          replicas: replicas
        }

        spawn(Scout, :start, [self.config, self(), self.acceptors, self.ballot_number])
        Debug.info(config, self, "Leader #{self.config.node_num} started")
        self |> next()
    end
  end

  # Updates the set of proposals, replacing for each slot number the command corresponding to the
  # maximum pvalue in pvals/pmax, if any.
  def update_proposals(proposals, pmax) do
    Map.merge(proposals, pmax, fn _k, _p1, p2 -> p2 end)
  end

  def next(%{ballot_number: b} = self) do
    receive do
      %Propose{slot_number: s, command: cmd} ->
        (if not Map.has_key?(self.proposals, s) do
          if self.active do
            pvalue = %PValue{ballot_number: self.ballot_number, slot_number: s, command: cmd}
            spawn(Commander, :start, [self.config, self(), self.acceptors, self.replicas, pvalue])
          end

          %{self | proposals: Map.put(self.proposals, s, cmd)}
        else
          self
        end)
        |> next()

      %Adopted{ballot_number: ^b, accepted_pvalues: pvalues} ->
        proposals = update_proposals(self.proposals, PValues.pmax(pvalues))
        self = %{self | proposals: proposals, active: true}

        for {s, cmd} <- proposals do
          spawn(Commander, :start, [
            self.config,
            self(),
            self.acceptors,
            self.replicas,
            %PValue{ballot_number: b, slot_number: s, command: cmd}
          ])
        end

        self |> next()

      %Adopted{} ->
        self |> next()

      %Preempted{ballot_number: %BallotNumber{priority: p} = b1} ->
        if b1 > b do
          ballot_number = %BallotNumber{priority: p + 1, leader_pid: self()}
          spawn(Scout, :start, [self.config, self(), self.acceptors, ballot_number])
          %{self | active: false, ballot_number: ballot_number}
        else
          self
        end
        |> next()

      unexpected ->
        Helper.node_halt("Database: unexpected message #{inspect(unexpected)}")
    end
  end
end
