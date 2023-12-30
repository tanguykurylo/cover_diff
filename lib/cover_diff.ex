defmodule CoverDiff do
  @moduledoc """
  Generates a coverage report for the code in a git diff.
  The diff will span between your current branch and the specified branch in
  your `:test_coverage` options:

    * `:base_branch` - branch to diff against, defaults to `"master"`

  ## Usage
      def project() do
        [
          ...
          test_coverage: [tool: CoverDiff, base_branch: "my_base_branch"]
          ...
        ]
      end
  """

  # use Mix.Task

  alias CoverDiff.Cover

  @default_threshold 90
  @default_base_branch "master"
  @default_context_size 2
  @default_format :console

  @doc false
  def start(_compile_path, opts) do
    Mix.shell().info("Cover compiling modules ...")
    opts = format_opts(opts)
    diff = CoverDiff.Diff.get_diff(opts[:base_branch], opts[:context])
    CoverDiff.Cover.compile_from_diff(diff)

    fn ->
      Mix.shell().info("\nGenerating cover results ...\n")
      generate_cover_results(diff, opts)
    end
  end

  defp format_opts(opts) do
    %{
      base_branch: opts[:base_branch] || @default_base_branch,
      context: opts[:context] || @default_context_size,
      format: opts[:format] || @default_format,
      threshold: opts[:threshold] || @default_threshold
    }
  end

  # If we remove a test without changing the code, coverage is not impacted :(
  def generate_cover_results(diff, opts) do
    diff
    |> add_coverage()
    |> CoverDiff.Output.export(opts)
  end

  defp add_coverage(changes) do
    coverage = gather_coverage(changes)

    changes
    |> Enum.map(fn {filename, lines} ->
      lines =
        for {line_number, type, text} <- lines do
          coverage =
            case type do
              :context -> nil
              :add -> coverage[{filename, line_number}]
            end

          {line_number, text, coverage}
        end

      {filename, lines}
    end)
  end

  defp gather_coverage(changes) do
    results = Cover.analyze()
    modules = Cover.modules()
    filenames = Map.new(modules, fn module -> {module, Cover.module_path(module)} end)
    changed_modules = Enum.filter(modules, fn module -> changes[filenames[module]] != nil end)

    for {{module, line}, cov} <- results, module in changed_modules, line != 0, reduce: %{} do
      acc ->
        case cov do
          {1, 0} -> Map.put(acc, {filenames[module], line}, true)
          {0, 1} -> Map.put_new(acc, {filenames[module], line}, false)
        end
    end
  end
end
