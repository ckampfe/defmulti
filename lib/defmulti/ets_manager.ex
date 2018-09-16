defmodule Defmulti.EtsManager do
  use GenServer
  # use Defmulti.Proxy

  # defmacro __using__(_) do
  #   quote do
  #     # import Defmulti, only: [defmulti: 2, defmethod: 2]
  #     # Module.register_attribute(__MODULE__, :methods, accumulate: true, persist: true)
  #     # @before_compile Defmulti
  #     # @on_load :register_methods
  #   end
  # end
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    s =
      try do
        :ets.new(:defmulti, [:named_table, :public, :set, read_concurrency: true])
      rescue
        _ ->
          IO.inspect("COULD NOT CREATE TABLE")
          :defmulti
      end

    File.read!("buildfile")
    |> :erlang.binary_to_term()
    |> Enum.flat_map(fn x -> x end)
    |> Enum.each(fn f ->
      :ets.insert(:defmulti, f)
    end)

    IO.inspect("defmulti ets table is started")

    {:ok, s}
    # {:ok, []}
  end
end
