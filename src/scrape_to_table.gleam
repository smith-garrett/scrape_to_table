import gleam/float
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import presentable_soup as soup

pub fn main() -> Nil {
  // Note! The BVDG just generates a page for any queried season, so we have to
  // manually constrain ourselves to the valid years for now
  let urls = generate_urls(2018, 2026)
  let getter = new_response_getter()

  // Pair each URL with its year
  let url_year_pairs =
    urls
    |> list.map(fn(url) {
      let year = extract_year_from_url(url)
      #(url, year)
    })

  let lifter_entries =
    url_year_pairs
    |> list.flat_map(fn(pair) {
      let #(url, year) = pair
      case get_html_body(url, getter) {
        Ok(body) -> {
          case get_all_table_entries(body) {
            Ok(table_rows) ->
              table_rows |> list.filter_map(parse_table_entry(_, year))
            Error(_) -> []
          }
        }
        Error(_) -> []
      }
    })

  // Print the parsed entries
  lifter_entries
  |> list.each(fn(entry) {
    io.println(
      "Year: "
      <> int.to_string(entry.year)
      <> ", Rank: "
      <> int.to_string(entry.rank)
      <> ", Name: "
      <> entry.name
      <> ", Club: "
      <> entry.club
      <> ", Points: "
      <> float.to_string(entry.maximum_points),
    )
  })

  Nil
}

pub fn generate_urls(start: Int, end: Int) -> List(String) {
  let seasons =
    list.range(start, end)
    |> list.window_by_2
    |> list.map(fn(year_pair) {
      let #(year1, year2) = year_pair
      int.to_string(year1) <> "-" <> int.to_string(year2)
    })

  let base_url =
    "https://german-weightlifting.de/bundesliga/contestants/best-list/"

  seasons |> list.map(fn(x) { base_url <> x })
}

pub type HttpResponseGetter {
  HtmlGetter(
    get: fn(String) -> Result(response.Response(String), httpc.HttpError),
  )
}

pub fn new_response_getter() -> HttpResponseGetter {
  let get_fn = fn(url: String) {
    let assert Ok(req) = request.to(url)
    httpc.send(req)
  }
  HtmlGetter(get_fn)
}

pub fn get_html_body(
  url: String,
  response_getter: HttpResponseGetter,
) -> Result(String, Nil) {
  let resp = response_getter.get(url)
  case resp {
    Ok(r) -> Ok(r.body)
    _ -> Error(Nil)
  }
}

// TODO: write tests
pub fn get_all_table_entries(html_body) -> Result(List(soup.Element), Nil) {
  let query =
    soup.element([soup.tag("tbody")])
    |> soup.descendant([soup.tag("tr")])
  soup.find_all(html_body, query)
}

pub type LifterEntry {
  Entry(year: Int, rank: Int, name: String, club: String, maximum_points: Float)
}

// TODO: Write 3 tests: happy, sad (nothing after the /), sad (non-integers after /)
fn extract_year_from_url(url: String) -> Int {
  url
  |> string.split("/")
  |> list.last
  |> result.unwrap("")
  |> string.split("-")
  |> list.first
  |> result.try(int.parse)
  |> result.unwrap(0)
}

// TODO: Write 2 tests: one with an embedded child, one without
fn get_text_content(element: soup.Element) -> String {
  case element {
    soup.Element(_tag, _attrs, children) -> {
      children
      |> list.map(fn(child) {
        case child {
          soup.Element(_, _, _) -> get_text_content(child)
          soup.Text(text) -> text
        }
      })
      |> string.join("")
      |> string.trim
    }
    soup.Text(text) -> string.trim(text)
  }
}

// TODO: Write 3 tests: happy, sad (no tds), sad (only Text)
// Get all td elements from a tr
fn get_table_cell_elements(
  table_row_element: soup.Element,
) -> Result(List(soup.Element), Nil) {
  case table_row_element {
    soup.Element(_tag, _attrs, children) -> {
      let table_cells =
        children
        |> list.filter(fn(child) {
          case child {
            soup.Element(tag, _, _) -> tag == "td"
            soup.Text(_) -> False
          }
        })
        |> list.map(fn(child) {
          case child {
            soup.Element(_, _, _) as el -> el
            soup.Text(_) -> soup.Element("", [], [])
          }
        })

      case list.is_empty(table_cells) {
        True -> Error(Nil)
        False -> Ok(table_cells)
      }
    }
    soup.Text(_) -> Error(Nil)
  }
}

// TODO: Write 4 tests: happy, sad (too many entries), sad (too few entries), sad (no tds)
pub fn parse_table_entry(
  table_row_element: soup.Element,
  year: Int,
) -> Result(LifterEntry, Nil) {
  case get_table_cell_elements(table_row_element) {
    Ok(table_cells) -> {
      // The table has columns: Rank, Name, Club, Maximum Points
      case table_cells {
        [rank_cell, name_cell, club_cell, points_cell, ..] -> {
          let rank_text = get_text_content(rank_cell)
          let name_text = get_text_content(name_cell)
          let club_text = get_text_content(club_cell)
          let points_text = get_text_content(points_cell)

          // Parse rank as int
          let rank = int.parse(rank_text) |> result.unwrap(0)

          // Parse points as float (might have comma as decimal separator)
          let points_normalized = string.replace(points_text, ",", ".")
          let points = float.parse(points_normalized) |> result.unwrap(0.0)

          Ok(Entry(
            year: year,
            rank: rank,
            name: name_text,
            club: club_text,
            maximum_points: points,
          ))
        }
        _ -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
