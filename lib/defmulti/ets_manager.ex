defmodule Defmulti.EtsManager do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    s =
      try do
        :ets.new(:defmulti, [:named_table, :public, :set, read_concurrency: true])
      rescue
        _ ->
          :defmulti
      end

    IO.inspect("defmulti ets table is available")

    {:ok, s}
  end
end
