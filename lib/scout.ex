# Khemi Chew (kjc20)

defmodule Scout do
  def start(config, leader_pid, acceptors, b) do
    self = %{
      config: config,
      leader_pid: leader_pid,
      acceptors: acceptors,
      ballot_number: b,
      waitfor: Enum.into(acceptors, MapSet.new()),
      pvalues: MapSet.new()
    }

    send self.config.monitor, {:SCOUT_SPAWNED, config.node_num}

    # Broadcasts p1a to all acceptors
    self.acceptors
    |> Enum.each(fn pid -> send(pid, %P1A{scout_pid: self(), ballot_number: b}) end)

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
          Helper.node_exit()
        end

        self |> next()

      %P1B{ballot_number: b1} ->
        send(self.leader_pid, %Preempted{ballot_number: b1})
        send self.config.monitor, {:SCOUT_FINISHED, self.config.node_num}
        Helper.node_exit()

      unexpected ->
        Helper.node_halt "Scout: unexpected message #{inspect unexpected}"
    end
  end
end
