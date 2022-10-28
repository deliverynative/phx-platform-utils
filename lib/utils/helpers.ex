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

  def parse_datetime_from_postgres!(date_string) do
    date_with_t = Regex.replace(~r/\s/, date_string, "T", global: false)

    formatted_date_string = Regex.replace(~r/(\s)(.+)(\d\d)$/, date_with_t, "\\g{2}:\\g{3}")

    case DateTime.from_iso8601(formatted_date_string) do
      {:ok, datetime, _} ->
        datetime

      {:error, error} ->
        throw("Could not parse datetime from postgres, recieved error: #{to_string(error)}")
    end
  end

  def convert_olo_to_datetime_by_offset!(nil, _), do: nil

  def convert_olo_to_datetime_by_offset!(olo_formatted_datetime, offset_decimal_string) do
    decimalized_offset_string = unless String.contains?(offset_decimal_string, "."), do: offset_decimal_string <> ".0", else: offset_decimal_string
    [_, negative, hour, min] = Regex.run(~r/(-?)([0-9]+)\.?([0-9]+)?/, decimalized_offset_string)

    symbol = if String.length(negative) > 0, do: "-", else: "+"
    offset = symbol <> String.pad_leading(hour, 2, "0") <> ":" <> String.pad_trailing(min, 2, "0")
    {date, time} = get_date_and_time_from_olo_format(olo_formatted_datetime)

    iso8601 = Date.to_string(date) <> "T" <> Time.to_iso8601(time) <> offset
    {:ok, date, _} = DateTime.from_iso8601(iso8601)
    date
  end

  def datetime_in_zone(datetime, zone) do
    datetime
    |> DateTime.shift_zone!(zone)
    |> DateTime.truncate(:millisecond)
  end

  def utc_from_iso8601!(iso8601_string) do
    unless iso8601_string == nil do
      case DateTime.from_iso8601(iso8601_string <> "Z") do
        {:ok, date, _offset} ->
          date

        {:error, err} ->
          raise err
      end
    else
      nil
    end
  end
end
