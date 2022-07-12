defmodule PhxPlatformUtilsTest do
  use ExUnit.Case
  doctest PhxPlatformUtils

  test "greets the world" do
    assert PhxPlatformUtils.hello() == :world
  end

  test "formats a mega phone number" do
    assert PhxPlatformUtils.Utils.Helpers.format_phone_number("+1 (555) 555-5555") == "5555555555"
  end

  test "formats a simple phone number" do
    assert PhxPlatformUtils.Utils.Helpers.format_phone_number("5555555555") == "5555555555"
  end
end
