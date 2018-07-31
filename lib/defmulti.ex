defmodule Defmulti do
  defmacro defmulti(name_and_args, do: body) do
    {name, _, argslist} = name_and_args
    namestring = Atom.to_string(name)
    namestring = String.to_atom("DefMulti" <> namestring)

    quote do
      {:ok, _} =
        Agent.start_link(
          fn ->
            %{}
          end,
          name: unquote(namestring)
        )

      def unquote(name_and_args) do
        IO.inspect(unquote(argslist), label: "AL")
        dispatcher = unquote(body)
        IO.inspect(dispatcher, label: "dispatch value")
        IO.inspect(unquote(namestring), label: "namestring in multi")

        apply(ABC, :dispatch, [%{argslist: unquote(argslist), dispatch_value: dispatcher}])
      end
    end
  end

  defmacro defmethod(name_and_args, do: body) do
    {name, _, argslist} = name_and_args
    IO.inspect(name_and_args, label: "name and args in defmethod")
    namestring = Atom.to_string(name)
    namestring = String.to_atom("DefMulti" <> namestring)

    quote do
      Agent.update(unquote(namestring), fn state ->
        IO.inspect(unquote(namestring))
        body = unquote(body)

        contents =
          quote do
            def apply(args) do
              IO.inspect(args, label: "ARGSLIST")
              unquote(body)
            end
          end

        module_name = System.monotonic_time() |> to_string() |> String.to_atom()
        Module.create(module_name, contents, Macro.Env.location(__ENV__))
        Map.put(state, unquote(Enum.at(argslist, 0)), {module_name, :apply, unquote(argslist)})
      end)
    end
  end

  defmacro __before_compile__(_env) do
    x = Macro.escape(Agent.get(:DefMultihi, fn state -> state end))

    contents =
      quote do
        def dispatch(args) do
          {m, f, a} = Map.get(unquote(x), args[:dispatch_value])
          IO.inspect({m, f, a})
          apply(m, f, [args])
        end
      end

    {:module, m, _b, _t} = Module.create(ABC, contents, Macro.Env.location(__ENV__))

    :ok
  end
end
