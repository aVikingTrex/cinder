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

  defp find_slot(slots, name), do: Enum.find(slots, &(&1.name == name))
  defp find_attr(attrs, name), do: Enum.find(attrs, &(&1.name == name))
end
