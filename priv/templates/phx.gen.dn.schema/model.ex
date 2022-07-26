defmodule <%= inspect schema.module %>.Model do
  use  PhxPlatformUtils.Utils.Schema
  import Ecto.Changeset
  <%= if schema.soft_delete do %>import Ecto.SoftDelete.Schema
  <% end %>
  <%= for {_, _, module_path, alias_name, _} <- schema.assocs do %>alias <%= module_path %>.Model, as: <%= alias_name %>Model
  <% end %>
<%= if schema.prefix do %>
  @schema_prefix :<%= schema.prefix %><% end %><%= if schema.binary_id do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id<% end %>
  schema <%= inspect schema.table %> do
<%= Mix.Phoenix.Schema.format_fields_for_schema(schema) %>
<%= for {key, :belongs_to, _, alias_name, table} <- schema.assocs do %>    belongs_to <%= inspect table %>, <%= alias_name %>Model, foreign_key: <%= inspect key %><% end %>
<%= for {_, :has_one, _, alias_name, table} <- schema.assocs do %>    has_one <%= inspect table %>, <%= alias_name %>Model, foreign_key: <%= inspect schema.atomic_singular %>_id<% end %>
<%= for {_, :has_many, _, alias_name, table} <- schema.assocs do %>    has_many <%= inspect table %>, <%= alias_name %>Model, foreign_key: <%= inspect schema.atomic_singular %>_id<% end %>
    <%= if schema.soft_delete do %>soft_delete_schema()<% end %>
    timestamps()
  end

  @doc false
  def changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [<%= Enum.map_join(schema.castables, ", ", &inspect(&1)) %>])
    |> validate_required(<%= inspect(Keyword.keys(schema.requires)) %>)
    <%= for {key, :belongs_to, _, _, _} <- schema.assocs do %>|> foreign_key_constraint(<%= inspect key %>)<% end %>
    <%= for k <- schema.uniques do %>|> unique_constraint(<%= inspect k %>)<% end %>
  end
end
