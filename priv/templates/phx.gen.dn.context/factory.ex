defmodule <%= inspect context.module %>.Factory do
  require Faker
  use <%= inspect context.base_module %>.Factory

  alias <%= inspect context.module %>.Model

  def generate() do
    %Model{
      # Don't forget to implement the rest of this map for fake data!
      id: Faker.UUID.v4()
    }
  end
end
