defmodule Pan.Parser.Enclosure do
  use Pan.Web, :controller

  def get_or_insert(enclosure_map, episode_id) do
    case get_enclosure(episode_id, enclosure_map[:guid], enclosure_map[:url]) do
      nil ->
        %PanWeb.Enclosure{episode_id: episode_id}
        |> Map.merge(enclosure_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end

  defp get_enclosure(episode_id, nil, url) do
    Repo.get_by(PanWeb.Enclosure, episode_id: episode_id,
                               url: url)
  end
  defp get_enclosure(episode_id, guid, url) do
    Repo.get_by(PanWeb.Enclosure, episode_id: episode_id,
                               guid: guid,
                               url: url)
  end
end