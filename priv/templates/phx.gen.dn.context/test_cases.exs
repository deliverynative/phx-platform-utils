
  describe "<%= schema.plural %>" do
    @invalid_attrs %{
      <%= for {key, _} <- schema.params.create do %><%= key %>: nil,<% end %>
      <%= for {key, _} <- schema.params.relations do %><%= key %>: nil,<% end %>
    }

    test "list_<%= schema.plural %>/0 returns all <%= schema.plural %>" do
      <%= schema.plural %> = Factory.create_many!(%{}, 3)
      assert Service.list_<%= schema.plural %>() == <%= schema.plural %>
    end

    test "get_<%= schema.singular %>!/1 returns the <%= schema.singular %> with given id" do
      <%= schema.singular %> = Factory.create!()
      assert Service.get_<%= schema.singular %>!(<%= schema.singular %>.id) == <%= schema.singular %>
    end

    test "create_<%= schema.singular %>/1 with valid data creates a <%= schema.singular %>" do
      <%= for {_, {_, create, _, _}} <- context.factory_relations do %><%= create %>
      <% end %>
      valid_attrs = %{<%= for {key, val} <- schema.params.create do %>
        <%= key %>: <%= Mix.Dn.to_text(val) %>,<% end %><%= for {key, val} <- schema.params.relations do %>
        <%= key %>: <%= val %>,<% end %>
      }

      assert {:ok, %Model{} = <%= schema.singular %>} = Service.create_<%= schema.singular %>(valid_attrs)<%= for {field, value} <- schema.params.create do %>
      assert <%= schema.singular %>.<%= field %> == <%= Mix.Dn.Schema.value(schema, field, value) %><% end %><%= for {field, value} <- schema.params.relations do %>
      assert <%= schema.singular %>.<%= field %> == <%= value %><% end %>
    end

    test "create_<%= schema.singular %>/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Service.create_<%= schema.singular %>(@invalid_attrs)
    end

    test "update_<%= schema.singular %>/2 with valid data updates the <%= schema.singular %>" do
      <%= schema.singular %> = Factory.create!()
      update_attrs = <%= Mix.Dn.to_text schema.params.update%>

      assert {:ok, %Model{} = <%= schema.singular %>} = Service.update_<%= schema.singular %>(<%= schema.singular %>, update_attrs)<%= for {field, value} <- schema.params.update do %>
      assert <%= schema.singular %>.<%= field %> == <%= Mix.Dn.Schema.value(schema, field, value) %><% end %>
    end

    test "update_<%= schema.singular %>/2 with invalid data returns error changeset" do
      <%= schema.singular %> = Factory.create!()
      assert {:error, %Ecto.Changeset{}} = Service.update_<%= schema.singular %>(<%= schema.singular %>, @invalid_attrs)
      assert <%= schema.singular %> == Service.get_<%= schema.singular %>!(<%= schema.singular %>.id)
    end

    test "delete_<%= schema.singular %>/1 deletes the <%= schema.singular %>" do
      <%= schema.singular %> = Factory.create!()
      assert {:ok, %Model{}} = Service.delete_<%= schema.singular %>(<%= schema.singular %>)
      assert_raise Ecto.NoResultsError, fn -> Service.get_<%= schema.singular %>!(<%= schema.singular %>.id) end
    end

    test "change_<%= schema.singular %>/1 returns a <%= schema.singular %> changeset" do
      <%= schema.singular %> = Factory.create!()
      assert %Ecto.Changeset{} = Service.change_<%= schema.singular %>(<%= schema.singular %>)
    end
  end
