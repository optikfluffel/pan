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
                |> String.replace("  ", " ")
                |> String.replace("\"", "")
                |> fix_time()
                |> replace_long_month_names()
                |> replace_long_week_days()
                |> fix_timezones()

    # Formatters reference:
    # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
    datetime = try_format(feed_date, "{RFC1123}") ||
               try_format(feed_date, "{ISO:Extended}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Z}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}T{ISOtime} {Z:}") ||
               try_format(feed_date, "{0D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}:{s}{ss}{Z:}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {ISOtime} {Z:}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY}, {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {ISOtime}{Zname}") ||
               try_format(feed_date, "{WDshort},{D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort},{D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort}, {D}th {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D}rd {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D}st {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D}nd {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDfull}, {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDfull}, {D}, {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDfull}, {Mshort} {D}, {YYYY} {ISOtime} {AM}") ||
               try_format(feed_date, "{WDfull}, {Mshort} {D}, {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDfull} {Mshort} {D}, {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {Mshort} {D}, {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Zname})") ||
               try_format(feed_date, "{WDshort}, {Mshort} {D} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} - {h24}:{m}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} {Zname}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY}") ||
               try_format(feed_date, "{YYYY}/{0M}/{0D} {ISOtime}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}") ||
               try_format(feed_date, "{RFC1123} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {Z}") ||
               try_format(feed_date, "{WDshort}, {Mshort} {D}, {YYYY} {Z}") ||
               try_format(feed_date, "{WDshort} {Mshort} {D}, {YYYY} {Z}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY}") ||
               try_format(feed_date, "{WDfull} {Mshort} {D}, {YYYY}") ||
               try_format(feed_date, "{WDfull}, {Mshort} {D} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDfull}:{D}:{0M}:{YYYY}: {ISOtime}")


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


  def replace_long_month_names(datetime) do
    datetime
    |> String.replace("January",   "Jan")
    |> String.replace("jan",       "Jan")
    |> String.replace("JAN",       "Jan")
    |> String.replace("February",  "Feb")
    |> String.replace("FEB",       "Feb")
    |> String.replace("feb",       "Feb")
    |> String.replace("Far",       "Feb")
    |> String.replace("Fev",       "Feb")
    |> String.replace("Febr",      "Feb")
    |> String.replace("March",     "Mar")
    |> String.replace("Mär",       "Mar")
    |> String.replace("mar",       "Mar")
    |> String.replace("MAR",       "Mar")
    |> String.replace("April",     "Apr")
    |> String.replace("APR",       "Apr")
    |> String.replace("apr",       "Apr")
    |> String.replace("Avr",       "Apr")
    |> String.replace("Mai",       "May")
    |> String.replace("may",       "May")
    |> String.replace("MAY",       "May")
    |> String.replace("jun",       "Jun")
    |> String.replace("JUN",       "Jun")
    |> String.replace("June",      "Jun")
    |> String.replace("Juin",      "Jun")
    |> String.replace("July",      "Jul")
    |> String.replace("jul",       "Jul")
    |> String.replace("JUL",       "Jul")
    |> String.replace("August",    "Aug")
    |> String.replace("aug",       "Aug")
    |> String.replace("AUG",       "Aug")
    |> String.replace("September", "Sep")
    |> String.replace("Set",       "Sep")
    |> String.replace("Sept",      "Sep")
    |> String.replace("sep",       "Sep")
    |> String.replace("SEP",       "Sep")
    |> String.replace("October",   "Oct")
    |> String.replace("OCtober",   "Oct")
    |> String.replace("Okt",       "Oct")
    |> String.replace("OCt",       "Oct")
    |> String.replace("OCT",       "Oct")
    |> String.replace("oct",       "Oct")
    |> String.replace("Noc",       "Nov")
    |> String.replace("November",  "Nov")
    |> String.replace("nov",       "Nov")
    |> String.replace("NOV",       "Nov")
    |> String.replace("Dez",       "Dec")
    |> String.replace("Dic",       "Dec")
    |> String.replace("dec",       "Dec")
    |> String.replace("DEC",       "Dec")
    |> String.replace("December",  "Dec")
  end


  def replace_long_week_days(datetime) do
    datetime
    |> String.replace("Wedn,", "Wed,")
    |> String.replace("Mo,",   "Mon,")
    |> String.replace("mån,",  "Mon,")
    |> String.replace("Di,",   "Tue,")
    |> String.replace("Tus,",  "Tue,")
    |> String.replace("Tues,", "Tue,")
    |> String.replace("tor,",  "Tue,")
    |> String.replace("Weds,", "Wed,")
    |> String.replace("Weds ", "Wed ")
    |> String.replace("Wen,",  "Wed,")
    |> String.replace("MWed,", "Wed,")
    |> String.replace("Mi,",   "Wed,")
    |> String.replace("Thurs,","Thu,")
    |> String.replace("Thue,", "Thu,")
    |> String.replace("Thur,", "Thu,")
    |> String.replace("Thr,",  "Thu,")
    |> String.replace("Thur ", "Thu ")
    |> String.replace("Do,",   "Thu,")
    |> String.replace("Fr,",   "Fri,")
    |> String.replace("Sa,",   "Sat,")
    |> String.replace("So,",   "Sun,")
    |> String.replace("Son,",  "Sun,")
    |> String.replace("TueSun,", "Sun,")
    |> String.replace("ٍ", "")
  end


  def fix_timezones(datetime) do
    datetime
    |> String.replace("NZDT", "+1300")
    |> String.replace("NZST", "+1200")
    |> String.replace("AEDT", "+1100")
    |> String.replace("AEST",  "EST")
    |> String.replace("GTM",   "GMT")
    |> String.replace("-0001", "2016")
    |> String.replace("KST", "+0900")
    |> String.replace("JST", "+0900")
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
    urls = Repo.all(from f in Pan.Feed, select: [f.self_link_url])
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
end
