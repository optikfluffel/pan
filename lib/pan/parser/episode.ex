defmodule Pan.Parser.Episode do
  use Pan.Web, :controller
  alias Pan.Parser.Contributor
  alias Pan.Parser.Chapter
  alias Pan.Parser.Enclosure
  alias Pan.Parser.Author
  alias Pan.Repo
  require Logger

  def get_or_insert(episode_map, podcast_id) do
    case Repo.get_by(PanWeb.Episode, guid: episode_map[:guid], podcast_id: podcast_id) do
      nil ->
        if episode_map[:guid] do
          insert(episode_map, podcast_id)
        else
          case Repo.get_by(PanWeb.Episode, title: episode_map[:title] || episode_map[:subtitle],
                                           podcast_id: podcast_id) do
            nil ->
              insert(episode_map, podcast_id)
            episode ->
              {:exists, episode}
          end
        end
      episode ->
        {:exists, episode}
    end
  end


  def insert(episode_map, podcast_id) do
    # Here comes the line with the initial update time
    Repo.get(PanWeb.Podcast, podcast_id)
    |> PanWeb.Podcast.changeset(%{update_intervall: 10,
                               next_update: Timex.shift(Timex.now(), hours: 10)})
    |> Repo.update()

    %PanWeb.Episode{podcast_id: podcast_id}
    |> Map.merge(episode_map)
    |> Repo.insert()
  end


  def get(episode_map, podcast_id) do
    case Repo.get_by(PanWeb.Episode, guid: episode_map[:guid], podcast_id: podcast_id) do
      nil ->
        case Repo.get_by(PanWeb.Episode, title: episode_map[:title], podcast_id: podcast_id) do
          nil ->
            {:error, "not_found"}
          episode ->
            {:exists, episode}
        end
      episode ->
        {:exists, episode}
    end
  end


  def persist_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do

      if episode_map[:enclosures] do
        first_enclosure = episode_map[:enclosures] |> Map.to_list |> List.first |> elem(1)
        fallback_url = if episode_map[:link], do: episode_map[:link], else: first_enclosure[:url]

        plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
                            |> Map.put_new(:guid, fallback_url)

        case get_or_insert(plain_episode_map, podcast.id) do
          {:ok, episode} ->
            if episode_map[:chapters] do
              for {_, chapter_map} <- episode_map[:chapters] do
                Chapter.get_or_insert(chapter_map, episode.id)
              end
            end

            if episode_map[:enclosures] do
              for {_, enclosure_map} <- episode_map[:enclosures] do
                Enclosure.get_or_insert(enclosure_map, episode.id)
              end
            end

            Contributor.persist_many(episode_map[:contributors], episode)
            Author.get_or_insert_persona_and_gig(episode_map[:author], episode, podcast)
            Logger.info "\n\e[33m === Importing new episode: #{episode.title} ===\e[0m"
          {:exists, _episode} ->
            true
        end
      end
    end
  end


  def insert_contributors(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      if episode_map[:enclosures] do
        first_enclosure = episode_map[:enclosures] |> Map.to_list |> List.first |> elem(1)
        fallback_url = if episode_map[:link], do: episode_map[:link], else: first_enclosure[:url]

        plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
                            |> Map.put_new(:guid, fallback_url)

        case get(plain_episode_map, podcast.id) do
          {:exists, episode} ->
            Contributor.persist_many(episode_map[:contributors], episode)
            Logger.info "\n\e[33m === Updating contributors for episode: #{episode.title} ===\e[0m"

          {:error, "not_found"} ->
            true
        end
      end
    end
  end


  def clean() do
    episodes = Repo.all(PanWeb.Episode)

    for episode <- episodes do
      PanWeb.Episode.changeset(episode, %{description: HtmlSanitizeEx2.basic_html_reduced(episode.description),
                                          summary:     HtmlSanitizeEx2.basic_html_reduced(episode.summary)})
      |> Repo.update()
    end
  end
end