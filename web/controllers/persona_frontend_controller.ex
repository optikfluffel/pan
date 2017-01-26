defmodule Pan.PersonaFrontendController do
  use Pan.Web, :controller
  alias Pan.Persona
  alias Pan.Message
  alias Pan.Manifestation
  alias Pan.Gig


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    personas = Repo.all(from p in Pan.Persona, order_by: :name,
                                               where: is_nil(p.redirect_id))
    render(conn, "index.html", personas: personas)
  end


  def show(conn, params, _user) do
    id = String.to_integer(params["id"])
    persona = Repo.get!(Persona, id)

    case persona.redirect_id do
      nil ->
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
      redirect_id ->
        persona = Repo.get!(Persona, redirect_id)
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
    end
  end


  def persona(conn, params, _user) do
    pid = params["pid"]

    persona = Repo.one(from p in Persona, where: p.pid == ^pid)
              |> Repo.preload(gigs: from(g in Gig, order_by: [desc: :publishing_date],
                                                   preload: :episode))
              |> Repo.preload(engagements: :podcast)

    case persona.redirect_id do
      nil ->
        messages = from(m in Message, where: m.persona_id == ^persona.id,
                                      order_by: [desc: :inserted_at],
                                      preload: [:persona])
                   |> Repo.paginate(params)

        render(conn, "show.html", persona: persona, messages: messages)
      redirect_id ->
        persona = Repo.get!(Persona, redirect_id)
        redirect(conn, to: persona_frontend_path(conn, :persona, persona.pid))
    end
  end


  def edit(conn, %{"id" => id}, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        render(conn, "not_allowed.html")
      manifestation ->
        persona = manifestation.persona

        changeset = Persona.changeset(persona)
        render(conn, "edit.html", persona: persona, changeset: changeset)
    end
  end


  def update(conn, %{"id" => id, "persona" => persona_params}, user) do
    manifestation = from(m in Manifestation, where: m.user_id == ^user.id and m.persona_id == ^id,
                                             preload: :persona)
                    |> Repo.one()

    case manifestation do
      nil ->
        render(conn, "not_allowed.html")
      manifestation ->
        persona = manifestation.persona
        changeset = Persona.changeset(persona, persona_params)

        case Repo.update(changeset) do
          {:ok, _persona} ->
            conn
            |> put_flash(:info, "Persona updated successfully.")
            |> redirect(to: user_frontend_path(conn, :my_profile))
          {:error, changeset} ->
            render(conn, "edit.html", persona: persona, changeset: changeset)
        end
    end
  end
end