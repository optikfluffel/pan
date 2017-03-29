defmodule Pan.SearchFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML

  def hit_widget(hit, searchstring) do
    %{_source: fields, _type: type} = hit

    case type do
      "episodes"   -> render("episode.html", episode: fields, searchstring: searchstring)
      "podcasts"   -> render("podcast.html", podcast: fields, searchstring: searchstring)
      "personas"   -> render("persona.html", persona: fields)
      "users"      -> render("user.html", user: fields)
      "categories" -> render("category.html", category: fields)
    end
  end


  def podcast_hit(podcast, searchstring) do
    hit([Title:       podcast[:title],
         Description: podcast[:description],
         Summary:     podcast[:summary]], searchstring, "")
    |> raw()
  end


  def episode_hit(episode, searchstring) do
    hit([Title:       episode[:title],
         Subtitle:    episode[:subtitle],
         Description: episode[:description],
         Summary:     episode[:summary],
         Shownotes:   episode[:shownotes]], searchstring, "")
    |> raw
  end


  def hit([head | tail], searchstring, output) do
    {type, content} = head

    case content != nil and String.match?(content, ~r/#{searchstring}/i) do
      true ->
        hit(tail, searchstring, output <> "<i>" <> Atom.to_string(type) <> ":</i> " <>
                                highlight(content, searchstring) <> "<br/>")
      false ->
        hit(tail, searchstring, output)
    end
  end

  def hit([], _searchstring, output) do
    output
  end


  def highlight(result, searchstring) do
    [left, match, right] =  Regex.split(~r/#{searchstring}/i, result, [include_captures: true, parts: 2])

    left = left
           |> HtmlSanitizeEx.strip_tags
           |> String.reverse
           |> truncate(60)
           |> String.reverse
    right = right
            |> HtmlSanitizeEx.strip_tags
            |> truncate(60)

    left <> "<b>" <> match <> "</b>" <> right
  end
end