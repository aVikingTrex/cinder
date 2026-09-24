defmodule Cinder.Collection.ComponentApiTest do
  use ExUnit.Case, async: true

  alias Cinder.Collection

  describe "load component attributes" do
    test "collection declares opt-in inference" do
      attrs = Collection.__components__()[:collection].attrs
      infer_loads = Enum.find(attrs, &(&1.name == :infer_loads))

      assert infer_loads.type == :boolean
      assert infer_loads.opts[:default] == false
    end

    test "collection declares column loads" do
      collection_col = find_slot(Collection.__components__()[:collection].slots, :col)

      assert find_attr(collection_col.attrs, :load).type == :any
    end
  end

  describe "processed column loads" do
    test "preserves bare, named, and multiple load declarations" do
      columns =
        Collection.process_columns(
          [
            %{field: "title", load: true},
            %{field: "title", load: "display_title"},
            %{field: "title", load: ["display_title", "alternate_title"]}
          ],
          nil
        )

      assert Enum.map(columns, & &1.load) == [
               true,
               "display_title",
               ["display_title", "alternate_title"]
             ]
    end

    test "defaults columns without a load declaration to false" do
      [column] = Collection.process_columns([%{field: "title"}], nil)

      assert column.load == false
    end
  end

  describe "normalized load requests" do
    test "infers each column field" do
      columns = [%{field: "title"}, %{field: "artist.display_name"}]

      assert Collection.normalize_load_requests(columns, true) == [
               %{path: "title", source: :inferred, column_field: "title"},
               %{
                 path: "artist.display_name",
                 source: :inferred,
                 column_field: "artist.display_name"
               }
             ]
    end

    test "normalizes bare, named, and multiple explicit loads" do
      columns = [
        %{field: "title", load: true},
        %{field: "title", load: "display_title"},
        %{field: "title", load: ["alternate_title", "display_title"]}
      ]

      assert Collection.normalize_load_requests(columns, false) == [
               %{path: "title", source: :explicit, column_field: "title"},
               %{path: "display_title", source: :explicit, column_field: "title"},
               %{path: "alternate_title", source: :explicit, column_field: "title"}
             ]
    end

    test "combines inferred and explicit loads additively" do
      columns = [%{field: "display_title", load: "alternate_title"}]

      assert Collection.normalize_load_requests(columns, true) == [
               %{path: "display_title", source: :inferred, column_field: "display_title"},
               %{path: "alternate_title", source: :explicit, column_field: "display_title"}
             ]
    end

    test "deduplicates identical requests and preserves explicit source" do
      columns = [
        %{field: "display_title", load: ["alternate_title", "alternate_title", "display_title"]},
        %{field: "display_title", load: "display_title"}
      ]

      assert Collection.normalize_load_requests(columns, true) == [
               %{path: "display_title", source: :explicit, column_field: "display_title"},
               %{path: "alternate_title", source: :explicit, column_field: "display_title"}
             ]
    end

    test "skips missing and empty paths" do
      columns = [
        %{field: nil, load: true},
        %{field: "", load: ["", nil, "valid"]},
        %{field: "ignored", load: false}
      ]

      assert Collection.normalize_load_requests(columns, true) == [
               %{path: "valid", source: :explicit, column_field: ""},
               %{path: "ignored", source: :inferred, column_field: "ignored"}
             ]
    end
  end

  defp find_slot(slots, name), do: Enum.find(slots, &(&1.name == name))
  defp find_attr(attrs, name), do: Enum.find(attrs, &(&1.name == name))
end
