defmodule CoverDiff.Cover do
  def compile(diff) when is_list(diff) do
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
    root_dir = File.cwd!()

    Mix.Project.config()[:app]
    |> Application.spec(:modules)
    |> Enum.filter(fn module ->
      file = apply(module, :__info__, [:compile])[:source]
      path = Path.relative_to(file, root_dir)
      path in diff_files
    end)
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
  Get all cover_compiled modules
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
