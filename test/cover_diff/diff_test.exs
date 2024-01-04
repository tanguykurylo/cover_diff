defmodule CoverDiff.DiffTest do
  use ExUnit.Case, async: true
  import CoverDiff.Diff

  setup_all do
    %{diff: File.read!("test/fixtures/changes.diff")}
  end

  describe "parse/1" do
    test "parses the contents of a diff into a list of line changes", %{diff: diff} do
      result = parse(diff)

      expected = %{
        "added.txt" => [
          {1, :add, "This file has been added and was not present before."}
        ],
        "changed.txt" => [
          {1, :add, "Changes done."},
          {2, :add, "Lorem ipsum dolor sit amet, this file was changed."},
          {3, :context, "Et odio pellentesque diam volutpat commodo sed."},
          {4, :context, "Nec ultrices dui sapien eget mi."},
          {5, :context, "Tellus cras adipiscing enim eu."},
          {7, :context, "Maecenas pharetra convallis posuere morbi."},
          {8, :context, "Donec massa sapien faucibus et molestie ac feugiat."},
          {9, :context, "Felis eget velit aliquet sagittis id consectetur purus."},
          {10, :add, "Massa ultricies mi quis hendrerit dolor magna eget est."},
          {11, :add, "Pellentesque eu tincidunt tortor aliquam."},
          {12, :add, "Enim vulputate odio ut enim blandit aliquam etiam erat velit."},
          {13, :context, "Diam quis enim lobortis scelerisque fermentum."},
          {14, :context, "Lacus viverra vitae congue eu consequat ac."},
          {15, :context, "Tincidunt id aliquet risus feugiat in ante metus dictum at."},
          {16, :add, "In fermentum et sollicitudin ac orci phasellus egestas tellus."},
          {17, :add, "A arcu cursus vitae congue mauris rhoncus aenean."},
          {18, :add, "New stuff."}
        ]
      }

      assert result == expected
    end
  end
end
