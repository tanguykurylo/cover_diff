defmodule CoverDiff.Output do
  require EEx

  def export(coverage, opts) do
    coverage = format_lines(coverage, opts[:context])
    export(coverage, opts[:format], opts)
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

  def stats(lines, threshold) do
    count_cov = Enum.count(lines, fn {_line_number, _text, cov} -> cov == true end)

    count_not_cov = Enum.count(lines, fn {_line_number, _text, cov} -> cov == false end)
    total = count_cov + count_not_cov
    stat = percentage(count_cov, count_not_cov)
    stat_text = "#{stat}% [#{count_cov}/#{total}]"

    cond do
      stat >= threshold -> {:ok, stat_text}
      stat < threshold -> {:bad_coverage, stat_text}
    end
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
        %{filename: filename, lines: lines, stats: stats(lines, opts[:threshold])}
      end

    html = html_template(file_details)
    path = "tmp/coverage_report.html"
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, html)
    Mix.shell().info("Wrote coverage report to: #{path}")
  end

  def export(coverage, :console, opts) do
    coverage
    |> Enum.map(fn {filename, lines} ->
      stats =
        case stats(lines, opts[:threshold]) do
          {:ok, text} -> green_text(text)
          {:bad_coverage, text} -> red_text(text)
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
  end

  def html_file_details(filename, lines, opts) do
    {covered, stats_text} = stats(lines, opts[:threshold])

    template = """
    <div class="file">
      <p
        <%= if @covered == :bad_coverage do %>
        class="uncovered"
        <% end %>
      >
        <%= @filename <> " " <> @stats_text %>
      </p>
      <table>
      <%= for {line_number, text, cov} <- @lines do %>
        <tr
          <%= if cov == false do %>
          class="uncovered"
          <% end %>
        >
          <td><code><%= String.pad_leading(inspect(line_number), 6) %></code></td>
          <td><code><%= text %></code></td>
        </tr>
      <% end %>
      </table>
    </div>
    """

    EEx.eval_string(template,
      assigns: [
        filename: filename,
        lines: lines,
        covered: covered,
        stats_text: stats_text
      ]
    )
  end

  defp red_text(string), do: IO.ANSI.red() <> IO.ANSI.bright() <> string <> IO.ANSI.reset()
  defp green_text(string), do: IO.ANSI.green() <> IO.ANSI.bright() <> string <> IO.ANSI.reset()
end
