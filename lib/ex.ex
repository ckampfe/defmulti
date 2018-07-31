defmodule Ex do
  require Defmulti
  import Defmulti

  @before_compile Defmulti

  defmulti(hi(x), do: rem(x, 2) == 0)
  defmethod(hi(true), do: :even)
  defmethod(hi(false), do: :odd)

  def doit do
    IO.inspect(hi(5), label: "should be odd")
    IO.inspect(hi(4), label: "should be even")
  end

  # defmulti z(x) do
  #   case x do
  #     0 ->
  #       "a"
  #     1 ->
  #       "b"
  #     -1 ->
  #       "c"
  #   end
  # end
end
