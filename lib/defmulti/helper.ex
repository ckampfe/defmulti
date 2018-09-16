defmodule Defmulti.Helper do
  defmacro __before_compile__(_env) do
    File.rm("buildfile")
  end
end
