defmodule CoverDiff.Output do
  require EEx

  def export(coverage, opts) do
    coverage = format_lines(coverage, opts[:context])
    if opts[:summary] do
      export(coverage, :console, opts)
    end
    if opts[:output] do
      export(coverage, :html, opts)
    end
  end

  def format_lines(coverage, context) do
    coverage
    |> Enum.reject(fn {_filename, lines} ->
      0 == Enum.count(lines, fn {_line_number, _text, cov} -> is_boolean(cov) end)
    end)
    |> Enum.map(fn {filename, lines} ->
      {filename,
       lines
       |> select_lines_to_display(context)
       |> add_spacers()}
    end)
  end

  def select_lines_to_display(lines, context) do
    padding = Stream.repeatedly(fn -> nil end) |> Enum.take(context)
    covs = padding ++ Enum.map(lines, fn {_line_number, _text, cov} -> cov end) ++ padding

    to_display =
      covs
      |> Stream.chunk_every(2 * context + 1, 1)
      |> Enum.map(fn covs ->
        Enum.any?(covs, fn cov -> cov == false end)
      end)

    lines
    |> Enum.zip(to_display)
    |> Enum.filter(fn {_line, to_display} -> to_display end)
    |> Enum.map(fn {line, _to_display} -> line end)
  end

  def add_spacers(lines) do
    {lines_with_spacers, _} =
      lines
      |> Enum.reduce({[], nil}, fn {line_number, _text, _cov} = line,
                                   {output, previous_line_number} ->
        cond do
          previous_line_number == nil ->
            {[line], line_number}

          line_number - previous_line_number > 1 ->
            {output ++ [{"...", "", nil}, line], line_number}

          true ->
            {output ++ [line], line_number}
        end
      end)

    lines_with_spacers
  end

  def stats(lines) do
    count_cov = Enum.count(lines, fn {_line_number, _text, cov} -> cov == true end)
    count_not_cov = Enum.count(lines, fn {_line_number, _text, cov} -> cov == false end)
    total = count_cov + count_not_cov
    stat = percentage(count_cov, count_not_cov)
    stat_text = "#{stat}% [#{count_cov}/#{total}]"
    {stat_text, stat}
  end

  defp percentage(0, 0), do: 100.0

  defp percentage(covered, not_covered),
    do: Float.floor(covered / (covered + not_covered) * 100, 1)

  EEx.function_from_file(
    :def,
    :html_template,
    "lib/templates/coverage_report.html.eex",
    [:file_details]
  )

  def export(coverage, :html, opts) do
    file_details =
      for {filename, lines} <- coverage do
        %{filename: filename, lines: lines, stats: stats(lines)}
      end

    html = html_template(file_details)
    path = Path.join(opts[:output], "coverage_report.html")
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, html)
    Mix.shell().info("Wrote coverage report to: #{path}")
  end

  def export(coverage, :console, opts) do
    threshold = opts[:threshold]
    coverage
    |> Enum.map(fn {filename, lines} ->
      stats =
        case stats(lines) do
          {text, percentage} when percentage >= threshold -> green_text(text)
          {text, _percentage} -> red_text(text)
        end

      head = " #{filename} : #{stats}"

      desc =
        lines
        |> Enum.map(fn {line_number, text, cov} ->
          text = if cov == false, do: red_text(text), else: text
          String.pad_leading(inspect(line_number), 6) <> "  " <> text
        end)
        |> Enum.join("\n")

      if lines != [] do
        """
        #{head}
        #{desc}
        """
      else
        ""
      end
    end)
    |> Mix.shell().info()

    total_stats =
      coverage
       |> Enum.flat_map(fn  {_filename, lines} -> lines end)
       |> stats()
      case total_stats do
        {text, percentage} when percentage >= threshold ->
          "Total coverage: #{text}" |> green_text() |> Mix.shell.info()
        {text, _percentage} ->
          "Total coverage: #{text}" |> red_text() |> Mix.shell.info()
          System.at_exit(fn _ -> exit({:shutdown, 3}) end)
      end
  end

  defp red_text(string), do: IO.ANSI.red() <> IO.ANSI.bright() <> string <> IO.ANSI.reset()
  defp green_text(string), do: IO.ANSI.green() <> IO.ANSI.bright() <> string <> IO.ANSI.reset()
end
