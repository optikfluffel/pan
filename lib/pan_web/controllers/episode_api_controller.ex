defmodule PanWeb.EpisodeApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Episode

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(e in Episode, join: p in assoc(e, :podcast),
                               where: (is_nil(p.blocked) or p.blocked == false) and
                                      e.publishing_date < ^NaiveDateTime.utc_now())
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: episode_api_url(conn,:index)}, conn)

    episodes = from(e in Episode, join: p in assoc(e, :podcast),
                                  where: (is_nil(p.blocked) or p.blocked == false) and
                                   e.publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :publishing_date],
                                  preload: [:podcast, :gigs, :contributors],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: episodes,
                                   opts: [page: links,
                                          include: "podcast,gigs,contributors"]
  end



  def show(conn, %{"id" => id}) do

    episode = Repo.get(Episode, id)
              |> Repo.preload([:podcast, :chapters, [recommendations: :user], :enclosures, :gigs,
                               :contributors])

    render conn, "show.json-api", data: episode,
                                  opts: [include: "podcast,chapters,recommendations,enclosures,gigs,contributors"]
  end


  def search(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/episodes",
             search: [size: size, from: offset, query: [match: [_all: params["filter"]]]]]


    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits}} ->
        total = Enum.min([hits.total, 10000])
        total_pages = div(total - 1, size) + 1

        links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                             size: size,
                                                             total: total_pages,
                                                             base_url: episode_api_url(conn,:search)}, conn)

        episode_ids = Enum.map(hits[:hits], fn(hit) -> String.to_integer(hit[:_id]) end)

        episodes = from(e in Episode, where: e.id in ^episode_ids,
                                      preload: [:podcast, :gigs, :contributors])
                   |> Repo.all()

        render conn, "index.json-api", data: episodes, opts: [page: links,
                                                              include: "podcast,gigs,contributors"]
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.json-api", reason: reason)
    end
  end
end
