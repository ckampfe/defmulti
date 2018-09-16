defmodule Defmulti do
  @external_resource "buildfile"
  @before_compile Defmulti.Helper

  #
  defmacro __using__(_) do
    quote do
      @external_resource "buildfile"

      import Defmulti, only: [defmulti: 2, defmethod: 2]
      Module.register_attribute(__MODULE__, :methods, accumulate: true, persist: true)
      @before_compile Defmulti
      # @on_load :register_methods
      @after_compile {__MODULE__, :register}

      def register(_, _) do
        methods = __MODULE__.__info__(:attributes) |> Keyword.get_values(:methods)

        case File.read("buildfile") do
          {:ok, ""} ->
            File.write!("buildfile", :erlang.term_to_binary(methods))

          {:ok, binary} ->
            data = :erlang.binary_to_term(binary)
            new_methods = methods ++ data
            File.write!("buildfile", :erlang.term_to_binary(new_methods))

          _ ->
            File.write!("buildfile", :erlang.term_to_binary(methods))
        end
      end
    end
  end

  defmacro defmulti(name_and_args, do: body) do
    {name, _, argslist} = name_and_args

    quote do
      def unquote(name_and_args) do
        dispatch_value = unquote(body)

        case :ets.lookup(:defmulti, {__MODULE__, unquote(name), dispatch_value}) do
          [] ->
            IO.inspect("no method found for #{dispatch_value}")

          [{{m, f, a}, {module_to_call, method_to_call}}] = res ->
            apply(module_to_call, method_to_call, unquote(argslist))
        end
      end
    end
  end

  def get_opts(maybe_opts) when is_list(maybe_opts) do
    case Keyword.get(maybe_opts, :opts, []) do
      opts when opts != [] ->
        opts

      _ ->
        []
    end
  end

  def get_opts(_maybe_opts) do
    []
  end

  defmacro defmethod(name_and_args, do: body) do
    {name, _, argslist} = name_and_args
    namestring = Atom.to_string(name)
    random_bytes = random_string(30)

    namestring = String.to_atom(namestring <> "_" <> random_bytes)

    maybe_opts = List.last(argslist)

    opts = get_opts(maybe_opts)

    target_module = opts[:module]

    IO.inspect(target_module, label: "TARGET MODULE")

    new_argslist =
      if opts != [] do
        Enum.reverse(argslist) |> Enum.drop(1) |> Enum.reverse()
      else
        argslist
      end

    new_name_and_args =
      name_and_args
      |> Tuple.delete_at(0)
      |> Tuple.insert_at(0, namestring)
      |> Tuple.delete_at(2)
      |> Tuple.insert_at(2, new_argslist)

    IO.inspect(new_name_and_args)

    quote do
      this_module = unquote(target_module) || __MODULE__

      IO.inspect(this_module, label: "this module")

      Module.put_attribute(
        __MODULE__,
        :methods,
        {{this_module, unquote(name), unquote(List.first(argslist))},
         {__MODULE__, unquote(namestring)}}
      )

      def unquote(new_name_and_args) do
        unquote(body)
      end
    end
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  defmacro __before_compile__(_env) do
    quote do
      def register_methods do
        # Enum.each(@methods, fn method ->
        #   IO.inspect(method, label: "METHOD")
        #   :ets.insert(:defmulti, method)
        # end)

        :ok
      end
    end
  end
end
