defmodule PanWeb.OpmlApiController do
  use Pan.Web, :controller
  alias PanWeb.Opml
  use JaSerializer

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    opmls = from(o in Opml, where: o.user_id == ^user.id,
                            preload: :user)
            |> Repo.all()

    render conn, "index.json-api", data: opmls,
                                   opts: [include: "user"]
  end


  def show(conn, %{"id" => id}, user) do
    opml = from(o in Opml, where: o.user_id == ^user.id and
                                  o.id == ^id,
                           preload: :user)

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end


  def create(conn, %{"upload" => upload}, user) do
    destination_path =
      if upload do
        File.mkdir_p("/var/phoenix/pan-uploads/opml/#{user.id}")
        path = "/var/phoenix/pan-uploads/opml/#{user.id}/#{upload.filename}"
        File.cp(upload.path, path)
        path
      else
        ""
      end

    {:ok, opml} = %Opml{content_type: upload.content_type,
                        filename: upload.filename,
                        path: destination_path,
                        user_id: user.id}
                  |> Opml.changeset()
                  |> Repo.insert()

    opml = Repo.preload(opml, :user)

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end
end
