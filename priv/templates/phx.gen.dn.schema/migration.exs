defmodule <%= inspect schema.repo %>.Migrations.Create<%= Macro.camelize(schema.table) %> do
  use <%= inspect schema.migration_module %>
  <%= if schema.soft_delete do %> import Ecto.SoftDelete.Migration
  <% end %>

  def change do
    create table(:<%= schema.table %><%= if schema.binary_id do %>, primary_key: false<% end %><%= if schema.prefix do %>, prefix: :<%= schema.prefix %><% end %>) do
<%= if schema.binary_id do %>      add :id, :binary_id, primary_key: true
<% end %><%= for {k, v} <- schema.attrs do %>      add <%= inspect k %>, <%= inspect Mix.Phoenix.Schema.type_for_migration(v) %><%= schema.migration_defaults[k] %><%= if schema.requires[k] do %>, null: false<% end %>
<% end %><%= for {key, :belongs_to, _, _, other} <- schema.assocs do %>      add <%= inspect(key) %>, references(<%= inspect(other) %>, on_delete: :nothing<%= if schema.binary_id do %>, type: :binary_id<% end %>)<%= if schema.requires[key] do %>, null: false<% end %>
<% end %>
<%= if schema.soft_delete do %>      soft_delete_columns()
<% end %>
      timestamps()
    end
<%= if Enum.any?(schema.indexes) do %><%= for index <- schema.indexes do %>
    <%= index %><% end %>
<% end %>  end
end
