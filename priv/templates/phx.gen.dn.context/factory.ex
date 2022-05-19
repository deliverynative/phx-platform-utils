defmodule <%= inspect context.module %>.Factory do
  require Faker
  use PhxPlatformUtils.Utils.Factory

  alias <%= inspect context.module %>.Model
  alias <%= inspect context.base_module %>.Repo

  def generate() do
    %Model{
      # Don't forget to implement the rest of this map for fake data!
      id: Faker.UUID.v4()<%= if length(schema.faker_attrs) > 0 do %>,<% end %>
      <%= for {col, mod, func} <- schema.faker_attrs do %>
      <%= col %>: <%= inspect mod %>.<%= func %>(),<% end %>
      <%= for {col, mod, func, args} <- schema.faker_attrs do %>
      <%= col %>: <%= inspect mod %>.<%= func %>(<%= Enum.join(args, ", ") %>),<% end %>
    }
  end

  def insert!(attrs) do
    attrs
    |> Repo.insert!()
  end
end
