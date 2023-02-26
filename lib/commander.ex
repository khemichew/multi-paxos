# Khemi Chew (kjc20)

defmodule Commander do
  def start(config, leader_pid, acceptors, replicas, pvalue) do
    self = %{
      config: config,
      leader_pid: leader_pid,
      acceptors: acceptors,
      waitfor: Enum.into(acceptors, MapSet.new()),
      replicas: replicas,
      pvalue: pvalue
    }

    send self.config.monitor, {:COMMANDER_SPAWNED, self.config.node_num}

    # Broadcasts p2a to all acceptors
    for pid <- acceptors do
      send(pid, %P2A{commander_pid: self(), pvalue: pvalue})
    end

    # Waits for p2b from all acceptors
    self |> next()
  end

  def next(%{pvalue: %PValue{ballot_number: b, slot_number: s, command: cmd}} = self) do
    receive do
      %P2B{acceptor_pid: pid, ballot_number: ^b} ->
        waitfor = self.waitfor |> MapSet.delete(pid)

        if MapSet.size(waitfor) < MapSet.size(self.acceptors) / 2 do
          # Notifies all replicas that command c has been decided for slot s
          self.replicas
          |> Enum.each(fn pid -> send(pid, %Decision{slot_number: s, command: cmd}) end)

          send self.config.monitor, {:COMMANDER_FINISHED, self.config.node_num}
          Helper.node_exit()
        end

        %{self | waitfor: waitfor} |> next()

      %P2B{ballot_number: b1} ->
        # the commander learns that the ballot b1 is active (b1 is necessarily greater than b since b1 >= b && b1 != b)
        send self.leader_pid, %Preempted{ballot_number: b1}
        send self.config.monitor, {:COMMANDER_FINISHED, self.config.node_num}
        Helper.node_exit()

      unexpected ->
        Helper.node_halt "Database: unexpected message #{inspect unexpected}"
    end
  end
end
