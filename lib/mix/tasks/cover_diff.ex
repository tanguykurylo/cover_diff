defmodule Mix.Tasks.CoverDiff do
  @moduledoc """
  Generates a coverage report for the code in a git diff.

  ```
  mix test --cover --export-coverage <filename>
  mix cover_diff --base-branch <base_branch> --context <integer> --threshold <percentage>
  ```

  Unles specified in the command, the arguments will be fetched from the
  `:test_coverage` configuration, falling back to default values.
  """
  @requirements ["compile"]
  @shortdoc "Generates a coverage report for the code in a git diff."
  @switches [
    base_branch: :string,
    context: :integer,
    threshold: :integer
  ]
  @preferred_cli_env :test

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: @switches)
    CoverDiff.run(opts)
  end
end
