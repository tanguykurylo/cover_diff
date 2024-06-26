defmodule CoverDiff.Cover do
  @moduledoc """
  THis module wraps the Erlang `:cover` module functionality.
  """

  @doc """
  Reads a diff and cover_compile only the files relevant to the diff.
  """
  def compile_from_diff(diff) when is_map(diff) do
    Mix.shell().info("Cover compiling modules ...")
    :cover.stop()
    {:ok, pid} = :cover.start()

    # Silence analyse import messages emitted by cover
    {:ok, string_io} = StringIO.open("")
    Process.group_leader(pid, string_io)

    diff
    |> modules_from_diff()
    |> :cover.compile_beam()
  end

  def modules_from_diff(diff) do
    diff_files = Enum.map(diff, fn {file, _changes} -> file end)

    apps =
      case Mix.Project.config()[:app] do
        # umbrella project
        nil -> Mix.Project.apps_paths() |> Map.keys()
        # normal project
        app -> [app]
      end

    apps
    |> Enum.flat_map(fn app -> Application.spec(app, :modules) end)
    |> Enum.filter(fn module -> module_path(module) in diff_files end)
  end

  @doc """
  Imports coverage data generated by a cover module from the output directory.
  """
  def import_coverage(output_directory) do
    cover_files =
      output_directory
      |> Path.join("*.coverdata")
      |> Path.wildcard()

    case cover_files do
      [] ->
        Mix.shell().error("No .coverdata file found in the directory: " <> output_directory)
        :error

      files ->
        for file <- files do
          Mix.shell().info("Importing cover results: #{file}")
          :ok = :cover.import(String.to_charlist(file))
        end

        :ok
    end
  end

  @doc """
  Returns the relative file path of a module.
  """
  def module_path(module) do
    # see https://groups.google.com/g/elixir-lang-talk/c/Ls0eJDdMMW8/m/VLWWAKWPAQAJ
    root_dir = File.cwd!()
    file = apply(module, :__info__, [:compile])[:source]
    Path.relative_to(file, root_dir)
  end

  @doc """
  Gets all cover_compiled modules
  """
  def modules do
    :cover.modules()
    |> Enum.filter(&source_file_present?/1)
    # Remove duplicates
    |> MapSet.new()
  end

  defp source_file_present?(module) do
    case apply(module, :__info__, [:compile])[:source] do
      nil -> false
      file -> File.exists?(file)
    end
  end

  @doc """
  Returns the result of coverage analysis
  """
  def analyze() do
    {:result, result, _fail} = :cover.analyse(:line)
    result
  end
end
