defmodule DevNervesTest do
  use ExUnit.Case
  doctest DevNerves

  test "greets the world" do
    assert DevNerves.hello() == :world
  end
end
