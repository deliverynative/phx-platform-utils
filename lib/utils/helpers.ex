defmodule PhxPlatformUtils.Utils.Helpers do
  def format_phone_number(phone_number) do
    phone_number |> String.trim() |> String.replace(~r/^(\\+)|\D/, "") |> String.slice(-10, 10)
  end

  defp get_date_and_time_from_olo_format(olo_formatted_datetime) do
    [olo_date, olo_time] = String.split(olo_formatted_datetime, " ")
    iso8601_date = Regex.replace(~r/(\d\d\d\d)(\d\d)(\d\d)/, olo_date, "\\g{1}-\\g{2}-\\g{3}")
    {Date.from_iso8601!(iso8601_date), Time.from_iso8601!(olo_time <> ":00.000Z")}
  end

  def convert_olo_to_datetime!(olo_formatted_datetime, time_zone \\ "Etc/UTC")
  def convert_olo_to_datetime!(nil, _), do: nil

  def convert_olo_to_datetime!(olo_formatted_datetime, time_zone) do
    {date, time} = get_date_and_time_from_olo_format(olo_formatted_datetime)
    DateTime.new!(date, time, time_zone, Tzdata.TimeZoneDatabase)
  end
end
