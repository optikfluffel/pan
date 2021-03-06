defmodule Pan.Parser.Helpers do
  use Pan.Web, :controller
  use Timex
  require Logger

  def boolify(explicit) do
    case explicit do
      "yes" ->
        true
      _ ->
        false
    end
  end


  def inspect(argument) do
    IO.puts "\n\e[33m === Debugger <<<\e[0m"
    IO.inspect argument
    IO.puts "\n\e[33m >>> Debugger ===\e[0m"
  end


  def to_naive_datetime(feed_date) do
    feed_date = feed_date
                |> String.replace(",", " ")
                |> String.replace(". ", " ")
                |> String.replace("  ", " ")
                |> String.replace("\"", "")
                |> String.replace("ٍ", "")
                |> fix_time()
                |> replace_first_second_third_fourth()
                |> replace_long_month_names()
                |> replace_long_week_days()
                |> String.replace("  ", " ")
                |> fix_timezones()


    # Formatters reference:
    # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
    datetime = try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {D}{Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z} {Zname}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m} {Z}") ||
               try_format(feed_date, "{ISO:Extended}") ||
               try_format(feed_date, "{WDshort}  {Mshort} {D} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}:{s}{ss}{Z:}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} 0100") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} GMT{Z:}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {AM} {Zname}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z:}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime}{Zname}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {Z}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Zname})") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {AM}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {Z}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY}") ||
               try_format(feed_date, "{WDshort}:{D}:{0M}:{YYYY}: {ISOtime}") ||
               try_format(feed_date, "{WDshort} {D}.{M}.{YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY}") ||
               try_format(feed_date, "{0D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} - {h24}:{m}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} {Zname}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY}") ||
               try_format(feed_date, "{M}/{0D}/{YYYY}") ||
               try_format(feed_date, "{0D}/{0M}/{YYYY} {ISOtime}") ||
               try_format(feed_date, "{0D}-{0M}-{YYYY}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Z}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}T{ISOtime}") ||
               try_format(feed_date, "{RFC3339z}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}T{ISOtime} {Z:}") ||
               try_format(feed_date, "{YYYY}/{0M}/{0D} {ISOtime}")

    if datetime do
      Timex.to_naive_datetime(datetime)
    else
      Logger.error "Error in date parsing: " <> feed_date
      raise "Error in date parsing"
    end
  end


  def try_format(feed_date, format) do
    case Timex.parse(feed_date, format) do
      {:ok, datetime} -> datetime
      {:error, _} -> nil
    end
  end


  def fix_time(datetime) do
    # add missing minutes
    datetime = Regex.replace(~r/ (\d\d):(\d\d) /, datetime, " \\1:\\2:00 ")

    # add missing leading 0 for hours
    Regex.replace(~r/ (\d):/, datetime, " 0\\1:")
  end


  def replace_first_second_third_fourth(datetime) do
    datetime
    |> String.replace(~r/(\d)st/i, "\\1")
    |> String.replace(~r/(\d)nd/i, "\\1")
    |> String.replace(~r/(\d)rd/i, "\\1")
    |> String.replace(~r/(\d)th/i, "\\1")
  end


  def replace_long_month_names(datetime) do
    datetime
    |> String.replace(~r/janr?u?r?a?r?y?/i,      "Jan")
    |> String.replace(~r/f[ae][bvr]r?u?a?r?y?/i, "Feb")
    |> String.replace(~r/m[aä]rc?h?/i,           "Mar")
    |> String.replace(~r/a[pvb]r?i?l?/i,         "Apr")
    |> String.replace(~r/m[a][iy]/i,             "May")
    |> String.replace(~r/jui?n[eg]?/i,           "Jun")
    |> String.replace(~r/jui?ly?/i,              "Jul")
    |> String.replace(~r/augu?s?t?/i,            "Aug")
    |> String.replace(~r/sep?t?e?m?b?e?r?/i,     "Sep")
    |> String.replace(~r/o[uck]to?b?e?r?/i,      "Oct")
    |> String.replace(~r/no[vc]e?m?e?b?e?r?/i,   "Nov")
    |> String.replace(~r/d[ei][vcz]e?m?b?e?r?/i, "Dec")
  end


  def replace_long_week_days(datetime) do
    # Saturday and Tuesday would interfere, if ordered
    datetime
    |> String.replace(~r/satu?r?d?a?y?/i,         "Sat")
    |> String.replace(~r/m[oå]n?d?a?y?/i,         "Mon")
    |> String.replace(~r/t[ui]e?s?[du]?[an]?y?/i, "Tue")
    |> String.replace("Di",   "Tue")
    |> String.replace("tor",  "Tue")
    |> String.replace(~r/we[db]?n?e?s?d?a?y?/i,   "Wed")
    |> String.replace("MWed", "Wed")
    |> String.replace(~r/Mie?/i, "Wed")
    |> String.replace(~r/thu?[er]?s?d?a?y?/i,     "Thu")
    |> String.replace("Do",   "Thu")
    |> String.replace(~r/fr[ei]?d?a?y?/i,         "Fri")
    |> String.replace(~r/s[ou]nd?a?y?/i,          "Sun")
    |> String.replace(~r/Lun/i,                   "Mon")
  end


  def fix_timezones(datetime) do
    datetime
    |> String.replace("AEST",  "+1000")
    |> String.replace("CEST",  "+0200")
    |> String.replace("AEDT", "+1100")
    |> String.replace("NZST", "+1200")
    |> String.replace("NZDT", "+1300")
    |> String.replace("EST",  "-0500")
    |> String.replace("EDT",  "-0400")
    |> String.replace("CST",  "-0600")
    |> String.replace("PST",  "-0700")
    |> String.replace("PCT",  "-0700")
    |> String.replace("GMT+1",  "+0100")
    |> String.replace("BST",  "+0100")
    |> String.replace("IDT",  "+0300")
    |> String.replace("GST",  "+0400")
    |> String.replace("KST",  "+0900")
    |> String.replace("JST",  "+0900")
    |> String.replace("GTM",   "GMT")
    |> String.replace("GMT+2", "+0200")
    |> String.replace("-0001", "2016")
  end


  def fix_missing_xml_tag(xml) do
    xml =
      if String.starts_with?(xml, ["<?xml"]) do
        xml
      else
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" <> xml
      end

    {:ok, xml}
  end


  # Deep merging maps
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end


