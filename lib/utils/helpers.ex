defmodule PhxPlatformUtils.Utils.Helpers do
  def format_phone_number(phone_number) do
    phone_number |> String.trim() |> String.replace(~r/^(\\+)|\D/, "") |> String.slice(-10, 10)
  end
end
