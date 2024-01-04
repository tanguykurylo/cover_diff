defmodule CoverDiff do
  @moduledoc """
  Generates a coverage report for the code in a git diff.
  To use it as a coverage module:

  ```
    def project() do
      [
        ...
        test_coverage: [tool: CoverDiff, base_branch: "my_base_branch"]
        ...
      ]
    end
  ```
  The diff will span between your current HEAD and the specified branch in
  your `:test_coverage` options:

    * `:base_branch` - branch to diff against, defaults to `"master"`
    * `:context` - how many lines to show around uncovered lines in reports,
      defaults to 2

  CoverDiff currently does not work with umbrella applications.

  CoverDiff can also be used as a Mix task without polluting your project
  configuration. This lets you use any cover tool capable of exporting
  .coverdata files during tests and analyze them afterwards using CoverDiff.
  Check Mix.Tasks.CoverDiff for details.
  """

  alias CoverDiff.{Cover, Diff, Output}

  @default_threshold 90
  @default_base_branch "master"
  @default_context_size 2
  @default_output "cover"

  def run(opts) do
    opts =
      Mix.Project.config()
      |> Keyword.get(:test_coverage, [])
      |> format_opts()
      |> Map.merge(Map.new(opts))

    with {:ok, diff} <- Diff.get_diff(opts[:base_branch], opts[:context]),
         _result <- Cover.compile_from_diff(diff),
         :ok <- Cover.import_coverage(opts[:output]) do
      generate_cover_results(diff, opts)
    else
      _ -> System.at_exit(fn _ -> exit({:shutdown, 3}) end)
    end
  end

  @doc false
  def start(_compile_path, opts) do
    opts = format_opts(opts)
    diff = Diff.get_diff(opts[:base_branch], opts[:context])
    CoverDiff.Cover.compile_from_diff(diff)
    fn -> generate_cover_results(diff, opts) end
  end

  defp format_opts(opts) do
    %{
      base_branch: opts[:base_branch] || @default_base_branch,
      context: opts[:context] || @default_context_size,
      output:
        case opts[:output] do
          false -> false
          output -> output || @default_output
        end,
      summary:
        case opts[:summary] do
          false -> false
          _ -> true
        end,
      threshold:
        case opts[:summary] do
          false -> nil
          [threshold: threshold] -> threshold
          _ -> @default_threshold
        end
    }
  end

  # If we remove a test without changing the code, coverage is not impacted :(
  def generate_cover_results(diff, opts) do
    Mix.shell().info("Generating cover results ...")

    diff
    |> add_coverage()
    |> Output.export(opts)
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
