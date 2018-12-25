defmodule TwitterclusterTest do
  use ExUnit.Case
  doctest Twittercluster

  test "greets the world" do
    assert Twittercluster.hello() == :world
  end
end
