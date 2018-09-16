defmodule Defmulti do
  defmacro __using__(_) do
    quote do
      import Defmulti, only: [defmulti: 2, defmethod: 2]
      Module.register_attribute(__MODULE__, :methods, accumulate: true)
      @before_compile Defmulti
      @on_load :register_methods
    end
  end

  defmacro defmulti(name_and_args, do: body) do
    {name, _, argslist} = name_and_args

    quote do
      def unquote(name_and_args) do
        mod = __MODULE__
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

  defmacro defmethod(name_and_args, do: body) do
    {name, _, argslist} = name_and_args
    namestring = Atom.to_string(name)
    random_bytes = random_string(30)

    namestring = String.to_atom(namestring <> "_" <> random_bytes)

    new_name_and_args =
      name_and_args
      |> Tuple.delete_at(0)
      |> Tuple.insert_at(0, namestring)

    quote do
      this_module = __MODULE__

      Module.put_attribute(
        __MODULE__,
        :methods,
        {{__MODULE__, unquote(name), unquote(List.first(argslist))},
         {this_module, unquote(namestring)}}
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
        Enum.each(@methods, fn method ->
          :ets.insert(:defmulti, method)
        end)

        :ok
      end
    end
  end
end
