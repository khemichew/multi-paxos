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
          replicas: replicas,
          timeout: config.initial_timeout
        }

        spawn(Scout, :start, [self.config, self(), self.acceptors, self.ballot_number])
        Debug.info(config, self, "Leader #{self.config.node_num} started")
        self |> next()
      unexpected ->
        Helper.node_halt("Leader: unexpected message #{inspect(unexpected)}")
    end
  end

  # Updates the set of proposals, replacing for each slot number the command corresponding to the
  # maximum pvalue in pvals/pmax, if any.
  def update_proposals(proposals, pmax) do
    Map.merge(proposals, pmax, fn _k, _p1, p2 -> p2 end)
  end

  def do_timeout(self, growth) when self.config.perform_timeout do
    timeout = case growth do
      :increase -> round(max(self.timeout * self.config.timeout_multiply, self.config.timeout_max))
      :decrease -> round(min(self.timeout - self.config.timeout_subtract, self.config.timeout_min))
      :maintain -> self.timeout
    end
    Process.sleep(timeout)
    %{self | timeout: timeout}
  end

  def do_timeout(self, _growth), do: self

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
        end) |> do_timeout(:maintain) |> next()

      %Adopted{ballot_number: ^b, accepted_pvalues: pvalues} ->
        proposals = update_proposals(self.proposals, PValues.pmax(pvalues))
        self = %{self | proposals: proposals, active: true}

        for {s, cmd} <- self.proposals do
          spawn(Commander, :start, [
            self.config,
            self(),
            self.acceptors,
            self.replicas,
            %PValue{ballot_number: b, slot_number: s, command: cmd}
          ])
        end

        # the leader does not seem to compete with another leader for the same proposal
        self |> do_timeout(:decrease) |> next()

      %Adopted{ballot_number: _b, accepted_pvalues: _pvalues} ->
        # the leader does not seem to compete with another leader for the same proposal
        self |> do_timeout(:decrease) |> next()

      %Preempted{ballot_number: %BallotNumber{priority: _p, leader_pid: other_pid} = other_b} ->
        self = (if other_b > b do
          ballot_number = %BallotNumber{priority: other_b.priority + 1, leader_pid: self()}
          spawn(Scout, :start, [self.config, self(), self.acceptors, ballot_number])
          %{self | active: false, ballot_number: ballot_number}
        else
          self
        end)

        # the leader is competing with another leader for the same proposal
        (if other_pid > self() do
          Debug.info(self.config, "Increase timeout", 5)
          self |> do_timeout(:increase)
        else

          Debug.info(self.config, "Maintain timeout", 5)
          self |> do_timeout(:maintain)
        end) |> next()

      unexpected ->
        Helper.node_halt("Database: unexpected message #{inspect(unexpected)}")
    end
  end
end
