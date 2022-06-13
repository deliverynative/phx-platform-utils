defmodule Mix.Dn.Types do
  @doc """
  Parses the attrs as received by generators.
  Based on types available https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Schema.html
  and Faker available https://github.com/elixirs/faker/tree/master/lib/faker
  """
  def determine_faker_generator_for_type({column, type}) do
    case {column, type} do
      {col, :string} ->
        {col, "Faker.Cat.name()"}

      {col, :uuid} ->
        {col, "Faker.UUID.v4()"}

      {col, :integer} ->
        {col, "Faker.Random.Elixir.random_between(0, 100)"}

      {col, :float} ->
        {col, "Faker.Random.Elixir.random_between(0, 10)/2"}

      {col, :decimal} ->
        {col, "Decimal.from_float(Faker.Random.Elixir.random_between(0, 10)/2)"}

      {col, :boolean} ->
        {col, "Faker.Util.pick([true, false])"}

      {col, :text} ->
        {col, "Faker.Pokemon.En.name()"}

      {col, :date} ->
        {col, "Faker.Date.backward(10)"}

      {col, :utc_datetime} ->
        {col, "Faker.DateTime.backward(10)"}

      {col, :utc_datetime_usec} ->
        {col, "Faker.DateTime.backward(10)"}

      {col, _} ->
        {col, nil}
    end
  end

  def types(attributes) do
    Enum.into(attributes, %{}, fn
      {key, {:enum, vals}} -> {key, {:enum, values: translate_enum_vals(vals)}}
      {key, {root, val}} -> {key, {root, schema_type(val)}}
      {key, val} -> {key, schema_type(val)}
    end)
  end

  def translate_enum_vals(vals) do
    vals
    |> Atom.to_string()
    |> String.split(":")
    |> Enum.map(&String.to_atom/1)
  end

  defp schema_type(:text), do: :string
  defp schema_type(:uuid), do: Ecto.UUID

  defp schema_type(val) do
    if Code.ensure_loaded?(Ecto.Type) and not Ecto.Type.primitive?(val) do
      Mix.raise("Unknown type `#{val}` given to generator")
    else
      val
    end
  end

  @one_day_in_seconds 24 * 3600

  def type_to_default(key, t, :create) do
    case t do
      {:array, _} ->
        []

      {:enum, values} ->
        build_enum_values(values, :create)

      :integer ->
        42

      :float ->
        120.5

      :decimal ->
        "120.5"

      :boolean ->
        true

      :map ->
        %{}

      :text ->
        "some #{key}"

      :date ->
        Date.add(Date.utc_today(), -1)

      :time ->
        ~T[14:00:00]

      :time_usec ->
        ~T[14:00:00.000000]

      :uuid ->
        "7488a646-e31f-11e4-aace-600308960662"

      :utc_datetime ->
        DateTime.add(build_utc_datetime(), -@one_day_in_seconds, :second, Calendar.UTCOnlyTimeZoneDatabase)

      :utc_datetime_usec ->
        DateTime.add(build_utc_datetime_usec(), -@one_day_in_seconds, :second, Calendar.UTCOnlyTimeZoneDatabase)

      :naive_datetime ->
        NaiveDateTime.add(build_utc_naive_datetime(), -@one_day_in_seconds)

      :naive_datetime_usec ->
        NaiveDateTime.add(build_utc_naive_datetime_usec(), -@one_day_in_seconds)

      _ ->
        "some #{key}"
    end
  end

  def type_to_default(key, t, :update) do
    case t do
      {:array, _} -> []
      {:enum, values} -> build_enum_values(values, :update)
      :integer -> 43
      :float -> 456.7
      :decimal -> "456.7"
      :boolean -> false
      :map -> %{}
      :text -> "some updated #{key}"
      :date -> Date.utc_today()
      :time -> ~T[15:01:01]
      :time_usec -> ~T[15:01:01.000000]
      :uuid -> "7488a646-e31f-11e4-aace-600308960668"
      :utc_datetime -> build_utc_datetime()
      :utc_datetime_usec -> build_utc_datetime_usec()
      :naive_datetime -> build_utc_naive_datetime()
      :naive_datetime_usec -> build_utc_naive_datetime_usec()
      _ -> "some updated #{key}"
    end
  end

  defp build_utc_datetime_usec,
    do: %{DateTime.utc_now() | second: 0, microsecond: {0, 6}}

  defp build_utc_datetime,
    do: DateTime.truncate(build_utc_datetime_usec(), :second)

  defp build_utc_naive_datetime_usec,
    do: %{NaiveDateTime.utc_now() | second: 0, microsecond: {0, 6}}

  defp build_utc_naive_datetime,
    do: NaiveDateTime.truncate(build_utc_naive_datetime_usec(), :second)

  defp build_enum_values(values, action) do
    case {action, translate_enum_vals(values)} do
      {:create, vals} -> hd(vals)
      {:update, [val | []]} -> val
      {:update, vals} -> vals |> tl() |> hd()
    end
  end
end
