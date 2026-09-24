defmodule Cinder.Integration.InferredCalculationLoadsTest do
  use Cinder.ConnCase, async: false

  defp inferred_loads_collection(assigns) do
    ~H"""
    <Cinder.collection
      resource={Cinder.Integration.Album}
      url_state={@url_state}
      infer_loads
    >
      <:col :let={album} field="display_title">{album.display_title}</:col>
    </Cinder.collection>
    """
  end

  defp field_load_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Album} url_state={@url_state}>
      <:col :let={album} field="display_title" load>{album.display_title}</:col>
    </Cinder.collection>
    """
  end

  defp named_load_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Album} url_state={@url_state}>
      <:col :let={album} field="title" sort load="display_title">
        {album.display_title}
      </:col>
    </Cinder.collection>
    """
  end

  defp multiple_loads_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Album} url_state={@url_state}>
      <:col
        :let={album}
        field="title"
        load={["display_title", "alternate_title"]}
      >
        {album.display_title} / {album.alternate_title}
      </:col>
    </Cinder.collection>
    """
  end

  defp relationship_load_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Album} url_state={@url_state}>
      <:col :let={album} field="title" load="artist.display_name">
        {album.artist.display_name}
      </:col>
    </Cinder.collection>
    """
  end
end
