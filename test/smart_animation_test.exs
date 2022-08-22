defmodule SmartAnimationTest do
  use ExUnit.Case
  doctest SmartAnimation

  test "new/1 with range" do
    assert %Kino.JS.Live{} = SmartAnimation.new(1..10)
  end

  test "new/1 with list" do
    assert %Kino.JS.Live{} = SmartAnimation.new(Enum.to_list(1..10))
  end

  test "new/1 with function" do
    assert %Kino.JS.Live{} = SmartAnimation.new(fn i -> i end)
  end

  test "new/2 with range and function" do
    assert %Kino.JS.Live{} = SmartAnimation.new(1..10, fn i -> i end)
  end

  test "new/2 with range and function and options" do
    # min speed
    assert %Kino.JS.Live{} = SmartAnimation.new(1..10, fn i -> i end, speed_multiplier: 1)
    # max speed
    assert %Kino.JS.Live{} = SmartAnimation.new(1..10, fn i -> i end, speed_multiplier: 10)
  end
end
