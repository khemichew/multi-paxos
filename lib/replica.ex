# Khemi Chew (kjc20)

defmodule Replica do
  def start(config, database) do
    receive do
      {:BIND, leaders} ->
        Debug.info(config, "  Replica #{config.node_num} started with database #{inspect database}")
        %{
          config: config,
          database_pid: database,
          slot_in: 1,
          slot_out: 1,
          # list of commands (raw type)
          requests: [],
          # Map from slot number to command (raw type)
          proposals: Map.new(),
          # map from slot number to command (raw type)
          decisions: Map.new(),
          leaders: leaders
        }
        |> next()
      unexpected ->
        Helper.node_halt("Unexpected message in Replica: #{inspect unexpected}")
    end
  end

  @tailrec
  def propose(%{requests: [cmd | cmds] = requests, slot_in: slot_in} = self) do
    Debug.info(self.config, " Requests element count: #{length(requests)} (slot #{slot_in})", 20)

      (if not Map.has_key?(self.decisions, slot_in) do
        proposals = Map.put(self.proposals, slot_in, cmd)

        # send propose to all leaders
        for pid <- self.leaders do
          send pid, %Propose{slot_number: slot_in, command: cmd}
        end

        %{self | requests: cmds, proposals: proposals}
      else
        self
      end)
      |> Map.put(:slot_in, slot_in + 1)
      |> propose()
  end

  def propose(self), do: self

  def perform(%{decisions: decisions, slot_out: slot_out} = self) do
    {client_pid, command_id, transaction} = decisions[slot_out]
    # check if command has not already been executed
    if 1..(slot_out - 1)
       |> Enum.filter(fn s -> decisions[s] == decisions[slot_out] end)
       |> Enum.empty?() do

      # execute command on current state
      send self.database_pid, {:EXECUTE, transaction}
      Debug.info(self.config, "  Executing #{inspect transaction} on #{inspect self.database_pid} (slot #{slot_out})")

      # return result to client
      send client_pid, {:CLIENT_REPLY, command_id, :ok}
    end

    %{self | slot_out: slot_out + 1}
  end

  @tailrec
  def try_perform(self) do
    if Map.has_key?(self.decisions, self.slot_out) do
      requests =
        if Map.has_key?(self.proposals, self.slot_out) and
             self.proposals[self.slot_out] != self.decisions[self.slot_out] do
          self.requests ++ [self.proposals[self.slot_out]]
        else
          self.requests
        end

      %{self | requests: requests, proposals: Map.delete(self.proposals, self.slot_out)}
      |> perform()
      |> try_perform()
    else
      self
    end
  end

  @tailrec
  def next(self) do
    receive do
      {:CLIENT_REQUEST, cmd} ->
        Debug.info(self.config, "  Received transaction: #{inspect cmd}", 30)
        send self.config.monitor, {:CLIENT_REQUEST, self.config.node_num}
        %{ self | requests: self.requests ++ [cmd] }
        |> propose()
        |> next()

      %Decision{slot_number: s, command: cmd} ->
        Debug.info(self.config, "  Received decision: #{inspect cmd} (slot #{s})", 10)
        %{self | decisions: Map.put(self.decisions, s, cmd)}
        |> try_perform()
        |> propose()
        |> next()

      unexpected ->
        Helper.node_halt "Database: unexpected message #{inspect unexpected}"

    end
  end
end
