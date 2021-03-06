defmodule PanWeb.FeedBacklogController do
  use Pan.Web, :controller
  alias PanWeb.Feed
  alias PanWeb.AlternateFeed
  alias PanWeb.FeedBacklog
  alias PanWeb.Subscription
  require Logger

  def index(conn, _params) do
    backlog_feeds = from(f in FeedBacklog, order_by: [desc: :inserted_at],
                                           limit: 25)
                    |> Repo.all
    feedcount = Repo.aggregate(FeedBacklog, :count, :id)

    render(conn, "index.html", backlog_feeds: backlog_feeds, feedcount: feedcount)
  end


  def new(conn, _params) do
    changeset = FeedBacklog.changeset(%FeedBacklog{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"feed_backlog" => feed_backlog_params}) do
    changeset = FeedBacklog.changeset(%FeedBacklog{}, feed_backlog_params)

    case Repo.insert(changeset) do
      {:ok, _feed_backlog} ->
        conn
        |> put_flash(:info, "Feed backlog created successfully.")
        |> redirect(to: feed_backlog_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    best_matching_feed = Feed.clean_and_best_matching(feed_backlog.url)

    render(conn, "show.html", feed_backlog: feed_backlog,
                              best_matching_feed: best_matching_feed)
  end


  def edit(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    changeset = FeedBacklog.changeset(feed_backlog)
    render(conn, "edit.html", feed_backlog: feed_backlog, changeset: changeset)
  end


  def update(conn, %{"id" => id, "feed_backlog" => feed_backlog_params}) do
    feed_backlog = Repo.get!(FeedBacklog, id)
    changeset = FeedBacklog.changeset(feed_backlog, feed_backlog_params)

    case Repo.update(changeset) do
      {:ok, feed_backlog} ->
        conn
        |> put_flash(:info, "Feed backlog updated successfully.")
        |> redirect(to: feed_backlog_path(conn, :show, feed_backlog))
      {:error, changeset} ->
        render(conn, "edit.html", feed_backlog: feed_backlog, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(feed_backlog)

    conn
    |> put_flash(:info, "Feed backlog deleted successfully.")
    |> redirect(to: feed_backlog_path(conn, :index))
  end


  def import(conn, %{"id" => id}) do
    feed_backlog = Repo.get!(FeedBacklog, id)

    case Pan.Parser.RssFeed.initial_import(feed_backlog.url, id) do
      {:ok, podcast_id} ->
        conn
        |> put_flash(:info, "Feed imported successfully.")
        |> redirect(to: podcast_frontend_path(conn, :show, podcast_id))

      {:error, error} ->
        Repo.delete!(feed_backlog)
        conn
        |> put_flash(:error, error)
        |> render("import.html")
    end
  end


  def import_100(conn, _params) do
    backlog_feeds = from(f in FeedBacklog, where: f.in_progress == false,
                                           order_by: [desc: :inserted_at],
                                           limit: 100)
                    |> Repo.all()


    for backlog_feed <- backlog_feeds do
      try do
        PanWeb.FeedBacklog.changeset(backlog_feed, %{in_progress: true})
        |> Repo.update()

        Pan.Parser.RssFeed.initial_import(backlog_feed.url, backlog_feed.id)
      rescue
        _ ->
          Logger.error "=== Error importing: " <> backlog_feed.url <> " ==="
      end
    end

    conn
      |> put_flash(:info, "Feeds imported successfully.")
      |> redirect(to: feed_backlog_path(conn, :index))
  end


  def subscribe(conn, _params) do
    for backlog_feed <- Repo.all(FeedBacklog) do
      feeds = Repo.all(from f in Feed, where: f.self_link_url == ^backlog_feed.url,
                                       preload: :podcast)
      feed = case feeds do
        [] ->
          alternate_feeds = Repo.all(from f in AlternateFeed, where: f.url == ^backlog_feed.url,
                                                              preload: [feed: :podcast])
          case alternate_feeds do
            [] ->
              nil
            alternate_feeds ->
              List.first(alternate_feeds).feed
            end
        feeds ->
          List.first(feeds)
      end

      if feed do
        Subscription.get_or_insert(backlog_feed.user_id, feed.podcast.id)
        Repo.delete!(backlog_feed)
      end
    end

    conn
    |> redirect(to: feed_backlog_path(conn, :index))
  end
end
