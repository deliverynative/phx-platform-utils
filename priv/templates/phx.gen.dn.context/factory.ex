defmodule <%= inspect context.module %>.Factory do
  require Faker
  use PhxPlatformUtils.Utils.Factory

  alias <%= inspect context.module %>.Model
  alias <%= inspect context.base_module %>.Repo
  <%= if length(context.factory_relations) > 0 do %><%= for {key, _, _, _, _} <- schema.assocs do %><%= if Keyword.has_key?(context.factory_relations, key) do %><%= Kernel.elem(context.factory_relations[key], 0)%><% end %><% end %>
  <% end %>

  def generate() do
    <%= if length(context.factory_relations) > 0 do %><%= for {key, _, _, _, _} <- schema.assocs do %><%= if Keyword.has_key?(context.factory_relations, key) do %><%= Kernel.elem(context.factory_relations[key], 1)%><% end %><% end %>
    <% end %>
    %Model{
      # Don't forget to implement the rest of this map for fake data!
      id: Faker.UUID.v4(),
      <%= for {col, def} <- schema.faker_attributes do %><%= col %>: <%= def %>,
      <% end %>
      <%= for {key, :belongs_to, _, _, _} <- schema.assocs do %><%= if Keyword.has_key?(context.factory_relations, key) do %><%= Kernel.elem(context.factory_relations[key], 2)%><% else %><%= key %>: nil,<% end %>
      <% end %>
    }
  end

  def insert!(attrs) do
    attrs
    |> Repo.insert!()
  end
end
