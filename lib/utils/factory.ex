defmodule PhxPlatformUtils.Utils.Factory do
  defmacro __using__(_opts) do
    quote do
      @doc """
      Build one of Model but do not insert to database.
      """
      def build!(attrs) do
        generate()
        |> struct!(attrs)
      end

      @doc """
      Build many of Model but do not insert to database.
      """
      def build_many!(attrs \\ %{}, num_to_build) do
        1..num_to_build
        |> Enum.to_list()
        |> Enum.map(fn _ -> build!(attrs) end)
      end

      @doc """
      Build one of Model and insert to database.
      """
      def create!(attrs \\ %{}) do
        attrs
        |> build!
        |> insert!()
      end

      @doc """
      Build many of Model and insert to database.
      """
      def create_many!(attrs \\ %{}, num_to_create) do
        1..num_to_create
        |> Enum.to_list()
        |> Enum.map(fn _ -> create!(attrs) end)
      end
    end
  end
end
