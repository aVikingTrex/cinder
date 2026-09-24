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

  defp additive_inferred_and_explicit_loads_collection(assigns) do
    ~H"""
    <Cinder.collection
      resource={Cinder.Integration.Album}
      url_state={@url_state}
      infer_loads
    >
      <:col
        :let={album}
        field="display_title"
        load="alternate_title"
      >
        {album.display_title} / {album.alternate_title}
      </:col>
    </Cinder.collection>
    """
  end

  defp aggregate_load_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Artist} url_state={@url_state}>
      <:col :let={artist} field="album_count" load>{artist.album_count}</:col>
    </Cinder.collection>
    """
  end

  defp direct_relationship_load_collection(assigns) do
    ~H"""
    <Cinder.collection resource={Cinder.Integration.Album} url_state={@url_state}>
      <:col :let={album} field="artist" load>{album.artist.name}</:col>
    </Cinder.collection>
    """
  end
  defp duplicate_loads_collection(assigns) do
    assigns =
      assigns
      |> assign_new(:captured_query, fn -> nil end)
      |> assign(
        :query,
        Ash.Query.load(Cinder.Integration.Album, :display_title)
      )

    ~H"""
    <Cinder.collection
      query={@query}
      url_state={@url_state}
      infer_loads
      query_opts={[load: [:display_title]]}
      on_query_change={:capture_query}
    >
      <:col
        :let={album}
        field="display_title"
        load={["display_title", "display_title", "alternate_title"]}
      >
        {album.display_title} / {album.alternate_title}
      </:col>
    </Cinder.collection>

    <span :if={@captured_query} id="display-title-load-count">
      {count_calculation_loads(@captured_query, :display_title)}
    </span>
    """
  end

  defp count_calculation_loads(query, calculation_name) do
    Enum.count(query.calculations, fn {_name, calculation} ->
      calculation.calc_name == calculation_name
    end)
  end

  setup do
    artist = generate(artist(name: "Test Artist"))
    generate(album(title: "Dirt", artist_id: artist.id))

    on_exit(fn ->
      Ash.bulk_destroy!(Cinder.Integration.Album, :destroy, %{})
      Ash.bulk_destroy!(Cinder.Integration.Artist, :destroy, %{})
    end)

    :ok
  end

  test "infer_loads loads calculations named by column fields", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&inferred_loads_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display)")
  end

  test "bare load loads the column field", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&field_load_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display)")
  end

  test "load names a calculation different from the column field", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&named_load_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display)")
  end

  test "load accepts multiple calculation names", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&multiple_loads_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display) / Dirt (alternate)")
  end

  test "load accepts a relationship calculation path", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&relationship_load_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Test Artist (display)")
  end

  test "infer_loads and explicit load are additive", %{conn: conn} do
    path =
      Cinder.TestLive.Fixture.register(&additive_inferred_and_explicit_loads_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display) / Dirt (alternate)")
  end

  test "load accepts aggregates", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&aggregate_load_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "1")
  end

  test "load accepts direct relationships", %{conn: conn} do
    path = Cinder.TestLive.Fixture.register(&direct_relationship_load_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Test Artist")
  end
  test "duplicate paths across query, query_opts, infer_loads, and load are deduplicated", %{
    conn: conn
  } do
    path = Cinder.TestLive.Fixture.register(&duplicate_loads_collection/1)

    conn
    |> visit(path)
    |> assert_has("td", text: "Dirt (display) / Dirt (alternate)")
    |> assert_has("#display-title-load-count", text: "1")
  end
end
