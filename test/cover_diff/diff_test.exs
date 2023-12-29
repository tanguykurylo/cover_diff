defmodule CoverDiff.DiffTest do
  use ExUnit.Case, async: true
  import CoverDiff.Diff

  setup_all do
    %{diff: File.read!("test/fixtures/changes.diff")}
  end

  describe "parse/1" do
    test "parses the contents of a diff into a list of line changes", %{diff: diff} do
      result = parse(diff)

      expected = [
        {"changed.txt",
         [
           {:add, 1, "Changes done."},
           {:add, 2, "Lorem ipsum dolor sit amet, this file was changed."},
           {:context, 3, "Et odio pellentesque diam volutpat commodo sed."},
           {:context, 4, "Nec ultrices dui sapien eget mi."},
           {:context, 5, "Tellus cras adipiscing enim eu."},
           {:context, 7, "Maecenas pharetra convallis posuere morbi."},
           {:context, 8, "Donec massa sapien faucibus et molestie ac feugiat."},
           {:context, 9, "Felis eget velit aliquet sagittis id consectetur purus."},
           {:add, 10, "Massa ultricies mi quis hendrerit dolor magna eget est."},
           {:add, 11, "Pellentesque eu tincidunt tortor aliquam."},
           {:add, 12, "Enim vulputate odio ut enim blandit aliquam etiam erat velit."},
           {:context, 13, "Diam quis enim lobortis scelerisque fermentum."},
           {:context, 14, "Lacus viverra vitae congue eu consequat ac."},
           {:context, 15, "Tincidunt id aliquet risus feugiat in ante metus dictum at."},
           {:add, 16, "In fermentum et sollicitudin ac orci phasellus egestas tellus."},
           {:add, 17, "A arcu cursus vitae congue mauris rhoncus aenean."},
           {:add, 18, "New stuff."}
         ]},
        {"added.txt",
         [
           {:add, 1, "This file has been added and was not present before."}
         ]}
      ]

      assert result == expected
    end
  end
end
