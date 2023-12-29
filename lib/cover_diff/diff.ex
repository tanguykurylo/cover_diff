defmodule CoverDiff.Diff do
  @moduledoc """
  Parses a diff into a list of additions and context, excluding deletions.
  For simplicity, the diff must be generated with the --no-prefix option
  (meaning there will be no "a/" and "b/" prefixes before file paths.)
  """

  @doc """
  Parses a diff in string format into a list of changes per file, taking only added or context lines (not deletions).
  """
  @spec parse(diff :: String.t()) :: [
          {filename :: String.t(),
           [
             {
               line_number :: integer,
               type :: :context | :add,
               text :: String.t()
             }
           ]}
        ]
  def parse(diff) when is_binary(diff) do
    diff
    |> String.split(["\r", "\n", "\r\n"])
    |> parse_diff(_changes = [], _line_number = nil)
  end

  # Skip deleted files
  defp parse_diff(["+++ /dev/null" | rest], changes, line_number) do
    parse_diff(rest, changes, line_number)
  end

  defp parse_diff([<<"+++ ", filename::binary>> | rest], changes, line_number) do
    parse_diff(rest, [{filename, []} | changes], line_number)
  end

  defp parse_diff([<<"@@", hunk_header::binary>> | rest], changes, _previous_line_number) do
    line_number =
      Regex.named_captures(~r/\+(?<line_number>[0-9]+)/, hunk_header)
      |> Map.fetch!("line_number")
      |> String.to_integer()

    parse_diff(rest, changes, line_number)
  end

  defp parse_diff([<<" ", text::binary>> | rest], [{filename, lines} | changes], line_number) do
    parse_diff(
      rest,
      [
        {filename, [{line_number, :context, text} | lines]}
        | changes
      ],
      line_number + 1
    )
  end

  defp parse_diff([<<"+", text::binary>> | rest], [{filename, lines} | changes], line_number) do
    parse_diff(
      rest,
      [
        {filename, [{line_number, :add, text} | lines]}
        | changes
      ],
      line_number + 1
    )
  end

  defp parse_diff([_no_match | rest], changes, line_number) do
    parse_diff(rest, changes, line_number)
  end

  defp parse_diff([], changes, _line_number) do
    Enum.map(changes, fn {filename, lines} -> {filename, Enum.reverse(lines)} end)
  end
end