# export feed urls
  def feed_urls do
    urls = Repo.all(from f in PanWeb.Feed, select: [f.self_link_url])
    for url <- urls do
      IO.puts url
    end
  end


  def remove_comments(xml) do
    # U ... non-greedy, s ... . matches newlines as well
    Regex.replace(~r/<!--.*-->/Us, xml, "")
  end


  def fix_character_code_strings(xml) do
    # Erlang does not know of 1252, that's the best we can do for now
    Regex.replace(~r/Windows-1252/Us, xml, "iso-8859-1")
  end


  def remove_extra_angle_brackets(xml) do
    xml = Regex.replace(~r/>>/Us, xml, ">")
    Regex.replace(~r//Us, xml, "")
  end


  def fix_ampersands(xml) do
    String.replace(xml, "& ", "&amp; ")
  end

  def to_255(text) do
    if text && byte_size(text) > 255 do
      chars = text
              |> binary_part(0, 255)
              |> String.length()

      String.slice(text, 0, chars - 1)
    else
      text
    end
  end


  def mark_if_deleted(changeset) do
    if changeset.__meta__.state == :deleted do
      changeset
      |> Map.put(:deleted, true)
      |> Map.put(:created, false)
    else
      changeset
      |> Map.put(:created, true)
      |> Map.put(:deleted, false)
    end
  end
end
