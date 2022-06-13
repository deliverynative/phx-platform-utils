defmodule <%= inspect context.module %>.Factory do
  require Faker
  use PhxPlatformUtils.Utils.Factory

  alias <%= inspect context.module %>.Model
  alias <%= inspect context.base_module %>.Repo

  def generate() do
    %Model{
      # Don't forget to implement the rest of this map for fake data!
      id: Faker.UUID.v4()<%= if length(schema.faker_attributes) > 0 do %>,
      <% end %>
      <%= for {col, def} <- schema.faker_attributes do %><%= col %>: <%= def %>,
      <% end %>
      <%= for {key, :belongs_to, _, _, _} <- schema.assocs do %><%= key %>: nil,
      <% end %>
    }
  end

  def insert!(attrs) do
    attrs
    |> Repo.insert!()
  end
end
