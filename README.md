# Multipaxos

Multidecree Paxos is a protocol used in distributed systems to achieve consensus
among a group of nodes on multiple values and how the values are ordered. It is 
most commonly used to maintain the same state across multiple replicas.

## How the protocol works

Each replica can be thought of as having a sequence of slots that needs to be filled
with commands that make up the state machine. Individual nodes may propose a different
command for each slot. To avoid inconsistency, a consensus protocol chooses a single 
command from the proposals for every slot.

Multipaxos is fault-tolerant - that is, the protocol can tolerate up to f crash failures
if it has at least f+1 leaders and 2f+1 acceptors, always leaving at least 1 leader to
order commands proposed by replicas, and f+1 acceptors to maintain the fault tolerant
memory.

| ![image](https://github.com/khemichew/multipaxos/assets/49807719/e0edc3ab-ba02-4c06-aa7c-a84053c59886) |
| :--: |
| Image 1: Relationship between replicas, leaders, and acceptors (source: https://paxos.systems/how/) |


A configuration represents a number of leader and acceptor processes that partake in 
the consensus protocol, but not the replicas. This implementation does not support 
reconfiguration, but it can be useful to extend the implementation to add new processes
when/if processes are experiencing crashes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `multipaxos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:multipaxos, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/multipaxos>.

