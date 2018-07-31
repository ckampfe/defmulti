defmodule DefmultiTest do
  use ExUnit.Case
  doctest Defmulti

  test "greets the world" do
    assert Defmulti.hello() == :world
  end
end
