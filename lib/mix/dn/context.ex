defmodule Mix.Dn.Context do
  @moduledoc false

  alias Mix.Dn.{Context, Schema}

  defstruct name: nil,
            context_module: nil,
            module: nil,
            schema: nil,
            alias: nil,
            base_module: nil,
            web_module: nil,
            basename: nil,
            file: nil,
            test_file: nil,
            factory_file: nil,
            controller_file: nil,
            view_file: nil,
            controller_test_file: nil,
            changeset_view_file: nil,
            fallback_controller_file: nil,
            dir: nil,
            generate?: true,
            context_app: nil,
            opts: [],
            factory_relations: []

  def valid?(context) do
    context =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(context_name, %Schema{} = schema, opts) do
    ctx_app = opts[:context_app] || Mix.Dn.context_app()
    base = Module.concat([Mix.Dn.context_base(ctx_app)])
    module = Module.concat([base, context_name, schema.alias])
    alias = Module.concat([module |> Module.split() |> List.last()])
    basedir = Phoenix.Naming.underscore(context_name)
    basename = Path.basename(basedir)
    dir = Mix.Dn.context_lib_path(ctx_app, basedir) <> "/" <> schema.singular
    web_dir = Mix.Dn.web_path(ctx_app)
    controller_file = web_dir <> "/controllers/#{schema.singular}_controller.ex"
    view_file = web_dir <> "/views/#{schema.singular}_view.ex"
    controller_test_file = web_dir <> "/controllers/#{schema.singular}_controller_test.exs"
    changeset_view_file = web_dir <> "/views/changeset_view.ex"
    fallback_controller_file = web_dir <> "/controllers/fallback_controller.ex"

    file = dir <> "/service.ex"
    test_file = dir <> "/test.exs"
    factory_file = dir <> "/factory.ex"
    generate? = Keyword.get(opts, :context, true)
    factory_relations = derive_factory_relations(schema.requires, schema.assocs)

    %Context{
      name: context_name,
      context_module: Module.concat([base, String.to_atom(context_name)]),
      module: module,
      schema: schema,
      alias: alias,
      base_module: base,
      web_module: web_module(),
      basename: basename,
      file: file,
      test_file: test_file,
      factory_file: factory_file,
      view_file: view_file,
      controller_file: controller_file,
      controller_test_file: controller_test_file,
      changeset_view_file: changeset_view_file,
      fallback_controller_file: fallback_controller_file,
      dir: dir,
      generate?: generate?,
      context_app: ctx_app,
      opts: opts,
      factory_relations: factory_relations
    }
  end

  defp derive_factory_relations(requires, associations) do
    Enum.reduce(associations, [], fn ({name, _, mod_path, mod, _}, factory_assoc) ->
      case Enum.member?(requires, {name, true}) do
        true ->
          Keyword.put(factory_assoc, name,
            {"alias #{mod_path}.Factory, as: #{mod}Factory",
             "#{String.downcase(mod)} = #{mod}Factory.create!()",
             "#{Atom.to_string(name)}: #{String.downcase(mod)}.id,",
             "#{String.downcase(mod)}.id"
            })
        false ->
          factory_assoc
      end
    end)
  end

  def pre_existing?(%Context{file: file}), do: File.exists?(file)

  def pre_existing_tests?(%Context{test_file: file}), do: File.exists?(file)

  def function_count(%Context{file: file}) do
    {_ast, count} =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.postwalk(0, fn
        {:def, _, _} = node, count -> {node, count + 1}
        {:defdelegate, _, _} = node, count -> {node, count + 1}
        node, count -> {node, count}
      end)

    count
  end

  def file_count(%Context{dir: dir}) do
    dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.count()
  end

  defp web_module do
    base = Mix.Dn.base()

    cond do
      Mix.Dn.context_app() != Mix.Dn.otp_app() ->
        Module.concat([base])

      String.ends_with?(base, "Web") ->
        Module.concat([base])

      true ->
        Module.concat(["#{base}Web"])
    end
  end
end
