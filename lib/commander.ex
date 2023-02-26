defmodule Commander do
  def start(leader_pid, acceptors, replicas, pvalue) do
    self = %{
      leader_pid: leader_pid,
      acceptors: acceptors,
      replicas: replicas,
      pvalue: pvalue,
      waitfor: MapSet.to_list(acceptors) |> MapSet.new()
    }
    # TODO: send a message to monitor to signify that the commander is started

    # Broadcasts p2a to all acceptors
    self.acceptors |> Enum.each(fn pid -> send(pid, %P2A{commander_pid: self(), pvalue: self.pvalue}) end)

    # Waits for p2b from all acceptors
    self |> next()
  end

  def next(%{pvalue: %PValue{ballot_number: b, slot_number: s, command: c}} = self) do
    receive do
      %P2B{acceptor_pid: pid, ballot_number: ^b} ->
          waitfor = self.waitfor |> MapSet.delete(pid)
          if MapSet.size(waitfor) < MapSet.size(self.acceptors) / 2 do
            # Notifies all replicas that command c has been decided for slot s
            self.replicas |> Enum.each(fn pid -> send(pid, %Decision{slot_number: s, command: c}) end)
            # TODO: send a message to monitor to signify that the commander is finished/decision has been made
            Helper.node_exit()
          end
          %{self | waitfor: waitfor} |> next()
      %P2B{ballot_number: b1} ->
          # the commander learns that the ballot b1 is active (b1 is necessarily greater than b since b1 >= b && b1 != b)
          send(self.leader_pid, %Preempted{ballot_number: b1})
          # TODO: send a message to monitor to signify that the commander is finished/preempted
    end
  end
end
