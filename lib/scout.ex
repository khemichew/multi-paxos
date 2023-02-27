# Khemi Chew (kjc20)

defmodule Scout do
  def start(config, leader_pid, acceptors, b) do
    self = %{
      config: config,
      leader_pid: leader_pid,
      acceptors: acceptors,
      waitfor: acceptors,
      ballot_number: b,
      pvalues: MapSet.new()
    }

    send self.config.monitor, {:SCOUT_SPAWNED, config.node_num}

    # Broadcasts p1a to all acceptors
    for pid <- acceptors do
      send(pid, %P1A{scout_pid: self(), ballot_number: b})
    end

    # Waits for p1b from all acceptors
    self |> next()
  end

  def next(%{ballot_number: b} = self) do
    receive do
      %P1B{acceptor_pid: pid, ballot_number: ^b, accepted_pvalues: accepted_pvalues} ->
        self = %{
          self
          | pvalues: MapSet.union(self.pvalues, accepted_pvalues),
            waitfor: MapSet.delete(self.waitfor, pid)
        }

        if MapSet.size(self.waitfor) < MapSet.size(self.acceptors) / 2 do
          # Notifies the leader that the scout has finished
          send self.leader_pid, %Adopted{ballot_number: b, accepted_pvalues: self.pvalues}
          send self.config.monitor, {:SCOUT_FINISHED, self.config.node_num}
          Process.exit(self(), :normal)
          Helper.node_halt("Unreachable code in Scout: adopted")
        end

        self |> next()

      %P1B{acceptor_pid: _pid, ballot_number: b1, accepted_pvalues: _pvalues} ->
        # assert b != b1
        send self.leader_pid, %Preempted{ballot_number: b1}
        send self.config.monitor, {:SCOUT_FINISHED, self.config.node_num}
        Process.exit(self(), :normal)
        Helper.node_halt("Unreachable code in Scout: preempted")

      unexpected ->
        Helper.node_halt "Scout: unexpected message #{inspect unexpected}"
    end
  end
end
