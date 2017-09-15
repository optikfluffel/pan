defmodule PanWeb.MessageApiController do
  use Pan.Web, :controller
  alias PanWeb.Message
  alias PanWeb.User
  use JaSerializer

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, %{"id" => id}, user) do
    user_id = Integer.to_string(user.id)
    subscribed_user_ids = User.subscribed_user_ids(user.id)
    subscribed_category_ids = User.subscribed_category_ids(user.id)
    subscribed_podcast_ids = User.subscribed_podcast_ids(user.id)

    message = from(m in Message,
              where: m.id == ^id and
                     (m.topic == "mailboxes" and m.subtopic == ^user_id) or
                     (m.topic == "users"     and m.subtopic in ^subscribed_user_ids) or
                     (m.topic == "podcasts"  and m.subtopic in ^subscribed_podcast_ids) or
                     (m.topic == "category"  and m.subtopic in ^subscribed_category_ids),
              order_by: [desc: :inserted_at],
              preload: :creator)
              |> Repo.one()

    render conn, "show.json-api", data: message
  end


  def my(conn, params, user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    user_id = Integer.to_string(user.id)
    subscribed_user_ids = User.subscribed_user_ids(user.id)
    subscribed_category_ids = User.subscribed_category_ids(user.id)
    subscribed_podcast_ids = User.subscribed_podcast_ids(user.id)

    total = from(m in Message,
               where: (m.topic == "mailboxes" and m.subtopic == ^user_id) or
                      (m.topic == "users"     and m.subtopic in ^subscribed_user_ids) or
                      (m.topic == "podcasts"  and m.subtopic in ^subscribed_podcast_ids) or
                      (m.topic == "category"  and m.subtopic in ^subscribed_category_ids))
               |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: message_api_url(conn,:my)}, conn)

    messages = from(m in Message, order_by: [desc: :inserted_at],
                                  preload: [:creator, :persona],
                                  limit: ^size,
                                  offset: ^offset,
                    where: (m.topic == "mailboxes" and m.subtopic == ^user_id) or
                           (m.topic == "users"     and m.subtopic in ^subscribed_user_ids) or
                           (m.topic == "podcasts"  and m.subtopic in ^subscribed_podcast_ids) or
                           (m.topic == "category"  and m.subtopic in ^subscribed_category_ids))
               |> Repo.all()

    render conn, "index.json-api", data: messages,
                                   opts: [page: links, include: "creator,persona"]
  end
end