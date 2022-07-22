defmodule <%= inspect context.module %>.Test do
  use <%= inspect context.base_module %>.DataCase

  alias <%= inspect context.module %>.{Factory, Model, Service}
  <%= if length(context.factory_relations) > 0 do %><%= for {key, _, _, _, _} <- schema.assocs do %><%= if Keyword.has_key?(context.factory_relations, key) do %><%= Kernel.elem(context.factory_relations[key], 0)%><% end %><% end %>
  <% end %>
end
