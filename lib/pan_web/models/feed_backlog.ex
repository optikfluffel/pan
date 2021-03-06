defmodule PanWeb.FeedBacklog do
  use Pan.Web, :model

  schema "backlog_feeds" do
    field :url, :string
    field :feed_generator, :string
    field :in_progress, :boolean, default: false
    belongs_to :user, PanWeb.User

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :in_progress, :feed_generator, :user_id])
    |> validate_required([:url])
  end
end
