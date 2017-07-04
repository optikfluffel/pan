defmodule Pan.PodcastView do
  use Pan.Web, :view
  alias Pan.Endpoint

  def render("datatable.json", %{podcasts: podcasts}) do
    %{podcasts: Enum.map(podcasts, &podcast_json/1)}
  end

  def render("datatable_stale.json", %{podcasts: podcasts}) do
    %{podcasts: Enum.map(podcasts, &podcast_stale_json/1)}
  end


  def podcast_json(podcast) do
    %{id:               podcast.id,
      title:            podcast.title,
      update_paused:    podcast.update_paused,
      updated_at:       format_for_vienna(podcast.updated_at),
      update_intervall: podcast.update_intervall,
      next_update:      podcast.next_update && format_for_vienna(podcast.next_update),
      website:          String.slice(podcast.website, 0, 100),
      actions:          podcast_actions(podcast, &podcast_path/3)}
  end


  def podcast_stale_json(podcast) do
    %{id:               podcast.id,
      title:            podcast.title,
      update_paused:    podcast.update_paused,
      updated_at:       format_for_vienna(podcast.updated_at),
      update_intervall: podcast.update_intervall,
      next_update:      podcast.next_update && format_for_vienna(podcast.next_update),
      feed_url:         podcast.feed_url,
      website:          podcast.website,
      actions:          podcast_actions(podcast, &podcast_path/3)}
  end


  def podcast_actions(record, path) do
    ["<nobr>",
     link("Show", to: path.(Endpoint, :show, record.id),
                  class: "btn btn-default btn-xs"), " ",
     link("Edit", to: path.(Endpoint, :edit, record.id),
                  class: "btn btn-warning btn-xs"), " ",
     link("Pause", to: path.(Endpoint, :pause, record.id),
                   class: "btn btn-info btn-xs"),
     "</nobr>"]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end


  def format_for_vienna(datetime) do
    "<nobr>#{String.slice(NaiveDateTime.to_string(datetime), 0..18)}</nobr>"
  end
end